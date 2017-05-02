//
//  FFmpegMP4Writer.m
//  ProjectLibrary
//
//  Created by alby on 14-7-22.
//  Copyright (c) 2014年 alby. All rights reserved.
//

#import "FFmpegMP4Writer.h"
#import "ProjectUtils.h"
#import <UIKit/UIImagePickerController.h>
#import <libavutil/opt.h>
#import <libavutil/mathematics.h>
#import <libavutil/timestamp.h>
#import <libavformat/avformat.h>
#import <libswresample/swresample.h>

#define kTempFile      [NSTemporaryDirectory() stringByAppendingPathComponent:@"FFmpegMP4WriterTemp.mp4"]
#define kErrorDomain   @"FFmpegMP4Writer"

// Video
#define kStreamPixFMT          AV_PIX_FMT_YUV420P /* default pix_fmt */

// Audio
#define	kQuantizationFieldMask (0xf)	/* Quantization field mask. */
#define	kSegmentFieldMask      (0x70)	/* Segment field mask. */
#define	kSegmentLeftShift      (4)		/* Left shift for segment number. */
#define	kSignBit               (0x80)   /* Sign bit for a A-law byte. */

const AVRational usTimeBase = {1, 1000000};

@implementation FFmpegMP4Writer
{
    // 写入标记
    BOOL                  _isReadyToWrite;

    // 音频参数
    FFmpegMP4WriterAudioType   _audioType;
    int                       _sampleRate;
    uint64_t                     _bitRate;
    // 视频参数
    int                   _videoFrameRate;
    int                            _width;
    int                           _height;
    
    // FFmpeg
    AVFormatContext     *_avFormatContext;
    
    // 按PTS写入
    long long                  _vStartPTS;
    long long                  _aStartPTS;
    
    // 按逐帧写入
    long long                   _videopts;
    long long                   _audiopts;

    // Video
    int                 _videoStreamIndex;
    AVStream                *_videoStream;
    BOOL            _isWaitingForKeyFrame;

    // Audio
    int                 _audioStreamIndex;
    AVStream                *_audioStream;
    
    // 非AAC编码音频，需进行编码
    AVFrame                  *_audioFrame;
    uint8_t                *_pTmpAudioBuf; // 音频临时缓冲区
    int                  _nTmpAudioBufLen; // 音频临时缓冲区长度
}

+(void)initialize {
    if (self == [FFmpegMP4Writer class]) {
        avcodec_register_all();
        av_register_all();
    }
}

- (instancetype)init {
    self = [super init];
    if ( !self ) {
        return nil;
    }
 
    return self;
}

- (void)dealloc {
    [self endWrite:nil];
}

- (void)destroy {
    if ( _avFormatContext ) {
        if( _isReadyToWrite ) {
            av_write_trailer(_avFormatContext);
        }
        if(_videoStream) {
            avcodec_close(_videoStream->codec);
            _videoStream = NULL; // avformat_free_context:Free an _avFormatContext and all its streams.
        }
        if(_audioStream) {
            avcodec_close(_audioStream->codec);
            _audioStream = NULL;
        }
        if(_audioFrame) {
            av_frame_free(&_audioFrame);
        }
        if( _pTmpAudioBuf ) {
            free(_pTmpAudioBuf);
            _pTmpAudioBuf = NULL;
        }
        
        if (!(_avFormatContext->oformat->flags & AVFMT_NOFILE)) {
            avio_close(_avFormatContext->pb);
        }
        
        avformat_free_context(_avFormatContext);
        _avFormatContext = NULL;
    }
}

- (void)reset {
    _isReadyToWrite = NO;
    _videoStreamIndex = -1;
    _audioStreamIndex = -1;
    _isWaitingForKeyFrame = YES;
    _videopts = 0;
    _audiopts = 0;
    _vStartPTS = 0;
    _aStartPTS = 0;
}

- (BOOL)beginWriteUnusedAudioWithVideoFrameRate:(int)videoFrameRate width:(int)width height:(int)height error:(NSError **)error {
    return [self beginWrite:FFmpegMP4WriterAudioTypeNone
             videoFrameRate:videoFrameRate
                      width:width
                     height:height
                 sampleRate:0
                    bitRate:0
                      error:error];
}

- (BOOL)beginWriteUseAACWithVideoFrameRate:(int)videoFrameRate width:(int)width height:(int)height sampleRate:(int)sampleRate bitRate:(uint64_t)bitRate error:(NSError **)error {
    return [self beginWrite:FFmpegMP4WriterAudioTypeAAC
             videoFrameRate:videoFrameRate
                      width:width
                     height:height
                 sampleRate:sampleRate
                    bitRate:bitRate
                      error:error];
}
- (BOOL)beginWriteUsePCMWithVideoFrameRate:(int)videoFrameRate width:(int)width height:(int)height sampleRate:(int)sampleRate bitRate:(uint64_t)bitRate error:(NSError **)error {
    return [self beginWrite:FFmpegMP4WriterAudioTypePCM
             videoFrameRate:videoFrameRate
                      width:width
                     height:height
                 sampleRate:sampleRate
                    bitRate:bitRate
                      error:error];

}
- (BOOL)beginWriteUseG711aWithVideoFrameRate:(int)videoFrameRate width:(int)width height:(int)height sampleRate:(int)sampleRate bitRate:(uint64_t)bitRate error:(NSError **)error {
    return [self beginWrite:FFmpegMP4WriterAudioTypeG711a
             videoFrameRate:videoFrameRate
                      width:width
                     height:height
                 sampleRate:sampleRate
                    bitRate:bitRate
                      error:error];

}

- (BOOL)beginWrite:(FFmpegMP4WriterAudioType)audioType
    videoFrameRate:(int)videoFrameRate
             width:(int)width
            height:(int)height
        sampleRate:(int)sampleRate
           bitRate:(uint64_t)bitRate
             error:(NSError **)error {
    [self reset];
    
    NSString *mp4File = kTempFile;
    DLog(@"%@ 临时文件:%@", __FUNCTION_FILE_LINE__, mp4File);
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:mp4File]) {
        DLog(@"%@ MP4WriterTemp.mp4已经存在,准备删除.", __FUNCTION_FILE_LINE__);
        if(![fileManager removeItemAtPath:mp4File error:nil]) {
            [self error:400 message:@"创建录像文件失败,请再试."];
            DLog(@"%@ 删除MP4WriterTemp.mp4失败.", __FUNCTION_FILE_LINE__);
            return NO;
        }
    }
    if(![fileManager createFileAtPath:mp4File contents:nil attributes:nil]) {
        [self error:401 message:@"创建录像文件失败,请再试."];
        DLog(@"%@ MP4WriterTemp.mp4创建失败.", __FUNCTION_FILE_LINE__);
        return NO;
    }
    
    _audioType = audioType;
    _sampleRate = sampleRate;
    _bitRate = bitRate;
    _videoFrameRate = videoFrameRate;
    _width = width;
    _height = height;

    if([self.delegate respondsToSelector:@selector(beginWrite:)]) {
        [self.delegate beginWrite:@"开始保存录像到相册"];
    }

    return YES;
}

- (BOOL)endWrite:(NSError **)error {
    [self destroy];
    [self reset];
    return YES;
}

- (void)error:(NSInteger)errorCode message:(NSString *)messge {
    if(!self.delegate||![self.delegate respondsToSelector:@selector(error:message:)])
        return;
    
    [self.delegate error:errorCode message:messge];
}

- (BOOL)saveVideo:(NSError **)error {
    DLog(@"%@ 写入相册", __FUNCTION_FILE_LINE__);
    if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(kTempFile)) {
        UISaveVideoAtPathToSavedPhotosAlbum(kTempFile, self, @selector(video:didFinishSavingWithError:contextInfo:), nil);
        return YES;
    } else {
        [self error:701 message:@"保存录像文件失败,请再试."];
        DLog(@"%@ 无法将视频文件%@写入", __FUNCTION_FILE_LINE__, kTempFile);
        return NO;
    }
}

- (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo: (void *)contextInfo
{
    DLog(@"%@ %@ %@", __FUNCTION_FILE_LINE__, videoPath, error);
    if(!error) {
        //*
        if([self.delegate respondsToSelector:@selector(saveVideo:)]) {
            [self.delegate saveVideo:@"已经成功将录像保存到相册."];
        }
        //*/
    } else {
        [self error:800 message:@"保存录像文件失败,请再试."];
    }
}

#pragma mark - Write Frame
- (BOOL)writeFrame:(TBMFrameType)frameType
         frameData:(const void *)frameData
      frameDataLen:(int)frameDataLen
             start:(NSUInteger)start
             error:(NSError **)error {
    return [self writeFrame:frameType
                  frameData:frameData
               frameDataLen:frameDataLen
                      start:start
                        pts:-1
                      error:error];
}

- (BOOL)writeFrame:(TBMFrameType)frameType
         frameData:(const void *)frameData
      frameDataLen:(int)frameDataLen
             start:(NSUInteger)start
               pts:(int64_t)pts /* 单位：纳秒（直播保存的是微秒） */
             error:(NSError **)error {
    int ret;
    
    if(frameType != TBMFrameTypeVideoI && frameType != TBMFrameTypeVideoP && frameType != TBMFrameTypeAudio) {
        DLog(@"frame type error");
        return NO;
    }
    
    if(!_isReadyToWrite) {
        // 期待I帧来写入MP4 Header
        if(frameType != TBMFrameTypeVideoI) return NO;
        AVOutputFormat *fmt = NULL;
        AVCodec *videoCodec = NULL;
        AVCodec *audioCodec = NULL;
        //AVStream *videoStream = NULL;
        //AVStream *_audioStream = NULL;
        
        void *pSpsPps=NULL;
        int spsPpsLen = 0;
        if(![self findSpsPps:(const unsigned char*)frameData strLen:frameDataLen pOut:&pSpsPps outLen:&spsPpsLen]) {
            DLog(@"could not find sps or pps");
            return NO;
        }
        
        const char *distFile = [kTempFile UTF8String];
        
        avformat_alloc_output_context2(&_avFormatContext, NULL, NULL, distFile);
        if (!_avFormatContext) {
            DLog(@"could not deduce output format from file extension");
            [self destroy];
            return NO;
        }
        fmt = _avFormatContext->oformat;
        if (fmt->video_codec != AV_CODEC_ID_NONE) {
            _videoStream = [self addStream:_avFormatContext codec:&videoCodec codec_id:fmt->video_codec streamIndex:&_videoStreamIndex];
        } else {
            DLog(@"video codec is none");
            [self destroy];
            return NO;
        }
        
        if (_videoStream) {
            [self openVideo:_avFormatContext codec:videoCodec stream:_videoStream spsPps:pSpsPps spsPpsLen:spsPpsLen];
        }
        
        free(pSpsPps);
        pSpsPps = NULL;
        
        if (_audioType != FFmpegMP4WriterAudioTypeNone) {
            fmt->audio_codec = AV_CODEC_ID_AAC;
            _audioStream = [self addStream:_avFormatContext codec:&audioCodec codec_id:fmt->audio_codec streamIndex:&_audioStreamIndex];
        } else {
            fmt->audio_codec = AV_CODEC_ID_NONE;
            DLog(@"audio codec is none");
        }
        
        if ( _audioStreamIndex >= 0 ) {
            [self openAudio:_avFormatContext codec:audioCodec st:_audioStream];
        }
        
        av_dump_format(_avFormatContext, 0, distFile, 1);
        
        /* open the output file, if needed */
        if (!(fmt->flags & AVFMT_NOFILE)) {
            ret = avio_open(&_avFormatContext->pb, distFile, AVIO_FLAG_WRITE);
            if (ret < 0) {
                DLog(@"could not open '%s'", distFile);
                [self destroy];
                return NO;
            }
        }
        
        /* Write the stream header, if any */
        ret = avformat_write_header(_avFormatContext, NULL);
        if (ret < 0) {
            DLog(@"error occurred when opening output file");
            [self destroy];
            return NO;
        }
        
        _isReadyToWrite = YES;
    }

    if (frameType != TBMFrameTypeAudio) {
        //( 0 == get_vop_type( frameData, frameDataLen ) ) ? AV_PKT_FLAG_KEY : 0;
        return [self writeVideoFrame:frameType == TBMFrameTypeVideoI frameData:frameData frameDataLen:frameDataLen start:start pts:pts];
    } else {
        return [self writeAudioFrame:frameData frameDataLen:frameDataLen start:start pts:pts];
    }

}

- (BOOL)writeVideoFrame:(BOOL)isKeyFrame
              frameData:(const void *)frameData
           frameDataLen:(int)frameDataLen
                  start:(NSUInteger)start
                    pts:(int64_t)pts {
    int ret;

    if ( 0 > _videoStreamIndex ) {
        DLog(@"vi less than 0");
        return NO;
    }
    
    // Waiting for key frame
    if (_isWaitingForKeyFrame&&!isKeyFrame) {
        DLog(@"video key frame is not ready");
        return NO;
    } else {
        _isWaitingForKeyFrame = NO;
    }
    //AVStream *videoStream = _avFormatContext->streams[ _videoStreamIndex ];
    
    // Init packet
    AVPacket pkt;
    av_init_packet( &pkt );
    pkt.flags |= isKeyFrame?AV_PKT_FLAG_KEY:0;
    
    pkt.stream_index = _videoStream->index;
    pkt.data = (uint8_t*)(frameData + start);
    pkt.size = frameDataLen;
    
    if(_vStartPTS <= 0) {
        _vStartPTS = pts;
    }
    if(pts >= 0) {
        pkt.pts = av_rescale_q(pts - _vStartPTS, usTimeBase, _videoStream->time_base);;
    } else {
        pkt.pts = av_rescale_q(_videopts, _videoStream->codec->time_base, _videoStream->time_base);
    }
    pkt.dts = pkt.pts;
    //NSLog(@"V.... %lld %lld %lld", _vStartPTS, pts, pkt.pts);
    pkt.duration = 0;
    
    ret = av_interleaved_write_frame( _avFormatContext, &pkt);
    av_packet_unref(&pkt);
    if ( 0 > ret ) {
        DLog(@"cannot write video frame");
        return NO;
    }
    
    _videopts++;
    return YES;
}

- (BOOL)writeAudioFrame:(const void *)frameData
           frameDataLen:(int)frameDataLen
                  start:(NSUInteger)start
                    pts:(int64_t)pts {
    
    if(_audioType == FFmpegMP4WriterAudioTypeNone) {
        DLog(@"audioType == FFmpegMP4WriterAudioTypeNone");
        return NO;
    }

    int ret;
    if (_audioStreamIndex < 0) {
        DLog(@"ai less than 0");
        return NO;
    }

    if (_isWaitingForKeyFrame) {
        DLog(@"video key frame is not ready");
        return NO;
    }
    //AVStream *_audioStream = _avFormatContext->streams[ _audioStreamIndex ];
    
    const void *data = frameData + start + 7/*adts*/;
    if(_audioType == FFmpegMP4WriterAudioTypeAAC) {
        AVPacket pkt = {0};
        av_init_packet(&pkt);
        pkt.stream_index = _audioStream->index;
        pkt.data = (uint8_t *)data;
        pkt.size = frameDataLen - 7/*adts*/;
        
        if(_aStartPTS <= 0) {
            _aStartPTS = pts;
        }
        if(pts >= 0) {
            pkt.pts = av_rescale_q(pts - _aStartPTS, usTimeBase, _audioStream->time_base);;
        } else {
            pkt.pts = av_rescale_q(_audiopts, _audioStream->codec->time_base, _audioStream->time_base);
        }
        pkt.dts = pkt.pts;
        //NSLog(@"A.... %lld %lld %lld", _aStartPTS, pts, pkt.pts);
        pkt.duration = 0;
        //pkt.duration = (int)av_rescale_q(pkt.duration, _audioStream->codec->time_base, _audioStream->time_base);
        
        int ret = av_interleaved_write_frame( _avFormatContext, &pkt);
        if (ret < 0) {
            char errbuf[128];
            const char *errbuf_ptr = errbuf;
            if (av_strerror(ret, errbuf, sizeof(errbuf)) < 0)
                errbuf_ptr = strerror(AVUNERROR(ret));
            DLog(@"cannot write audio frame %s", errbuf_ptr);
            av_packet_unref(&pkt);
            return NO;
        }
        av_packet_unref(&pkt);
    } else {
        AVFrame* p_audioFrame;
        int got_packet;
        AVRational br = {1, _audioStream->codec->sample_rate};
        do {
            int needLen = _audioFrame->nb_samples - _nTmpAudioBufLen;
            if ( needLen > frameDataLen )
            {
                memcpy(_pTmpAudioBuf + _nTmpAudioBufLen, data, frameDataLen);
                _nTmpAudioBufLen += frameDataLen;
                break;
            }
            
            memcpy(_pTmpAudioBuf + _nTmpAudioBufLen, data, needLen);
            _nTmpAudioBufLen += needLen;
            
            data += needLen;
            frameDataLen -= needLen;
            
            if(_audioType == FFmpegMP4WriterAudioTypeG711a) {
                // G711A to PCM
                p_audioFrame = [self pcma2lpcm:_audioFrame];
                if (!p_audioFrame) {
                    break;
                }
            } else {
                p_audioFrame = _audioFrame;
            }
            
            // Init packet
            AVPacket pkt = {0};
            av_init_packet(&pkt);
            p_audioFrame->pts = av_rescale_q(pts, br, _audioStream->codec->time_base);
            _audiopts += _audioFrame->nb_samples;
            ret = avcodec_encode_audio2(_audioStream->codec, &pkt, p_audioFrame, &got_packet);
            if (ret < 0) {
                DLog(@"avcodec_encode_audio2 failed");
                av_packet_unref(&pkt);
                break;
            }
            
            if (got_packet) {
                pkt.stream_index = _audioStream->index;
                pkt.pts = av_rescale_q(p_audioFrame->pts, _audioStream->codec->time_base,_audioStream->time_base);
                pkt.dts = pkt.pts;
                //pkt.duration = 0;
                pkt.duration = (int)av_rescale_q(pkt.duration, _audioStream->codec->time_base,_audioStream->time_base);
                if (av_interleaved_write_frame( _avFormatContext, &pkt ) < 0) {
                    DLog(@"cannot write audio frame");
                    av_packet_unref(&pkt);
                    break;
                }
            }
            av_packet_unref(&pkt);
        } while (frameDataLen > 0);
    }
    
    return YES;
}

#pragma mark - Utils
/*
// < 0 = error
// 0 = I-Frame
// 1 = P-Frame
// 2 = B-Frame
// 3 = S-Frame
// < 0 = error
// 0 = I-Frame
// 1 = P-Frame
// 2 = B-Frame
// 3 = S-Frame
static int get_vop_type( const void *p, int len ) {
    if ( !p || 6 >= len )
        return -1;
    
    unsigned char *b = (unsigned char*)p;
    
    // Verify NAL marker
    if ( b[ 0 ] || b[ 1 ] || 0x01 != b[ 2 ] ) {   
        b++;
        if ( b[ 0 ] || b[ 1 ] || 0x01 != b[ 2 ] )
            return -1;
    } // end if
    
    b += 3;
    
    // Verify VOP id
    if ( 0xb6 == *b ) {   
        b++;
        return ( *b & 0xc0 ) >> 6;
    } // end if
    
	/ *
     switch( *b ) {  
        case 0x65 : return 0;
        case 0x61 : return 1;
        case 0x01 : return 2;
     } // end switch
     * /
	switch(*b & 0x1f) {
        case 5:
        case 6:
        case 7:
        case 8:
            return 0;
        case 1:
            return 1;
	}
    
    return -1;
}

static int get_nal_type(const void *p, int len ) {
    if ( !p || 5 >= len )
        return -1;
    
    unsigned char *b = (unsigned char*)p;
    
    // Verify NAL marker
    if ( b[ 0 ] || b[ 1 ] || 0x01 != b[ 2 ] )
    {   b++;
        if ( b[ 0 ] || b[ 1 ] || 0x01 != b[ 2 ] )
            return -1;
    } // end if
    
    b += 3;
    
    return *b;
}
*/

- (bool)extractSPSPPS:(const uint8_t *)pSrc
             strLen:(int)srcLen
               pOut:(void **)pOut
             outLen:(int *)outLen {
    int spsBeginIndex = -1;
	int spsEndIndex = -1;
	int ppsBeginIndex = -1;
	int ppsEndIndex = -1;
	for (int i = 0; i < srcLen - 4 && i< 200; i++)
	{
		if (spsBeginIndex==-1
			&&(pSrc[i] == 0x00 && pSrc[i + 1] == 0x00 && pSrc[i + 2] == 0x00 && pSrc[i + 3] == 0x01 && (pSrc[i + 4]&0x1f)==7)) {
			spsBeginIndex = i + 4;
			continue;
		} else if (spsBeginIndex != -1 && spsEndIndex==-1
                  && (pSrc[i] == 0x00 && pSrc[i + 1] == 0x00 && pSrc[i + 2] == 0x00 && pSrc[i + 3] == 0x01)) {
			spsEndIndex = i - 1;
			ppsBeginIndex = spsEndIndex + 5;
			continue;
		}
		if(ppsBeginIndex!=-1
           && (pSrc[i] == 0x00 && pSrc[i + 1] == 0x00 && pSrc[i + 2] == 0x00 && pSrc[i + 3] == 0x01)) {
			ppsEndIndex = i - 1;
			break;
		}
	}
	//DLog(@"Index:%d %d %d %d\n\n",spsBeginIndex,spsEndIndex,ppsBeginIndex,ppsEndIndex);
	if (spsBeginIndex < 0 || spsEndIndex < 0  || ppsBeginIndex < 0 || ppsEndIndex < 0) {
		return false;
	}
    
    *outLen = ppsEndIndex - spsBeginIndex + 1 + 4;
    *pOut = (void*)malloc(*outLen);
    memcpy(*pOut, pSrc + spsBeginIndex - 4, *outLen);
    
	return true;
}

- (bool)findSpsPps:(const uint8_t *)pSrc
            strLen:(int)srcLen
              pOut:(void **)pOut
            outLen:(int *)outLen
{
    int i;
    int begPos = -1;
    int endPos = -1;
    int headlen = 0;
    for (i=0; i + 5 < srcLen; i++)
    {
        if (pSrc[i]==0 && pSrc[i+1]==0 && pSrc[i+2]==1)
        {
            if ((pSrc[i+3]&0x1f)==7 || (pSrc[i+3]&0x1f)==8 )
            {
                begPos = i;
                headlen = 3;
                break;
            }
        }
        else if (pSrc[i]==0 && pSrc[i+1]==0 && pSrc[i+2]==0 && pSrc[i+3]==1)
        {
            if ((pSrc[i+4]&0x1f)==7 || (pSrc[i+4]&0x1f)==8 )
            {
                begPos = i;
                headlen = 4;
                break;
            }
        }
    }
    
    if (begPos<0)
    {
        return false;
    }
    
    i+=headlen;
    
    for (; i+5<srcLen; i++)
    {
        if (pSrc[i]==0 && pSrc[i+1]==0 && pSrc[i+2]==1)
        {
            if ((pSrc[i+3]&0x1f)!=7 && (pSrc[i+3]&0x1f)!=8 )
            {
                endPos = i;
                break;
            }
        }
        else if (pSrc[i]==0 && pSrc[i+1]==0 && pSrc[i+2]==0 && pSrc[i+3]==1)
        {
            if ((pSrc[i+4]&0x1f)!=7 && (pSrc[i+4]&0x1f)!=8 )
            {
                endPos = i;
                break;
            }
        }
    }
    
    if (endPos == -1)
    {
        endPos = srcLen;
    }
    *outLen = endPos - begPos;
    
    *pOut = (uint8_t*)av_malloc(*outLen);
    memcpy(*pOut, pSrc+begPos, *outLen);
    return true;
}

/*
static bool extractSPSPPS1(const unsigned char* pSrc, int srcLen, void** pOut, int* outLen)
{
	int i;
	int begPos = -1;
	int endPos = -1;
	int headlen = 0;
	for (i=0; i+5<srcLen; i++)
	{
		if (pSrc[i]==0 && pSrc[i+1]==0 && pSrc[i+2]==1)
		{
			if ((pSrc[i+3]&0x1f)==7 || (pSrc[i+3]&0x1f)==8 )
			{
				begPos = i;
				headlen = 3;
                break;
			}
		}
		else if (pSrc[i]==0 && pSrc[i+1]==0 && pSrc[i+2]==0 && pSrc[i+3]==1)
		{
			if ((pSrc[i+4]&0x1f)==7 || (pSrc[i+4]&0x1f)==8 )
			{
				begPos = i;
				headlen = 4;
                break;
			}
		}
	}
    
	if (begPos<0)
	{
		return -1;
	}
    
	i+=headlen;
	for (; i+5<srcLen; i++)
	{
		if (pSrc[i]==0 && pSrc[i+1]==0 && pSrc[i+2]==1)
		{
			if ((pSrc[i+3]&0x1f)!=7 && (pSrc[i+3]&0x1f)!=8 )
			{
				endPos = i;
				break;
			}
		}
		else if (pSrc[i]==0 && pSrc[i+1]==0 && pSrc[i+2]==0 && pSrc[i+3]==1)
		{
			if ((pSrc[i+4]&0x1f)!=7 && (pSrc[i+4]&0x1f)!=8 )
			{
				endPos = i;
				break;
			}
		}
	}
    
	if (endPos == -1)
	{
		endPos = srcLen;
	}
	*outLen = endPos - begPos;
    
	*pOut = (char*)av_malloc(*outLen);
	memcpy(*pOut, pSrc+begPos, *outLen);
	return 0;
    
}
*/

/* Add an output stream */
- (AVStream *)addStream:(AVFormatContext *)oc
                   codec:(AVCodec **)codec
                codec_id:(enum AVCodecID)codec_id
             streamIndex:(int *)streamIndex
{
    AVCodecContext *c;
    AVStream *st;
    
    /* find the encoder */
    *codec = avcodec_find_encoder(codec_id);
    if (!*codec) {
        DLog(@"could not find encoder for '%s' \n", avcodec_get_name(codec_id));
        exit(1);
    }
    
    st = avformat_new_stream(oc, *codec);
    if (!st) {
        DLog(@"could not allocate stream \n");
        exit(1);
    }
    st->id = oc->nb_streams-1;
    c = st->codec;
    *streamIndex = st->index;
    
    switch ((*codec)->type) {
        case AVMEDIA_TYPE_AUDIO:
            c->sample_fmt = AV_SAMPLE_FMT_S16;
            c->bit_rate = _bitRate;
            c->sample_rate = _sampleRate;
            c->channels = 1;
            c->channel_layout = AV_CH_LAYOUT_MONO;
            break;
            
        case AVMEDIA_TYPE_VIDEO:
            c->codec_id = codec_id;
            c->bit_rate = 0;
            c->width = _width;
            c->height = _height;
            // 时间单位比率
            c->time_base.den = _videoFrameRate;
            c->time_base.num = 1;
            c->gop_size = 12;
            c->pix_fmt = kStreamPixFMT;
            c->max_b_frames = 0;
            if (c->codec_id == AV_CODEC_ID_MPEG2VIDEO)
            {
                c->max_b_frames = 2;
            }
            if (c->codec_id == AV_CODEC_ID_MPEG1VIDEO)
            {
                c->mb_decision = 2;
            }
            // 帧率信息
            st->r_frame_rate.den = 1;
            st->r_frame_rate.num = _videoFrameRate;
            break;

        default:
            break;
    }
    
    c->codec_tag = 0;
    if (oc->oformat->flags & AVFMT_GLOBALHEADER) {
        c->flags |= CODEC_FLAG_GLOBAL_HEADER;
    }
    
    return st;
}

- (int)openVideo:(AVFormatContext *)oc
           codec:(AVCodec *)codec
          stream:(AVStream *)stream
          spsPps:(const void*)spsPps
       spsPpsLen:(int)spsPpsLen {
    int ret;
    AVCodecContext *c = stream->codec;
    
    /* open the codec */
    ret = avcodec_open2(c, codec, NULL);
    if (ret < 0) {
        DLog(@"could not open video codec");
        return -1;
    }
	
	c->extradata = (uint8_t *)av_mallocz(spsPpsLen + AV_INPUT_BUFFER_PADDING_SIZE);
	c->extradata_size = spsPpsLen;
	memcpy(c->extradata, spsPps, spsPpsLen);
    
    return 0;
}

- (NSInteger)openAudio:(AVFormatContext *)oc codec:(AVCodec *)codec st:(AVStream *)st {
	int ret;
    AVCodecContext *c = st->codec;
    
	/* open the codec */
	ret = avcodec_open2(c, codec, NULL);
	if (ret < 0) {
		DLog(@"could not open audio codec");
		return -1;
	}
    _audioFrame = av_frame_alloc();
    
	if (!_audioFrame) {
		DLog(@"av_frame_alloc failed");
		return -2;
	}
    
    _audioFrame->format = c->sample_fmt;
    _audioFrame->channel_layout = c->channel_layout;
    _audioFrame->channels = c->channels;
    _audioFrame->sample_rate = c->sample_rate;
    _audioFrame->nb_samples = c->frame_size;

    ret = av_frame_get_buffer(_audioFrame, 0);
	if (ret < 0) {
		DLog(@"av_frame_get_buffer failed:%d", ret);
	}
    
	_pTmpAudioBuf = (uint8_t *)malloc(c->frame_size);
	_nTmpAudioBufLen = 0;
    
    return 0;
}

// 转换 A-law到16-bit PCM
- (int)alaw2linear:(int)a_val {
	int		t;      /* changed from "short" *drago* */
	int		seg;    /* changed from "short" *drago* */
    
	a_val ^= 0x55;
    
	t = (a_val & kQuantizationFieldMask) << 4;
	seg = ((unsigned)a_val & kSegmentFieldMask) >> kSegmentLeftShift;
	switch (seg) {
        case 0:
            t += 8;
            break;
        case 1:
            t += 0x108;
            break;
        default:
            t += 0x108;
            t <<= seg - 1;
	}
	return ((a_val & kSignBit) ? t : -t);
}

- (AVFrame *)pcma2lpcm:(AVFrame *)p_audioFrame {
	int16_t *q = (int16_t *)p_audioFrame->data[0];
	int ret = av_frame_make_writable(p_audioFrame);
	if (ret < 0) {
		DLog(@"av_frame_make_writable error");
		return NULL;
	}
	int i = 0;
	for (; i< _nTmpAudioBufLen; i++) {
		*q++ = [self alaw2linear:_pTmpAudioBuf[i]];
	}
	_nTmpAudioBufLen = 0;
	return _audioFrame;
}

#pragma Test
static void log_packet(const AVFormatContext *fmt_ctx, const AVPacket *pkt, const char *tag)
{
    AVRational *time_base = &fmt_ctx->streams[pkt->stream_index]->time_base;
    
    printf("%s: pts:%s pts_time:%s dts:%s dts_time:%s duration:%s duration_time:%s stream_index:%d\n",
           tag,
           av_ts2str(pkt->pts), av_ts2timestr(pkt->pts, time_base),
           av_ts2str(pkt->dts), av_ts2timestr(pkt->dts, time_base),
           av_ts2str(pkt->duration), av_ts2timestr(pkt->duration, time_base),
           pkt->stream_index);
}

int mainRemuxing(int argc, char **argv)
{
    AVOutputFormat *ofmt = NULL;
    AVFormatContext *ifmt_ctx = NULL, *ofmt_ctx = NULL;
    AVPacket pkt;
    const char *in_filename, *out_filename;
    int ret, i;
    
    if (argc < 3) {
        printf("usage: %s input output\n"
               "API example program to remux a media file with libavformat and libavcodec.\n"
               "The output format is guessed according to the file extension.\n"
               "\n", argv[0]);
        return 1;
    }
    
    in_filename  = argv[1];
    out_filename = argv[2];
    
    av_register_all();
    
    if ((ret = avformat_open_input(&ifmt_ctx, in_filename, 0, 0)) < 0) {
        fprintf(stderr, "Could not open input file '%s'", in_filename);
        goto end;
    }
    
    if ((ret = avformat_find_stream_info(ifmt_ctx, 0)) < 0) {
        fprintf(stderr, "Failed to retrieve input stream information");
        goto end;
    }
    
    av_dump_format(ifmt_ctx, 0, in_filename, 0);
    
    avformat_alloc_output_context2(&ofmt_ctx, NULL, NULL, out_filename);
    if (!ofmt_ctx) {
        fprintf(stderr, "Could not create output context\n");
        ret = AVERROR_UNKNOWN;
        goto end;
    }
    
    ofmt = ofmt_ctx->oformat;
    
    for (i = 0; i < ifmt_ctx->nb_streams; i++) {
        AVStream *in_stream = ifmt_ctx->streams[i];
        AVStream *out_stream = avformat_new_stream(ofmt_ctx, in_stream->codec->codec);
        if (!out_stream) {
            fprintf(stderr, "Failed allocating output stream\n");
            ret = AVERROR_UNKNOWN;
            goto end;
        }
        
        ret = avcodec_copy_context(out_stream->codec, in_stream->codec);
        if (ret < 0) {
            fprintf(stderr, "Failed to copy context from input to output stream codec context\n");
            goto end;
        }
        out_stream->codec->codec_tag = 0;
        if (ofmt_ctx->oformat->flags & AVFMT_GLOBALHEADER)
            out_stream->codec->flags |= AV_CODEC_FLAG_GLOBAL_HEADER;
    }
    av_dump_format(ofmt_ctx, 0, out_filename, 1);
    
    if (!(ofmt->flags & AVFMT_NOFILE)) {
        ret = avio_open(&ofmt_ctx->pb, out_filename, AVIO_FLAG_WRITE);
        if (ret < 0) {
            fprintf(stderr, "Could not open output file '%s'", out_filename);
            goto end;
        }
    }
    
    ret = avformat_write_header(ofmt_ctx, NULL);
    if (ret < 0) {
        fprintf(stderr, "Error occurred when opening output file\n");
        goto end;
    }
    
    while (1) {
        AVStream *in_stream, *out_stream;
        
        ret = av_read_frame(ifmt_ctx, &pkt);
        if (ret < 0)
            break;
        
        in_stream  = ifmt_ctx->streams[pkt.stream_index];
        out_stream = ofmt_ctx->streams[pkt.stream_index];
        
        log_packet(ifmt_ctx, &pkt, "in");
        
        /* copy packet */
        pkt.pts = av_rescale_q_rnd(pkt.pts, in_stream->time_base, out_stream->time_base, AV_ROUND_NEAR_INF|AV_ROUND_PASS_MINMAX);
        pkt.dts = av_rescale_q_rnd(pkt.dts, in_stream->time_base, out_stream->time_base, AV_ROUND_NEAR_INF|AV_ROUND_PASS_MINMAX);
        pkt.duration = av_rescale_q(pkt.duration, in_stream->time_base, out_stream->time_base);
        pkt.pos = -1;
        log_packet(ofmt_ctx, &pkt, "out");
        
        ret = av_interleaved_write_frame(ofmt_ctx, &pkt);
        if (ret < 0) {
            fprintf(stderr, "Error muxing packet\n");
            break;
        }
        av_packet_unref(&pkt);
    }
    
    av_write_trailer(ofmt_ctx);
end:
    
    avformat_close_input(&ifmt_ctx);
    
    /* close output */
    if (ofmt_ctx && !(ofmt->flags & AVFMT_NOFILE))
        avio_closep(&ofmt_ctx->pb);
    avformat_free_context(ofmt_ctx);
    
    if (ret < 0 && ret != AVERROR_EOF) {
        fprintf(stderr, "Error occurred: %s\n", av_err2str(ret));
        return 1;
    }
    
    return 0;
}

@end
