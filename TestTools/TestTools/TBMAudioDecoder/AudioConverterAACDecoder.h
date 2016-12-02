//
//  AudioConverterAACDecoder.h
//  ProjectLibrary
//
//  Created by alby on 15/1/27.
//  Copyright (c) 2015年 alby. All rights reserved.
//

/*
 
 1、AAC格式：AAC LC 44.1kHz, 1 Channel
 2、PCM格式：44.1kHz, 16Bit sample, 1 Channel
 3、每次固定输出 1 包 AAC 数据，不包含 ADTS (可通过 start 参数跳过)
 
*/

#import <Foundation/Foundation.h>
@import CoreMedia;

@interface AudioConverterAACDecoder : NSObject

- (NSData *)decodeWithData:(NSData *)frameData;

- (NSData *)decodeWithData:(NSData *)frameData
                     start:(NSUInteger)start;

@end

// 不完善
