//
//  VideoUtils.h
//  ProjectLibrary
//
//  Created by alby on 15/3/23.
//  Copyright (c) 2015年 alby. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreMedia/CMSampleBuffer.h>

@class AVAsset;

@interface VideoUtils : NSObject

+ (UIImage *)extractImageFromVideoFileWithAsset:(AVAsset *)asset;
+ (UIImage *)extractImageFromVideoFileWithURL:(NSURL *)url;
+ (UIImage *)extractImageFromVideoFileWithPath:(NSString *)path;
+ (NSUInteger)degressFromVideoFileWithAsset:(AVAsset *)asset;
+ (NSUInteger)degressFromVideoFileWithURL:(NSURL *)url;
+ (NSUInteger)degressFromVideoFileWithPath:(NSString *)path;

+ (UIImage *)imageFromSampleBuffer:(CMSampleBufferRef)sampleBuffer;

@end
