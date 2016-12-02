//
//  ProjectUtils.h
//  ProjectLibrary
//
//  Created by alby on 14/9/28.
//  Copyright (c) 2014年 alby. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMotion/CoreMotion.h>

#ifndef Project_ProjectUtils_h
#define Project_ProjectUtils_h

// Weak Self
#define WS(weakSelf) __weak __typeof(&*self)weakSelf = self;

// AppDelegate
#define APPDELEGATE [(AppDelegate *)[UIApplication sharedApplication] delegate]

//----------------------系统设备相关-------------------------
// 判断是真机还是模拟器；判断是否是模拟器最好是使用TARGET_OS_SIMULATOR，除非需要更详细知道是才使用TARGET_OS_IPHONE/IOS/WATCH/TV等
#if TARGET_OS_SIMULATOR
// iPhone Simulator
#endif

// 获取设备屏幕尺寸
#define ScreenWidth     MIN([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)
#define ScreenHeight    MAX([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)
#define AppWidth        [[UIScreen mainScreen] applicationFrame].size.width
#define AppHeight       [[UIScreen mainScreen] applicationFrame].size.height
#define AppVersion      [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]
#define AppID           [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"]

#define ScreenWidth1 (IOS_VERSION_LOWER_THAN_8 ? (UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation) ? [[UIScreen mainScreen] bounds].size.width : [[UIScreen mainScreen] bounds].size.height) : [[UIScreen mainScreen] bounds].size.width)
#define ScreenHeight1 (IOS_VERSION_LOWER_THAN_8 ? (UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation) ? [[UIScreen mainScreen] bounds].size.height : [[UIScreen mainScreen] bounds].size.width) : [[UIScreen mainScreen] bounds].size.height)
#define IOS_VERSION_LOWER_THAN_8 (NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_7_1)

// 获取系统版本
// __IPHONE_OS_VERSION_MAX_ALLOWED
#define SystemVersion   [[[UIDevice currentDevice] systemVersion] doubleValue]
#define IsiOS6          ([[[UIDevice currentDevice] systemVersion] intValue] == 6)
#define IsiOS7          ([[[UIDevice currentDevice] systemVersion] intValue] == 7)
#define IsiOS8          ([[[UIDevice currentDevice] systemVersion] intValue] == 8)
#define IsiOS9          ([[[UIDevice currentDevice] systemVersion] intValue] == 9)
#define IsiOS10         ([[[UIDevice currentDevice] systemVersion] intValue] == 10)
#define IsAfteriOS6     ([[[UIDevice currentDevice] systemVersion] intValue] > 6)
#define IsAfteriOS7     ([[[UIDevice currentDevice] systemVersion] intValue] > 7)
#define IsAfteriOS8     ([[[UIDevice currentDevice] systemVersion] intValue] > 8)
#define IsAfteriOS9     ([[[UIDevice currentDevice] systemVersion] intValue] > 9)
#define IsAfteriOS10    ([[[UIDevice currentDevice] systemVersion] intValue] > 10)
#define IsBeforeiOS6    ([[[UIDevice currentDevice] systemVersion] intValue] < 6)
#define IsBeforeiOS7    ([[[UIDevice currentDevice] systemVersion] intValue] < 7)
#define IsBeforeiOS8    ([[[UIDevice currentDevice] systemVersion] intValue] < 8)
#define IsBeforeiOS9    ([[[UIDevice currentDevice] systemVersion] intValue] < 9)
#define IsBeforeiOS10   ([[[UIDevice currentDevice] systemVersion] intValue] < 10)

// 获取当前语言
#define CurrentLanguage ([[NSLocale preferredLanguages] objectAtIndex:0])

// 判断iPhone/iPad
#define IsPhone         (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
#define IsPad           (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
#define IsiPhone4 ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(640, 960), [[UIScreen mainScreen] currentMode].size) : NO)
#define IsiPhone5 ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(640, 1136), [[UIScreen mainScreen] currentMode].size) : NO)
#define IsiPhone6 ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(750, 1334), [[UIScreen mainScreen] currentMode].size) : NO)
#define IsiPhone6Plus ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(1242, 2208), [[UIScreen mainScreen] currentMode].size) : NO)

//----------------------内存相关----------------------------
// 使用ARC和不使用ARC
#if __has_feature(objc_arc)
// compiling with ARC
#else
// compiling without ARC
#endif
// 释放一个对象
#define SafeDelete(P)   if(P) { [P release], P = nil; }
#define SafeRelease(x)  [x release]; x = nil;

//----------------------图片相关----------------------------
// 读取本地图片
// 定义UIImage对象
#define LoadImage(file,ext)     [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:file ofType:ext]]
// 定义UIImage对象
#define Image(A)                [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:A ofType:nil]]
// 定义UIImage对象
#define ImageNamed(_pointer)    [UIImage imageNamed:_pointer]
// 可拉伸的图片
#define ResizableImage(name,top,left,bottom,right) [[UIImage imageNamed:name] resizableImageWithCapInsets:UIEdgeInsetsMake(top,left,bottom,right)]
#define ResizableImageWithMode(name,top,left,bottom,right,mode) [[UIImage imageNamed:name] resizableImageWithCapInsets:UIEdgeInsetsMake(top,left,bottom,right) resizingMode:mode]

//----------------------视图相关----------------------------
// 设置需要粘贴的文字或图片
#define PasteString(string)         [[UIPasteboard generalPasteboard] setString:string];
#define PasteImage(image)           [[UIPasteboard generalPasteboard] setImage:image];

// 得到frame的left top的X,Y坐标点
#define FrameTopLeft(frame)         (frame.origin)
#define FrameTopLeftX(frame)        (frame.origin.x)
#define FrameTopLeftY(frame)        (frame.origin.y)

// 得到frame的right bottom的X,Y坐标点
#define FrameBottomRight(frame)     CGPointMake(frame.origin.x + frame.size.width,frame.origin.y + frame.size.height)
#define FrameBottomRightX(frame)    (frame.origin.x + frame.size.width)
#define FrameBottomRightY(frame)    (frame.origin.y + frame.size.height)

// 得到frame的宽度、高度
#define FrameWidth(frame)           (frame.size.width)
#define FrameHeight(frame)          (frame.size.height)

//----------------------打印日志----------------------------
// Debug模式下打印日志,当前行,函数名

#define __FUNCTION_FILE_LINE__ [NSString stringWithFormat:@"%s[%@:%d]", __PRETTY_FUNCTION__, [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__]
#define __FUNCTION_LINE__ [NSString stringWithFormat:@"%s[%d]", __PRETTY_FUNCTION__, __LINE__]
#define __FILE_LINE__ [NSString stringWithFormat:@"%@:%d", [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__]

#if DEBUG
//#define DLog(format, ...) fprintf(stderr,"\nF:%s L:%d C:%s\n", __PRETTY_FUNCTION__, __LINE__, [[NSString stringWithFormat:format, ##__VA_ARGS__] UTF8String]);
//#define  WDLog(format, ...)  { UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"%s\n [Line %d] ", __PRETTY_FUNCTION__, __LINE__] message:[NSString stringWithFormat:format, ##__VA_ARGS__]  delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil]; [alert show]; }
#define DLog(format, ...) NSLog(format, ## __VA_ARGS__)

#else

//#define DLog(format, ...)
//#define WDLog(format, ...)
#define DLog(format, ...)
//#define NSLog(format, ...) nil

#endif

// 打印Frame
#define DLogRect(frame)  DLog(@"%@ Frame[X=%.1f, Y=%.1f, W=%.1f, H=%.1f]", __FUNCTION_FILE_LINE__, frame.origin.x, frame.origin.y, frame.size.width, frame.size.height)
// 打印Point
#define DLogPoint(point) DLog(@"%@ Point[X=%.1f, Y=%.1f]", __FUNCTION_FILE_LINE__, point.x, point.y)
// 打印Size
#define DLogSize(size)   DLog(@"%@ Size[W=%.1f, H=%.1f]", __FUNCTION_FILE_LINE__, size.width, size.height)

//----------------------其他-------------------------------
// 方正黑体简体字体定义
#define Font(F) [UIFont fontWithName:@"FZHTJW--GB1-0" size:F]
// File
// 读取文件的文本内容,默认编码为UTF-8
#define FileString(name,ext)            [[NSString alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:(name) ofType:(ext)] encoding:NSUTF8StringEncoding error:nil]
#define FileDictionary(name,ext)        [[NSDictionary alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:(name) ofType:(ext)]]
#define FileArray(name,ext)             [[NSArray alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:(name) ofType:(ext)]]
// GCD
#define RunBack(block) dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), block)
#define RunMain(block) dispatch_async(dispatch_get_main_queue(),block)
// Alert
#define Alert(tit,msg) [[[UIAlertView alloc] initWithTitle:tit message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show]

// 由角度获取弧度
#define DegreesToRadian(x) (M_PI * (x) / 180.0)
// 由弧度获取角度
#define RadianToDegrees(radian) ((radian * 180.0) / M_PI)

#endif

// 屏幕尺寸的枚举类型
typedef NS_ENUM(NSUInteger, ScreenSizeType) {
    iPhone4Size,    // 480
    iPhone5Size,    // 568
    iPhone6Size,    // 667
    iPhone6pSize,   // 736
};

void runSynchronouslyOnQueue(dispatch_queue_t queue, const void *key, void (^block)(void));
void runAsynchronouslyOnQueue(dispatch_queue_t queue, const void *key, void (^block)(void));

@interface ProjectUtils : NSObject

+ (NSString*)hardwareType;
// URL编码
+ (NSString *)encodeToPercentEscapeString:(NSString *)input;
// URL解码
+ (NSString *)decodeFromPercentEscapeString:(NSString *)input;
//+ (ScreenSizeType)getScreenSizeType;
+ (BOOL)accelerationIsShaked:(CMAcceleration)first
                      second:(CMAcceleration)second
                   threshold:(double)threshold;
+ (NSString *)uuid;

@end
