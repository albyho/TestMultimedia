//
//  FAACAACEncoder.h
//  ProjectLibrary
//
//  Created by alby on 15/1/24.
//  Copyright (c) 2015年 alby. All rights reserved.
//

/*
 
 1、PCM格式：44.1kHz, 16Bit sample, 1 Channel
 2、AAC格式：AAC LC 44.1kHz, 1 Channel, 64Kbps
 3、每次最多输入1024次采样的PCM数据，即2048字节。
 
 */

#import <Foundation/Foundation.h>

@interface FAACAACEncoder : NSObject

@property (nonatomic,readonly) uint8_t *aacBuffer;

- (int)startup:(unsigned long)bitRate;

- (int)encodeWithPCMBuffer:(void *)pcmBuffer;

- (int)shutdown;

@end
