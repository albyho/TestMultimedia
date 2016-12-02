//
//  TBMDefines.h
//  ProjectLibrary
//
//  Created by ho alby on 13-10-24.
//  Copyright (c) 2013年 ho alby. All rights reserved.
//

#ifndef Project_TBMDefines_h
#define Project_TBMDefines_h

//FFmpegVideoEncoder HWVideoEncoder VTVideoEncoder (FFmpegVideoEncoder 尚未实现encodePixelBuffer方法)
#define kTBMVideoEncoder                 HWVideoEncoder
#define kTBMRecorderProjectLibrary       1
#define kTBMPlayerProjectLibrary         1

// 帧类型(备注：无B帧)
typedef NS_ENUM(uint8_t/*1字节*/, TBMFrameType)
{
    TBMFrameTypeEnd                      = 0,    // 结束帧
    TBMFrameTypeAudio                    = 8,    // 音频帧
    TBMFrameTypeVideoP                   = 9,    // 视频P帧
    TBMFrameTypeVideoI                   = 10,   // 视频I帧
    TBMFrameTypeRotation                 = 11,   // 旋转帧
    TBMFrameTypeBlack                    = 12,   // 黑屏帧
    TBMFrameTypeSeek                     = 13,   // S->C Seek确认帧(直播回放)
    TBMFrameTypeCheck                    = 21,   // C->S Check帧(直播上传)
    TBMFrameTypeNull                     = 99    // 空帧
};

// 监控视频命令错误码(备注：内部使用)
typedef NS_ENUM(NSUInteger, TBMVideoPacketError)
{
    TBMVideoPacketErrorNone              = 0,    // 无错误
    TBMVideoPacketErrorCommandFlag       = 1,    // 包头错误
    TBMVideoPacketErrorCommandLength     = 2,    // 命令长度错误
    TBMVideoPacketErrorCommand           = 3,    // 命令错误
    TBMVideoPacketErrorResult            = 4     // 命令返回值错误
};

// 监控视频云台控制指令
typedef NS_ENUM(NSUInteger, TBMVideoPTZCode)
{
    TBMVideoPTZCodeZoomIn                = 111,   // 放大
    TBMVideoPTZCodeZoomOut               = 110,   // 缩小
    TBMVideoPTZCodeUp                    = 100,   // 上
    TBMVideoPTZCodeDown                  = 102,   // 下
    TBMVideoPTZCodeLeft                  = 104,   // 左
    TBMVideoPTZCodeRight                 = 106    // 右
};

#pragma pack(1)

#define COMMANDHEADER           \
uint32_t    commandFlag;        \
uint32_t    commandLength;      \
uint32_t    command;            \

// 视频包头，25字节（实时视频、本地回放、云端回放都相同）
typedef struct
{
    COMMANDHEADER
    uint32_t    result;
    uint16_t    videoWidth;
    uint16_t    videoHeight;
    uint8_t     hasAudio;
    uint8_t     frameRate;
    uint8_t     reserve[3];
} TBMVideoPacketHeader;

// 实时视频和本地回放帧头
typedef struct
{
    uint8_t     frameType;
    uint32_t    frameLength;
} TBMVideoFrameHeader;

// 云存储帧头
typedef struct
{
    uint8_t     frameType;
    uint32_t    frameLength;
    uint8_t     reserve[18];
} TBMCloudVideoFrameHeader;

// 报警视频包头，26字节
typedef struct
{
    COMMANDHEADER
    uint16_t    videoWidth;
    uint16_t    videoHeight;
    uint8_t     hasAudio;
    uint8_t     frameRate;
    uint16_t    frameCount;
    uint8_t     reserve[18];
} TBMVideocommandFlagAlarm;

// 回放日期列表包头，21字节
typedef struct
{
    COMMANDHEADER
    uint32_t    result;
    uint32_t    deviceID;
    uint8_t     channelPort;
} TBMVideoDateListcommandFlag;

// 回放录像列表，31字节
typedef struct
{
    COMMANDHEADER
    uint32_t    result;
    uint32_t    deviceID;
    uint8_t     channelPort;
    uint8_t     reserve[10];
} TBMVideoListcommandFlag;

// 回放视频包头，25字节
typedef struct
{
    COMMANDHEADER
    uint32_t    result;
    uint16_t    videoWidth;
    uint16_t    videoHeight;
    uint8_t     hasAudio;
    uint8_t     frameRate;
    uint8_t     reserve[3];
} TBMVideocommandFlagReplay;

#pragma pack()

#endif
