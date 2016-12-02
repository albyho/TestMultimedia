//
//  TBMParams.h
//  ProjectLibrary
//
//  Created by alby on 15/4/27.
//  Copyright (c) 2015年 alby. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#pragma mark - 公共
@interface Server : NSObject
@property (nonatomic, copy)     NSString *host;
@property (nonatomic)           uint16_t port;
@end

@interface ServerWithToken : Server
@property (nonatomic, copy)     NSString *token;
@end

#pragma mark - 直播
@interface LiveParams : NSObject
@property (nonatomic)           ServerWithToken *schedulingServer;
@property (nonatomic)           NSUInteger netType;
@property (nonatomic)           NSUInteger liveID;
@property (nonatomic)           NSUInteger bitrate;
@end

#pragma mark - 直播播放
@interface LivePlayParams : LiveParams
@end


#pragma mark - 直播回放
@interface LiveReplayParams : NSObject
@property (nonatomic)           ServerWithToken *replayServer;
@property (nonatomic)           NSUInteger netType;
@property (nonatomic)           NSUInteger videoID;
@end

#pragma mark - 监控
@interface CameraChannel : NSObject

// 仅一个字段，方便以后扩展
@property (nonatomic)     NSUInteger channelPort;

@end

@interface CameraDevice : NSObject

@property (nonatomic)           Server *mediaServer;
@property (nonatomic)           NSUInteger deviceID;
// 播放器内部将code和aCode拼接成token
@property (nonatomic, copy)     NSString *code;
@property (nonatomic, copy)     NSString *aCode;
// 到期时间仅为了播放器验证，服务器还会从其他途径验证
@property (nonatomic, copy)     NSString *expirationTime;
// 仅支持单通道播放
//@property (nonatomic, copy)     NSArray<CameraChannel *> *channels;
@property (nonatomic)           CameraChannel *channel;

@end

@interface CameraParams : NSObject

@property (nonatomic)           CameraDevice *device;

@end

#pragma mark - 监控回放
@interface CameraReplayParams : CameraParams

//beginTime和endTime格式：yyyyMMddHHmmss
@property (nonatomic, copy)     NSString *beginTime;
@property (nonatomic, copy)     NSString *endTime;

@end

#pragma mark - 视频水印
@interface CameraMask : NSObject

@property (nonatomic)           UIImage *logo;      // logo和text同时有值才会显示水印
@property (nonatomic, copy)     NSString *text;     // 格式：名称•学校。默认选第一所学校。如，@"刘老师•成都记上学科技有限公司幼儿园"

@end




