//
//  FFmpegAACEncoder.h
//  ProjectLibrary
//
//  Created by alby on 16/3/31.
//  Copyright © 2016年 alby. All rights reserved.
//

/*
 
 1、PCM格式：44.1kHz, 16Bit sample, 1 Channel
 2、AAC格式：AAC LC 44.1kHz, 1 Channel, 自定义码流
 3、每次最多输入1024次采样的PCM数据，即2048字节。
 
 */

#import <Foundation/Foundation.h>

@interface FFmpegAACEncoder : NSObject

- (int)startup:(unsigned long)bitRate;

- (NSData *)encodeWithPCMBuffer:(const void *)pcmBuffer;

- (int)shutdown;

@end
