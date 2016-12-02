//
//  FFmpegAACDecoder.h
//  ProjectLibrary
//
//  Created by alby ho on 12-4-11.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

/*
 
 1、AAC格式：AAC LC 44.1kHz, 1 Channel
 2、PCM格式：44.1kHz, 16Bit sample, 1 Channel
 3、每次最多输入 1 个 AAC 帧。
 
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIImage.h>
#import <libavformat/avformat.h>
#import <libavcodec/avcodec.h>
#import <libavutil/pixfmt.h>
#import <libswscale/swscale.h>
#import <libswresample/swresample.h>

@interface FFmpegAACDecoder : NSObject

- (NSData *)decodeWithData:(NSData *)frameData;

- (NSData *)decodeWithData:(NSData *)frameData
                     start:(NSUInteger)start;

@end
