//
//  VideoUtils.m
//  ProjectLibrary
//
//  Created by alby on 15/3/23.
//  Copyright (c) 2015年 alby. All rights reserved.
//

#import "VideoUtils.h"
#import "ProjectUtils.h"
#import <AVFoundation/AVAsset.h>
#import <AVFoundation/AVAssetImageGenerator.h>
#import <AVFoundation/AVMediaFormat.h>
#import <AVFoundation/AVCompositionTrack.h>
#import <CoreMedia/CMSampleBuffer.h>

@implementation VideoUtils

+ (UIImage *)extractImageFromVideoFileWithAsset:(AVAsset *)asset
{
    AVAssetImageGenerator *gen = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    // 应用方向
    gen.appliesPreferredTrackTransform = YES;
    CMTime time = CMTimeMakeWithSeconds(1, 600);
    NSError *error = nil;
    CMTime actualTime;
    CGImageRef image = [gen copyCGImageAtTime:time actualTime:&actualTime error:&error];
    if(error) {
        DLog(@"%@ %@", __FUNCTION_FILE_LINE__, error);
        return nil;
    }
    UIImage *thumb = [[UIImage alloc] initWithCGImage:image];
    CGImageRelease(image);
    
    return thumb;
}

+ (UIImage *)extractImageFromVideoFileWithURL:(NSURL *)url
{
    NSDictionary *opts = @{ AVURLAssetPreferPreciseDurationAndTimingKey:@(NO) };
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:url options:opts];
    return [self extractImageFromVideoFileWithAsset:asset];
}

+ (UIImage *)extractImageFromVideoFileWithPath:(NSString *)path
{
    return [self extractImageFromVideoFileWithURL:[NSURL fileURLWithPath:path]];
}

+ (NSUInteger)degressFromVideoFileWithAsset:(AVAsset *)asset
{
    NSUInteger degress = 0;
    
    NSArray *tracks = [asset tracksWithMediaType:AVMediaTypeVideo];
    if([tracks count] > 0) {
        AVAssetTrack *videoTrack = [tracks objectAtIndex:0];
        CGAffineTransform t = videoTrack.preferredTransform;
        
        if(t.a == 0 && t.b == 1.0 && t.c == -1.0 && t.d == 0){
            // Portrait
            degress = 90;
        }else if(t.a == 0 && t.b == -1.0 && t.c == 1.0 && t.d == 0){
            // PortraitUpsideDown
            degress = 270;
        }else if(t.a == 1.0 && t.b == 0 && t.c == 0 && t.d == 1.0){
            // LandscapeRight
            degress = 0;
        }else if(t.a == -1.0 && t.b == 0 && t.c == 0 && t.d == -1.0){
            // LandscapeLeft
            degress = 180;
        }
    }
    
    return degress;
}

+ (NSUInteger)degressFromVideoFileWithURL:(NSURL *)url
{
    return [self degressFromVideoFileWithAsset:[AVAsset assetWithURL:url]];
}

+ (NSUInteger)degressFromVideoFileWithPath:(NSString *)path
{
    return [self degressFromVideoFileWithURL:[NSURL URLWithString:path]];
}

+ (UIImage *)imageFromSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    // 为媒体数据设置一个CMSampleBuffer的Core Video图像缓存对象
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    // 锁定pixel buffer的基地址
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    // 得到pixel buffer的基地址
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    
    // 得到pixel buffer的行字节数
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    // 得到pixel buffer的宽和高
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    // 创建一个依赖于设备的RGB颜色空间
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    // 用抽样缓存的数据创建一个位图格式的图形上下文（graphics context）对象
    CGContextRef context = CGBitmapContextCreate(baseAddress,
                                                 width,
                                                 height,
                                                 8,
                                                 bytesPerRow,
                                                 colorSpace,
                                                 kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    // 根据这个位图context中的像素数据创建一个Quartz image对象
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    // 解锁pixel buffer
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    
    // 释放context和颜色空间
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    // 用Quartz image创建一个UIImage对象image
    UIImage *image = [UIImage imageWithCGImage:quartzImage];
    
    // 释放Quartz image对象
    CGImageRelease(quartzImage);
    
    return (image);
}

@end
