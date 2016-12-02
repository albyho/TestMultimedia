//
//  FFmpegPCMResampler.m
//  ProjectLibrary
//
//  Created by alby on 15/1/27.
//  Copyright (c) 2015年 alby. All rights reserved.
//

#import "FFmpegPCMResampler.h"
#import "ProjectUtils.h"
#include <libavutil/opt.h>
#include <libavutil/channel_layout.h>
#include <libavutil/samplefmt.h>
#include <libswresample/swresample.h>

@interface FFmpegPCMResampler ()
{
    SwrContext                      *_swr_ctx;
    uint8_t                         **_dst_data;
    int64_t                         _src_ch_layout;
    int64_t                         _dst_ch_layout;
    int32_t                         _src_nb_samples_previous;
    int32_t                         _max_dst_nb_samples;
    enum AVSampleFormat             _src_sample_fmt;
    enum AVSampleFormat             _dst_sample_fmt;
    int32_t                         _src_rate;
    int32_t                         _dst_rate;
    int32_t                         _src_nb_channels;
    int32_t                         _dst_nb_channels;
}
@end

@implementation FFmpegPCMResampler

- (instancetype)initWithSrcChLayout:(int64_t)src_ch_layout
                      dst_ch_layout:(int64_t)dst_ch_layout
                     src_sample_fmt:(enum AVSampleFormat)src_sample_fmt
                     dst_sample_fmt:(enum AVSampleFormat)dst_sample_fmt
                           src_rate:(int)src_rate
                           dst_rate:(int)dst_rate {

    self = [super init];
    if(self) {
        _src_nb_samples_previous = 0;
        _max_dst_nb_samples = 0;
        
        _src_ch_layout = src_ch_layout;
        _dst_ch_layout = dst_ch_layout;
        
        _src_sample_fmt = src_sample_fmt;
        _dst_sample_fmt = dst_sample_fmt;   // 设置成 AV_CH_LAYOUT_MONO,AV_SAMPLE_FMT_S16P 等平面格式可能会失败，未测试
        
        _src_rate = src_rate;
        _dst_rate = dst_rate;

        [self setup];
    }
    return self;

}

- (BOOL)setup {
    int ret;
    //*
    _swr_ctx = swr_alloc_set_opts(NULL,                 // we're allocating a new context
                                  _dst_ch_layout,       // out_ch_layout
                                  _dst_sample_fmt,      // out_sample_fmt
                                  _dst_rate,            // out_sample_rate
                                  _src_ch_layout,       // in_ch_layout
                                  _src_sample_fmt,      // in_sample_fmt
                                  _src_rate,            // in_sample_rate
                                  0,                    // log_offset
                                  NULL);                // log_ctx
    //*/
    //_swr_ctx = swr_alloc();
    /*
     // set options
     av_opt_set_int(_swr_ctx, "in_channel_layout",    _src_ch_layout, 0);
     av_opt_set_int(_swr_ctx, "in_sample_rate",       _src_rate, 0);
     av_opt_set_sample_fmt(_swr_ctx, "in_sample_fmt", _src_sample_fmt, 0);
     
     av_opt_set_int(_swr_ctx, "out_channel_layout",    _dst_ch_layout, 0);
     av_opt_set_int(_swr_ctx, "out_sample_rate",       _dst_rate, 0);
     av_opt_set_sample_fmt(_swr_ctx, "out_sample_fmt", _dst_sample_fmt, 0);
     */
    
    // initialize the resampling context
    if ((ret = swr_init(_swr_ctx)) < 0) {
        DLog(@"%s swr_init() Could not allocate resampler context", __FUNCTION__);
        return NO;
    }

    _src_nb_channels = av_get_channel_layout_nb_channels(_src_ch_layout);
    _dst_nb_channels = av_get_channel_layout_nb_channels(_dst_ch_layout);

    return YES;
}

- (NSData *)resampleWithPCMBuffer:(void **)pcmBuffer sampleCount:(int)sampleCount {
    
    if(pcmBuffer == NULL || sampleCount <= 0) {
        return nil;
    }
    
    int ret;
    int dst_linesize;
    int dst_bufsize;
    int dst_nb_samples;
    
    if(_src_nb_samples_previous != sampleCount) {
        // compute the number of converted samples: buffering is avoided
        // ensuring that the output buffer will contain at least all the
        // converted input samples
        _max_dst_nb_samples = dst_nb_samples = (int)av_rescale_rnd(sampleCount, _dst_rate, _src_rate, AV_ROUND_UP);
        
        /* buffer is going to be directly written to a rawaudio file, no alignment */
        if(_dst_data) {
            if(_dst_data[0]) {
                av_freep(&_dst_data[0]);
            }
            av_freep(&_dst_data);
        }
        ret = av_samples_alloc_array_and_samples(&_dst_data, &dst_linesize, _dst_nb_channels, dst_nb_samples, _dst_sample_fmt, 0);
        if (ret < 0) {
            DLog(@"%s av_samples_alloc_array_and_samples() Could not allocate destination samples", __FUNCTION__);
            return nil;
        }
        
        _src_nb_samples_previous = sampleCount;

    } else {
        // compute destination number of samples
        dst_nb_samples = (int)av_rescale_rnd(swr_get_delay(_swr_ctx, _src_rate) + sampleCount, _dst_rate, _src_rate, AV_ROUND_UP);
        if (dst_nb_samples > _max_dst_nb_samples) {
            av_freep(&_dst_data[0]);
            ret = av_samples_alloc(_dst_data, &dst_linesize, _dst_nb_channels, dst_nb_samples, _dst_sample_fmt, 1);
            if (ret < 0) {
                DLog(@"%s av_samples_alloc() Error while realloc", __FUNCTION__);
                return nil;;
            }
            
            _max_dst_nb_samples = dst_nb_samples;
        }
    }
    
    // convert to destination format
    ret = swr_convert(_swr_ctx, _dst_data, dst_nb_samples, (const uint8_t**)pcmBuffer, sampleCount);
    if (ret < 0) {
        DLog(@"%s swr_convert() Error while converting", __FUNCTION__);
        return nil;
    }
    
    dst_bufsize = av_samples_get_buffer_size(&dst_linesize, _dst_nb_channels, ret, _dst_sample_fmt, 1);
    if (dst_bufsize < 0) {
        DLog(@"%s av_samples_get_buffer_size() Could not get sample buffer size", __FUNCTION__);
        return nil;
    }
    
    //DLog(@"in:%d out:%d size:%d\n ", src_nb_samples, ret, dst_bufsize);
    NSData *result = [NSData dataWithBytes:_dst_data[0] length:dst_bufsize];
    return result;
}

- (void)dealloc {
    DLog(@"%@", __FUNCTION_FILE_LINE__);
    
    if(_swr_ctx) {
        swr_free(&_swr_ctx);
    }
    
    if(_dst_data) {
        if (_dst_data[0]) {
            av_freep(&_dst_data[0]);
        }
        av_freep(&_dst_data);
    }
}

@end
