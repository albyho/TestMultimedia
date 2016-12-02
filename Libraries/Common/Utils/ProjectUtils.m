//
//  ProjectUtils.m
//  ProjectLibrary
//
//  Created by alby on 14/9/28.
//  Copyright (c) 2014年 alby. All rights reserved.
//

#import "ProjectUtils.h"
#import <UIKit/UIKit.h>
#import <sys/utsname.h>
#import <AdSupport/AdSupport.h>


void runSynchronouslyOnQueue(dispatch_queue_t queue, const void *key, void (^block)(void))
{
#if !OS_OBJECT_USE_OBJC
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    if (dispatch_get_current_queue() == queue)
#pragma clang diagnostic pop
#else
        if (dispatch_get_specific(key))
#endif
        {
            block();
        }else
        {
            dispatch_sync(queue, block);
        }
}

void runAsynchronouslyOnQueue(dispatch_queue_t queue, const void *key, void (^block)(void))
{
#if !OS_OBJECT_USE_OBJC
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    if (dispatch_get_current_queue() == queue)
#pragma clang diagnostic pop
#else
        if (dispatch_get_specific(key))
#endif
        {
            block();
        }else
        {
            dispatch_async(queue, block);
        }
}

@implementation ProjectUtils

// @see: http://theiphonewiki.com/wiki/Models
+ (NSString *)hardwareType
{
    // 需要#import "sys/utsname.h"
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *identifier = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    
    //DLog(@"%@",deviceString);
    NSDictionary *model = @{
                            @"i386":@"iPhone Simulator",
                            @"x86_64":@"iPhone Simulator",
                            
                            // Apple Watch
                            @"Watch1,1":@"Apple Watch (A1553)",
                            @"Watch1,2":@"Apple Watch (A1554/A1638)",
                            
                            // Apple TV
                            @"AppleTV2,1":@"Apple TV 2G (A1378)",
                            @"AppleTV3,1":@"Apple TV 2G (A1427)",
                            @"AppleTV3,2":@"Apple TV 2G (A1469)",
                            
                            // iPhone
                            @"iPhone1,1":@"iPhone (A1203)",
                            @"iPhone1,2":@"iPhone 3G (A1241/A1324)",
                            @"iPhone2,1":@"iPhone 3GS (A1303/A1325)",
                            @"iPhone3,1":@"iPhone 4 (A1332)",
                            @"iPhone3,2":@"iPhone 4 (A1332)",//注，和iPhone3,1一样
                            @"iPhone3,3":@"iPhone 4 (A1349)",
                            @"iPhone4,1":@"iPhone 4s (A1387/A1431)",
                            @"iPhone5,1":@"iPhone 5 (A1428)",
                            @"iPhone5,2":@"iPhone 5 (A1429/A1442)",
                            @"iPhone5,3":@"iPhone 5c (A1456/A1532)",
                            @"iPhone5,4":@"iPhone 5c (A1507/A1516/A1526/A1529)",
                            @"iPhone6,1":@"iPhone 5s (A1453/A1533)",
                            @"iPhone6,2":@"iPhone 5s (A1457/A1518/A1528/A1530)",
                            @"iPhone7,2":@"iPhone 6 (A1549/A1586)",//注，iPhone6是iPhone7,2，iPhone6+是iPhone7,1
                            @"iPhone7,1":@"iPhone 6+ (A1522/A1524)",
                            
                            // iPod
                            @"iPod1,1":@"iPod touch (A1213)",
                            @"iPod2,1":@"iPod touch 2G (A1288)",
                            @"iPod3,1":@"iPod touch 3G (A1318)",
                            @"iPod4,1":@"iPod touch 4G (A1367)",
                            @"iPod5,1":@"iPod touch 5G (1421/A1509)",
                            
                            // iPad
                            @"iPad1,1":@"iPad (A1219/A1337)",
                            @"iPad2,1":@"iPad 2 (A1395)",
                            @"iPad2,2":@"iPad 2 (A1396)",
                            @"iPad2,3":@"iPad 2 (A1397)",
                            @"iPad2,4":@"iPad 2 (A1395)",
                            @"iPad2,5":@"iPad mini (A1432)",
                            @"iPad2,6":@"iPad mini (A1454)",
                            @"iPad2,7":@"iPad mini (A1455)",
                            @"iPad3,1":@"iPad 3 (A1416)",
                            @"iPad3,2":@"iPad 3 (A1403)",
                            @"iPad3,3":@"iPad 3 (A1430)",
                            @"iPad3,4":@"iPad 4 (A1458)",
                            @"iPad3,5":@"iPad 4 (A1459)",
                            @"iPad3,6":@"iPad 4 (A1460)",
                            @"iPad4,1":@"iPad Air (A1474)",
                            @"iPad4,2":@"iPad Air (A1475)",
                            @"iPad4,3":@"iPad Air (A1476)",
                            @"iPad4,4":@"iPad mimi 2 (A1489)",
                            @"iPad4,5":@"iPad mimi 2 (A1490)",
                            @"iPad4,6":@"iPad mimi 2 (A1491)",
                            @"iPad4,7":@"iPad mimi 3 (A1599)",
                            @"iPad4,8":@"iPad mimi 3 (A1600)",
                            @"iPad4,9":@"iPad mimi 3 (A1601)",
                            @"iPad5,3":@"iPad Air (A1566)",// 注，无iPad5,1和iPad5,2
                            @"iPad5,4":@"iPad Air (A1567)",
                            
                            };
    
    NSString *result = [model objectForKey:identifier];
    
    return result?:identifier;
    
}

+ (NSString *)encodeToPercentEscapeString:(NSString *)input
{
    // Encode all the reserved characters, per RFC 3986
    // (<http://www.ietf.org/rfc/rfc3986.txt>)
    
    /*
     
     使用 CFBridgingRelease()等价于__bridge_trasfer,从 Core Foundation 传递所有权给 Objective-C;
     使用 CFBridgingRetain()等价于__bridge_retained,从 Objective-C 传递所有权给 Core Foundation;
     使用 __bridge,表示临时使用某种类型,不改变对象的所有权。
     
     */
    
    // (CFStringRef)input 等价于【CFBridgingRetain(input)或(__bridge_retained CFStringRef)input】,表示赋予CF所有权同时接触OC所有权
    // (CFStringRef)@"!*'();:@&=+$,/?%#[]" 大致等价于 【CFStr("!*'();:@&=+$,/?%#[]")】
    /*
     NSString *outputStr = CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
     (__bridge CFStringRef)input,
     NULL,
     CFSTR("!*'();:@&=+$,/?%#[]"),
     kCFStringEncodingUTF8));
     //*/
    /*
     static NSString * const kAFCharactersToBeEscapedInQueryString = @":/?&=;+!@#$()',*";
     
     NSString *outputStr	= (__bridge_transfer  NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
     (__bridge CFStringRef)input,
     NULL,
     (__bridge CFStringRef)kAFCharactersToBeEscapedInQueryString,
     kCFStringEncodingUTF8);
     //*/
    /*
     NSString *outputStr = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
     (CFStringRef)input,
     NULL,
     (CFStringRef)@"!*'();:@&=+$,/?%#[]",
     kCFStringEncodingUTF8));
     //*/
    NSString *outputStr = CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                                    (CFStringRef)input,
                                                                                    NULL,
                                                                                    (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                                    kCFStringEncodingUTF8));
    
    return outputStr;
}

+ (NSString *)decodeFromPercentEscapeString:(NSString *)input
{
    NSMutableString *outputStr = [NSMutableString stringWithString:input];
    [outputStr replaceOccurrencesOfString:@"+"
                               withString:@" "
                                  options:NSLiteralSearch
                                    range:NSMakeRange(0, [outputStr length])];
    
    return [outputStr stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

+ (BOOL)accelerationIsShaked:(CMAcceleration)first
                      second:(CMAcceleration)second
                   threshold:(double)threshold;
{
    double
    deltaX = fabs(first.x - second.x),
    deltaY = fabs(first.y - second.y),
    deltaZ = fabs(first.z - second.z);
    
    return
    (deltaX > threshold && deltaY > threshold) ||
    (deltaX > threshold && deltaZ > threshold) ||
    (deltaY > threshold && deltaZ > threshold);
}

+ (NSString *)uuid
{
    return @"uuid";
    //NSString *uuid = [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
    //return uuid;
}

/*
 + (NSInteger)systemMajorVersion{
 static NSInteger _deviceSystemMajorVersion = -1;
 static dispatch_once_t onceToken;
 dispatch_once(&onceToken, ^{
 _deviceSystemMajorVersion = [[[[[UIDevice currentDevice] systemVersion]
 componentsSeparatedByString:@"."] objectAtIndex:0] intValue];
 });
 return _deviceSystemMajorVersion;
 }
 */

/*
 + (ScreenSizeType)getScreenSizeType
 {
 if (kScreenBounds.size.height == 736) {
 return iPhone6pSize;
 } else if (kScreenBounds.size.height == 667) {
 return iPhone6Size;
 } else if (kScreenBounds.size.height == 568) {
 return iPhone5Size;
 }
 UITextField
 return iPhone4Size;
 }
 */

@end
