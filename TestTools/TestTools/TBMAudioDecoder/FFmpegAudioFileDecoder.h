//
//  FFmpegAudioFileDecoder.h
//  ProjectLibrary
//
//  Created by alby on 2016/11/29.
//  Copyright © 2016年 alby. All rights reserved.
//

/*
 
 1、源文件需包含音频流
 2、输出文件格式：PCM 44.1kHz, 16Bit sample, 1 Channel
 3、目前仅 mp3 正常，测试过 mov, m4v 不行
 */

#import <Foundation/Foundation.h>

extern NSString *const FFmpegAudioFileDecoderErrorDomain;

@interface FFmpegAudioFileDecoder : NSObject

- (BOOL)decodeWithSourceFilePath:(NSString *)sourceFilePath
             destinationFilePath:(NSString *)destinationFilePath
               completionHandler:(void (^)(void))completionHandler
                    errorHandler:(void (^)(NSError *error))errorHandler;

@end
