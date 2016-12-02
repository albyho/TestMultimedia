//
//  DateUtils.h
//  qsx
//
//  Created by alby on 15/8/11.
//  Copyright (c) 2015年 alby. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DateUtils : NSObject

// 1.
// yyyy-MM-dd HH:mm:ss  NSString 转 NSDate
+ (NSDate *)dateWithDateTimeString:(NSString *)dateTimeString;
// yyyy-MM-dd           NSString 转 NSDate
+ (NSDate *)dateWithDateString:(NSString *)dateString;
// yyyy-MM-dd HH:mm:ss  NSDate 转 NSString
+ (NSString *)dateStringWithDate:(NSDate *)date;

// 2.
// yyyy-MM-dd           NSDate 转 NSString
+ (NSString *)dateDisplayWithDate:(NSDate *)date;
// yyyy-MM-dd HH:mm:ss  NSString 转 NSString 假设了目标日期比现在早
// 转换规则：
// 今天显示： 12:34
// 昨天显示： 昨天 12:34
// 前天显示： 前天 12:34
// 本年(月)显示： 03-05 12:34
// 其他显示： 2014-03-05 12:34
+ (NSString *)dateDisplayWithDateTimeString:(NSString *)dateTimeString;
// 3.
// yyyy-MM-dd           NSDate 转 NSString
+ (NSString *)dateDisplayWithDateForList:(NSDate *)date;
+ (NSString *)dateDisplayWithDateForList:(NSDate *)date showTime:(BOOL)showTime;
// yyyy-MM-dd HH:mm:ss  NSString 转 NSString 假设了目标日期比现在早
// 今天显示： 12:34
// 昨天显示： 昨天
// 昨天的前一周，避免和本周冲突只计共5天： 星期X
// 本年(月)显示： 03-05
// 其他显示： 2014-03-05
+ (NSString *)dateDisplayWithDateTimeStringForList:(NSString *)dateTimeString;
// yyyy-MM-dd HH:mm:ss  NSString 转 NSString 假设了目标日期比现在早
// showTime: 对于非今天的日期显示时间(今天本来就只显示了时间)
+ (NSString *)dateDisplayWithDateTimeStringForList:(NSString *)dateTimeString showTime:(BOOL)showTime;

// 4.
// 今天 NSDate 转 NSString 非今天返回@""
+ (NSString *)todayDisplayWithDate:(NSDate *)date;
// 今天 NSString 转 NSString 非今天返回@""
+ (NSString *)todayDisplayWithDateTimeString:(NSString *)dateTimeString;

@end
