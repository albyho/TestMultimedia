//
//  MP4Writer.h
//  ProjectLibrary
//
//  Created by alby on 14-7-22.
//  Copyright (c) 2014年 alby. All rights reserved.
//

/*
 
 1、视频格式：H.264
 2、音频格式：AAC PCM G711a, 16Bit
 
 TODO:
 1、整理代码
 2、转为使用最新版FFmpeg
 
 */

#import <Foundation/Foundation.h>
#import "TBMDefines.h"

typedef NS_ENUM(NSUInteger, FFmpegMP4WriterAudioType) {
    FFmpegMP4WriterAudioTypeNone,
    FFmpegMP4WriterAudioTypeAAC,
    FFmpegMP4WriterAudioTypePCM,
    FFmpegMP4WriterAudioTypeG711a
};

@protocol FFmpegMP4WriterDelegate <NSObject>
@required
- (void)beginWrite:(NSString *)messge;
- (void)endWrite:(NSString *)messge;
- (void)saveVideo:(NSString *)messge;
- (void)error:(NSInteger)errorCode message:(NSString *)messge;

@end

@interface FFmpegMP4Writer : NSObject

@property (nonatomic, weak)      id<FFmpegMP4WriterDelegate> delegate;

- (BOOL)beginWriteUnusedAudioWithVideoFrameRate:(int)videoFrameRate width:(int)width height:(int)height error:(NSError **)error;
- (BOOL)beginWriteUseAACWithVideoFrameRate:(int)videoFrameRate width:(int)width height:(int)height sampleRate:(int)sampleRate bitRate:(uint64_t)bitRate error:(NSError **)error;
- (BOOL)beginWriteUsePCMWithVideoFrameRate:(int)videoFrameRate width:(int)width height:(int)height sampleRate:(int)sampleRate bitRate:(uint64_t)bitRate error:(NSError **)error;
- (BOOL)beginWriteUseG711aWithVideoFrameRate:(int)videoFrameRate width:(int)width height:(int)height sampleRate:(int)sampleRate bitRate:(uint64_t)bitRate error:(NSError **)error;

// TODO: 重构
// 注：不要混用两个 writeFrame
- (BOOL)writeFrame:(TBMFrameType)frameType
         frameData:(const void *)frameData
      frameDataLen:(int)frameDataLen
             start:(NSUInteger)start
             error:(NSError **)error;

- (BOOL)writeFrame:(TBMFrameType)frameType
         frameData:(const void *)frameData
      frameDataLen:(int)frameDataLen
             start:(NSUInteger)start
               pts:(int64_t)pts /* 单位：微秒（直播保存的是微秒） */
             error:(NSError **)error;

- (BOOL)endWrite:(NSError **)error;
- (BOOL)saveVideo:(NSError **)error;



@end
