//
//  FFmpegPCM2AACEncoder.m
//  ProjectLibrary
//
//  Created by alby on 16/3/31.
//  Copyright © 2016年 alby. All rights reserved.
//

#import "FFmpegAACEncoder.h"
#import "ProjectUtils.h"
#include <libavutil/opt.h>
#include <libavcodec/avcodec.h>
#include <libavutil/imgutils.h>
#import "TBMADTS.h"

#define kSampleRate         44100
#define kChannelCount       1
#define kBitDepth           16
#define kSampleNumber       1024
#define kADTSPacketLength   7

@interface FFmpegAACEncoder ()
{
    AVCodec             *_codec;
    AVCodecContext      *_codecContext;
    AVFrame             *_sourceFrame;
    AVPacket            _packet;
}

@end

@implementation FFmpegAACEncoder

+ (void)initialize {
    if (self == [FFmpegAACEncoder class]) {
        //DLog(@"%s",__PRETTY_FUNCTION__);
        /* register all formats and codecs */
        avcodec_register_all();
    }
}

- (instancetype)init {
    self = [super init];
    if(self) {
        _codec = avcodec_find_encoder(AV_CODEC_ID_AAC);
    }
    return self;
}

- (int)startup:(unsigned long)bitRate {
    [self shutdown];
    _codecContext = avcodec_alloc_context3(_codec);
    //_codecContext->strict_std_compliance = FF_COMPLIANCE_EXPERIMENTAL;
    _codecContext->profile = FF_PROFILE_AAC_LOW;
    _codecContext->codec_id = AV_CODEC_ID_AAC;
    _codecContext->codec_type = AVMEDIA_TYPE_AUDIO;
    _codecContext->sample_fmt = AV_SAMPLE_FMT_S16;
    _codecContext->sample_rate = kSampleRate;
    _codecContext->channel_layout = AV_CH_LAYOUT_MONO;
    _codecContext->channels = av_get_channel_layout_nb_channels(_codecContext->channel_layout);
    _codecContext->bit_rate = bitRate;
    
    if (avcodec_open2(_codecContext, _codec, NULL) < 0) {
        DLog(@"%s avcodec_open2() could not open codec\n", __FUNCTION__);
        return -1;
    }

    _sourceFrame = av_frame_alloc();
    _sourceFrame->nb_samples= _codecContext->frame_size;
    _sourceFrame->format= _codecContext->sample_fmt;
    _sourceFrame->channels = 1;
    _sourceFrame->channel_layout = _codecContext->channel_layout;

    av_init_packet(&_packet);
    _packet.data = NULL;
    _packet.size = 0;

    return 0;

}

- (NSData *)encodeWithPCMBuffer:(const void *)pcmBuffer {

    _sourceFrame->data[0] = (uint8_t *)pcmBuffer;

    _packet.data = NULL;    // packet data will be allocated by the encoder
    _packet.size = 0;
    
    int res;
    res = avcodec_send_frame(_codecContext, _sourceFrame);
    if (res < 0 && res != AVERROR(EAGAIN) && res != AVERROR_EOF){
        DLog(@"%s avcodec_send_frame() error encoding audio frame (%s)\n", __FUNCTION__, av_err2str(res));
        return nil;
    }
    res = avcodec_receive_packet(_codecContext, &_packet);
    if (res < 0 && res != AVERROR_EOF) {
        DLog(@"%s avcodec_receive_packet() error encoding audio frame (%s)\n", __FUNCTION__, av_err2str(res));
        return nil;
    }
    if(_packet.size <= 0 || _packet.data == NULL) {
        DLog(@"%s ???\n", __FUNCTION__);
        av_packet_unref(&_packet);
        return nil;
    }
    
    NSData *data = [NSData dataWithBytes:_packet.data length:_packet.size];
    
    av_packet_unref(&_packet);

    return data;
}

- (int)shutdown {
    if(_codecContext) {
        avcodec_close(_codecContext);
        avcodec_free_context(&_codecContext);
    }
    
    if(_sourceFrame) {
        if(_sourceFrame->data[0]) {
            //av_freep(&_sourceFrame->data[0]); // data 从外部传入，不负责释放
            _sourceFrame->data[0] = NULL;
        }
        av_frame_free(&_sourceFrame);
    }
    
    return 0;
}

- (void)dealloc {
    DLog(@"%@", __FUNCTION_FILE_LINE__);
    
    [self shutdown];
}

@end
