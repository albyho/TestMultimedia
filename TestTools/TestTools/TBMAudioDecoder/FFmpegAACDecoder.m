//
//  FFmpegAACDecoder.m
//  ProjectLibrary
//
//  Created by alby ho on 12-4-11.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "FFmpegAACDecoder.h"
#import <math.h>
#import "ProjectUtils.h"
#import "TBMADTS.h"

#define kSameleRate     44100
#define kBitDepth       16
#define kChannelNumber  1

@interface FFmpegAACDecoder()
{
    struct AVCodec                  *_codec;
    struct AVCodecContext           *_codecContext;
    struct AVFrame                  *_sourceFrame;
    struct SwrContext               *_swrContext;
    AVPacket                        _packet;
}
@end

@implementation FFmpegAACDecoder

+(void)initialize {
    if (self == [FFmpegAACDecoder class]) {
        //DLog(@"%s",__PRETTY_FUNCTION__);
        av_register_all();
    }
}

- (instancetype)init {
    //DLog(@"VideoDecoder init");
	if(self = [super init]) {
        [self setupCodec];
        [self setupCodecContext];
	}
	
	return self;
}

// 设置解码器
- (void)setupCodec {
    //DLog(@"%s",__PRETTY_FUNCTION__);
    
    _codec = avcodec_find_decoder(AV_CODEC_ID_AAC);
    _sourceFrame = av_frame_alloc();
}

// 设置解码上下文
- (void)setupCodecContext {
    //DLog(@"%s(%d,%d)",__PRETTY_FUNCTION__);
    
    if(_codecContext) {
        avcodec_close(_codecContext);
        av_free(_codecContext);
    }
    
    _codecContext = avcodec_alloc_context3(_codec);
    //DLog(@"---- %d %d %d %d %d",_codecContext->codec_type,_codecContext->sample_rate,_codecContext->channels,_codecContext->bit_rate,_codecContext->sample_fmt);
    //_codecContext->codec_type = AVMEDIA_TYPE_AUDIO;
    //_codecContext->bit_rate = 64000;
    //_codecContext->sample_fmt = AV_SAMPLE_FMT_S16;
    //_codecContext->channel_layout = AV_CH_LAYOUT_MONO;
    //_codecContext->sample_rate = kSameleRate;
    _codecContext->channels = kChannelNumber;
    _codecContext->bits_per_coded_sample = kBitDepth;

    int res = avcodec_open2(_codecContext, _codec, NULL);
    if (res < 0) {
        DLog(@"%@ Failed to initialize decoder", __FUNCTION_FILE_LINE__);
    }
    
    av_init_packet(&_packet);
    _packet.data = NULL;
    _packet.size = 0;
}

- (BOOL)setupSwrContext {
    if(_swrContext)
        return YES;
    
    int res;
    
    _swrContext = swr_alloc_set_opts(NULL,                      // we're allocating a new context
                                 AV_CH_LAYOUT_MONO,         // out_ch_layout
                                 AV_SAMPLE_FMT_S16,         // out_sample_fmt
                                 kSameleRate,               // out_sample_rate
                                 av_get_default_channel_layout(_codecContext->channels), // in_ch_layout
                                 _codecContext->sample_fmt,     // in_sample_fmt
                                 _codecContext->sample_rate,    // in_sample_rate
                                 0,                         // log_offset
                                 NULL);                     // log_ctx
    
    if ((res = swr_init(_swrContext)) < 0) {
        DLog(@"Could not allocate SwrContext\n");
        return NO;
    }

    return YES;
}

// 设置拉伸（初始化VideoDecoder后，如果要使用应首先执行setupDecoder方法）
- (void)setupDecoder {
    //DLog(@"%s(%d,%d)",__PRETTY_FUNCTION__);

    // 重新设置解码上下文
    [self setupCodecContext];
}

- (NSData *)decodeWithData:(NSData *)frameData {
    return [self decodeWithData:frameData start:0];
}

- (NSData *)decodeWithData:(NSData *)frameData
                     start:(NSUInteger)start {
    //DLog(@"%s(%lu,%lu)",__PRETTY_FUNCTION__,(unsigned long)frameData.length,(unsigned long)start);


    if (![self decodeDataToFrame:frameData start:start result:_sourceFrame])
        return nil;

    if(![self setupSwrContext])
        return nil;

    int needed_buf_size = av_samples_get_buffer_size(NULL,
                                                     _codecContext->channels,
                                                     _sourceFrame->nb_samples,
                                                     AV_SAMPLE_FMT_S16, 0);
    
    uint8_t *outData = (uint8_t *)malloc(needed_buf_size);
    int outSamples = swr_convert(_swrContext,
                                 &outData,
                                 needed_buf_size,
                                 (const uint8_t**)_sourceFrame->extended_data,
                                 _sourceFrame->nb_samples);
    
    av_frame_unref(_sourceFrame);

    int resampledDataSize = outSamples * _codecContext->channels * av_get_bytes_per_sample(AV_SAMPLE_FMT_S16);
    NSData *data = [NSData dataWithBytesNoCopy:outData length:resampledDataSize freeWhenDone:YES];
    
    return data;
}

// 解码，成功后保存在result参数中
- (BOOL)decodeDataToFrame:(NSData *)frameData
                    start:(NSUInteger)start
                   result:(AVFrame *)result {
    //DLog(@"%s(%lu,%lu)",__PRETTY_FUNCTION__,(unsigned long)frameData.length,(unsigned long)start);
    if(!frameData){
        DLog(@"%@ frameData is nil", __FUNCTION_FILE_LINE__);
        return NO;
    }

    uint8_t *rawData = (uint8_t *)[frameData bytes] + start;
    int rawDataLength = (int)([frameData length] - start);
    if (rawDataLength < 7) {
        DLog(@"%@ data length is less than 7", __FUNCTION_FILE_LINE__);
        unsigned char buff[7];
        [frameData getBytes:buff range:NSMakeRange(sizeof(uint64_t), 7)];
        adts_fixed_header header;
        get_fixed_header(buff, &header);

        return NO;
    }
    
	_packet.data = rawData;
    _packet.size = rawDataLength;
	    
    int res;
    res = avcodec_send_packet(_codecContext, &_packet);
    if (res < 0 && res != AVERROR(EAGAIN) && res != AVERROR_EOF){
        DLog(@"%s avcodec_send_packet() error decoding audio frame (%s)\n", __FUNCTION__, av_err2str(res));
        return NO;
    }
    
    res = avcodec_receive_frame(_codecContext, result);
    if (res < 0 && res != AVERROR_EOF) {
        DLog(@"%s avcodec_receive_frame() error decoding audio frame (%s)\n", __FUNCTION__, av_err2str(res));
        return NO;
    }
    
    return YES;
}

- (void)dealloc {
    DLog(@"%@", __FUNCTION_FILE_LINE__);
    
    if (_codecContext) {
        avcodec_close(_codecContext);
        avcodec_free_context(&_codecContext);
    }

    if(_swrContext) {
        swr_free(&_swrContext);
    }

    if(_sourceFrame) {
        av_free(_sourceFrame);
    }
}

@end

