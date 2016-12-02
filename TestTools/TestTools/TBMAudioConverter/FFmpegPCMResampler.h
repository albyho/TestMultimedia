//
//  PCMResampler.h
//  ProjectLibrary
//
//  Created by alby on 15/1/27.
//  Copyright (c) 2015年 alby. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <libavutil/samplefmt.h>

@interface FFmpegPCMResampler : NSObject

- (instancetype)initWithSrcChLayout:(int64_t)src_ch_layout
                      dst_ch_layout:(int64_t)dst_ch_layout
                     src_sample_fmt:(enum AVSampleFormat)src_sample_fmt
                     dst_sample_fmt:(enum AVSampleFormat)dst_sample_fmt
                           src_rate:(int)src_rate
                           dst_rate:(int)dst_rate;

- (NSData *)resampleWithPCMBuffer:(void **)pcmBuffer sampleCount:(int)sampleCount;

@end
