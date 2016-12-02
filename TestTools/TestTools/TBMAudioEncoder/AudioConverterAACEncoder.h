//
//  AudioConverterAACEncoder.h
//  ProjectLibrary
//
//  Created by alby on 15/1/27.
//  Copyright (c) 2015年 alby. All rights reserved.
//

/*
 
 1、PCM格式：44.1kHz, 16Bit sample, 1 Channel
 2、AAC格式：AAC LC 44.1kHz, 1 Channel, 64Kbps
 3、每次最多输入1024次采样的 PCM 数据，即2048字节；如果少于1024次采样，则会缓存。注：存在极少情况会出现采样多于1024的情况，尚未处理。
 
*/

#import <Foundation/Foundation.h>
@import CoreMedia;

@interface AudioConverterAACEncoder : NSObject

- (NSMutableData *)encodeWithSampleBuffer:(CMSampleBufferRef)sampleBuffer;

@end

