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

const AVRational usTimeBase = {1,1000000};

@implementation FFmpegMP4Writer
{
    // 写入、保存标记
    BOOL                  _isReadyToWrite;
    BOOL                   _isReadyToSave;
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
    
    // Video
    BOOL            _isWaitingForKeyFrame;
    int                 _videoStreamIndex;
    AVStream                 *videoStream;
    long long                   _videopts;

    // Audio
    int                 _audioStreamIndex;
    AVFrame                  *_audioFrame;
    AVStream                *_audioStream;
    uint8_t                *_pTmpAudioBuf; // 音频临时缓冲区
    int                  _nTmpAudioBufLen; // 音频临时缓冲区长度
    long long                   _audiopts;
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
        if( _isReadyToWrite )
        {
            av_write_trailer(_avFormatContext);
        }
        
        if(videoStream) {
            avcodec_close(videoStream->codec);
            videoStream = NULL; // avformat_free_context:Free an _avFormatContext and all its streams.
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
    _isReadyToSave = NO;
    _videoStreamIndex = -1;
    _audioStreamIndex = -1;
    _isWaitingForKeyFrame = YES;
    _videopts = 0;
    _audiopts = 0;
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
                 sampleRate:0
                    bitRate:0
                      error:error];
}
- (BOOL)beginWriteUsePCMWithVideoFrameRate:(int)videoFrameRate width:(int)width height:(int)height sampleRate:(int)sampleRate bitRate:(uint64_t)bitRate error:(NSError **)error {
    return [self beginWrite:FFmpegMP4WriterAudioTypePCM
             videoFrameRate:videoFrameRate
                      width:width
                     height:height
                 sampleRate:0
                    bitRate:0
                      error:error];

}
- (BOOL)beginWriteUseG711aWithVideoFrameRate:(int)videoFrameRate width:(int)width height:(int)height sampleRate:(int)sampleRate bitRate:(uint64_t)bitRate error:(NSError **)error {
    return [self beginWrite:FFmpegMP4WriterAudioTypeG711a
             videoFrameRate:videoFrameRate
                      width:width
                     height:height
                 sampleRate:0
                    bitRate:0
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
    
    _isReadyToSave = YES;
    
    /*
    if([self.delegate respondsToSelector:@selector(endWriteCallback:)])
    {
        [self.delegate endWriteCallback:@"保存录像成功,准备复制到相册."];
    }
    */
    
    return YES;
}

- (void)error:(NSInteger)errorCode message:(NSString *)messge {
    if(!self.delegate||![self.delegate respondsToSelector:@selector(error:message:)])
        return;
    
    [self.delegate error:errorCode message:messge];
}

/*
- (void)beginWrite
{
    NSString *testVideoPath = [[NSBundle mainBundle] pathForResource:@"Test" ofType:@"mp4"];
    NSData *testVideoData = [NSData dataWithContentsOfFile:testVideoPath];
    
    NSOutputStream *outputStream = [[NSOutputStream alloc] initToFileAtPath:kMP4TempFile append:YES];
    [outputStream open];
    
    [outputStream write:[testVideoData bytes] maxLength:[testVideoData length]];

}
*/

- (BOOL)saveVideo:(NSError **)error {
    if( !_isReadyToSave ) {
        [self error:700 message:@"保存录像到相册失败,录制时间过短."];
        DLog(@"%@ MP4WriterTemp.mp4尚未准备好.", __FUNCTION_FILE_LINE__);
        return NO;
    }
    /*
    if( !videoName ) {
        videoName = [NSString stringWithFormat:@"%@.mp4",[_dateTimeFormatter stringFromDate:[NSDate date]]];
        DLog(@"%s 文件名参数为空,生成文件名:%@",__PRETTY_FUNCTION__,videoName);
    }
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *videoPath = [[kMP4WriterTempFile stringByDeletingLastPathComponent] stringByAppendingPathComponent:videoName];
    DLog(@"%s 视频文件路径:%@",__PRETTY_FUNCTION__,videoPath);
    if(![fileManager moveItemAtPath:kMP4WriterTempFile toPath:videoPath error:nil]) {
        [self error:701 message:@"保存录像到相册失败,请再试."];
        DLog(@"%s 无法将%@更名为%@",__PRETTY_FUNCTION__,kMP4WriterTempFile,videoPath);
        return nil;
    }
    //*/
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
    
    if ( _isReadyToSave ) {
        [self endWrite:nil];
        [self saveVideo:nil];
    }
    
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
        if(![self find_spspps:(const unsigned char*)frameData strLen:frameDataLen pOut:&pSpsPps outLen:&spsPpsLen]) {
            DLog(@"could not find sps or pps");
            return NO;
        }
        
        const char *distFile = [kTempFile UTF8String];
        
        avformat_alloc_output_context2(&_avFormatContext, NULL, NULL, distFile);
        if (!_avFormatContext) {
            DLog(@"could not deduce output format from file extension");
            [self destroy];
            return NO;
            //DLog(@"could not deduce output format from file extension: using MPEG. ");
            //avformat_alloc_output_context2(&_avFormatContext, NULL, "mpeg", distFile);
        }
        fmt = _avFormatContext->oformat;
        if (fmt->video_codec != AV_CODEC_ID_NONE) {
            videoStream = [self addStream:_avFormatContext codec:&videoCodec codec_id:fmt->video_codec streamIndex:&_videoStreamIndex];
        } else {
            DLog(@"video codec is none");
            [self destroy];
            return NO;
        }
        
        if (videoStream) {
            [self openVideo:_avFormatContext codec:videoCodec stream:videoStream spsPps:pSpsPps spsPpsLen:spsPpsLen];
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
    
    pkt.stream_index = videoStream->index;
    pkt.data = (uint8_t*)(frameData + start);
    pkt.size = frameDataLen;
    
    if(pts >= 0) {
        pkt.pts = av_rescale_q(pts, usTimeBase, videoStream->time_base);;
    } else {
        pkt.pts = av_rescale_q(_videopts, videoStream->codec->time_base,videoStream->time_base);
    }
    pkt.dts = pkt.pts;
    ret = av_interleaved_write_frame( _avFormatContext, &pkt );
    av_packet_unref(&pkt);
    if ( 0 > ret ) {
        DLog(@"cannot write video frame");
        return NO;
    } else {
        _videopts++;
    }
    
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
    if ( 0 > _audioStreamIndex ) {
        DLog(@"ai less than 0");
        return NO;
    }

    if ( _isWaitingForKeyFrame ) {
        DLog(@"video key frame is not ready");
        return NO;
    }
    //AVStream *_audioStream = _avFormatContext->streams[ _audioStreamIndex ];
    
    const void *data = frameData + start;
    if(_audioType == FFmpegMP4WriterAudioTypeAAC) {
        AVPacket pkt = {0};
        av_init_packet(&pkt);
        pkt.stream_index = _audioStream->index;
        pkt.data = (uint8_t *)data;
        pkt.size = frameDataLen;
        if(pts >= 0) {
            pkt.pts = av_rescale_q(_audiopts, usTimeBase, videoStream->time_base);;
        } else {
            pkt.pts = av_rescale_q(_audiopts, _audioStream->codec->time_base, _audioStream->time_base);
        }
        pkt.dts = pkt.pts;
        pkt.duration = 0;
        //pkt.duration = (int)av_rescale_q(pkt.duration, _audioStream->codec->time_base,_audioStream->time_base);
        if (av_interleaved_write_frame( _avFormatContext, &pkt ) < 0) {
            DLog(@"cannot write audio frame");
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

- (bool)find_spspps:(const uint8_t *)pSrc
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
		return - 1;
	}
    
    *outLen = ppsEndIndex - spsBeginIndex + 1 + 4;
    *pOut = (void*)malloc(*outLen);
    memcpy(*pOut, pSrc + spsBeginIndex - 4, *outLen);
    
	return true;
}

/*
static bool find_spspps1(const unsigned char* pSrc, int srcLen, void** pOut, int* outLen)
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
    if (!st)
    {
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

@end
