//
//  DateUtils.m
//  qsx
//
//  Created by alby on 15/8/11.
//  Copyright (c) 2015年 alby. All rights reserved.
//

#import "DateUtils.h"
#import "DFDateFormatterFactory.h"

@implementation DateUtils

+ (NSDate *)dateWithDateTimeString:(NSString *)dateTimeString
{
    NSDateFormatter *dateTimeFormatter = [[DFDateFormatterFactory sharedFactory] dateFormatterWithFormat:@"yyyy-MM-dd HH:mm:ss" andLocaleIdentifier:@"zh-Hans"];
    return [dateTimeFormatter dateFromString:dateTimeString];
}

+ (NSDate *)dateWithDateString:(NSString *)dateString
{
    NSDateFormatter *dateTimeFormatter = [[DFDateFormatterFactory sharedFactory] dateFormatterWithFormat:@"yyyy-MM-dd" andLocaleIdentifier:@"zh-Hans"];
    return [dateTimeFormatter dateFromString:dateString];
}

+ (NSString *)dateStringWithDate:(NSDate *)date
{
    NSDateFormatter *dateTimeFormatter = [[DFDateFormatterFactory sharedFactory] dateFormatterWithFormat:@"yyyy-MM-dd HH:mm:ss" andLocaleIdentifier:@"zh-Hans"];
    
    NSString *dateTimeString = [dateTimeFormatter stringFromDate:date];
    return dateTimeString;
}

+ (NSString *)dateDisplayWithDate:(NSDate *)date
{
    NSDateFormatter *dateTimeFormatter = [[DFDateFormatterFactory sharedFactory] dateFormatterWithFormat:@"yyyy-MM-dd HH:mm:ss" andLocaleIdentifier:@"zh-Hans"];
    
    NSString *dateTimeString = [dateTimeFormatter stringFromDate:date];
    
    return [self dateDisplayWithDateTimeString:dateTimeString];
}

+ (NSString *)dateDisplayWithDateTimeString:(NSString *)dateTimeString {
    if(!dateTimeString || [dateTimeString isEqual:[NSNull null]] || dateTimeString.length == 0) return @"0000-00-00 00:00";
    
    NSDateFormatter *dateTimeFormatter = [[DFDateFormatterFactory sharedFactory] dateFormatterWithFormat:@"yyyy-MM-dd HH:mm:ss" andLocaleIdentifier:@"zh-Hans"];
    NSDateFormatter *dateFormatter = [[DFDateFormatterFactory sharedFactory] dateFormatterWithFormat:@"yyyy-MM-dd" andLocaleIdentifier:@"zh-Hans"];
    
    
    NSDate *now = [NSDate date];//[dateTimeFormatter dateFromString:@"2014-01-01 12:34:09"];
    NSString *nowString = [dateTimeFormatter stringFromDate:now]; // 2014-04-17 13:07:23
    
    NSString *todayString = [nowString substringToIndex:10];       // 2014-04-17
    NSDate *todayDate = [dateFormatter dateFromString:todayString];
    NSString *yesterdayString = [dateFormatter stringFromDate:[todayDate dateByAddingTimeInterval:-(60*60*24)]];
    NSString *theDayBeforeYesterdayString = [dateFormatter stringFromDate:[todayDate dateByAddingTimeInterval:-(60*60*24)*2]];
    //NSString *monthString = [nowString substringToIndex:7];
    NSString *yearString = [nowString substringToIndex:4];         // 2014
    
    //DLog(@"%@,%@,%@,%@,%@",todayString,yesterdayString,theDayBeforeYesterdayString,monthString,yearString);

    NSString *result = nil;
    if([[dateTimeString substringToIndex:10] isEqualToString:todayString]){
        // 今天显示： 12:34
        result = [dateTimeString substringWithRange:NSMakeRange(11,5)];
    }else if([[dateTimeString substringToIndex:10] isEqualToString:yesterdayString]){
        // 昨天显示： 昨天 12:34
        result = [NSString stringWithFormat:@"昨天 %@",[dateTimeString substringWithRange:NSMakeRange(11,5)]];
    }else if([[dateTimeString substringToIndex:10] isEqualToString:theDayBeforeYesterdayString]){
        // 前天显示： 前天 12:34
        result = [NSString stringWithFormat:@"前天 %@",[dateTimeString substringWithRange:NSMakeRange(11,5)]];
    }else if([[dateTimeString substringToIndex:4] isEqualToString:yearString]){
        // 本年(月)显示： 03-05 12:34
        result = [dateTimeString substringWithRange:NSMakeRange(5,11)];
    }else{
        // 其他显示： 2014-03-05 12:34
        result = [dateTimeString substringWithRange:NSMakeRange(2,14)];
    }
    return result;
}

+ (NSString *)dateDisplayWithDateForList:(NSDate *)date {
    
    return [self dateDisplayWithDateForList:date showTime:NO];
}

+ (NSString *)dateDisplayWithDateForList:(NSDate *)date showTime:(BOOL)showTime {
    NSDateFormatter *dateTimeFormatter = [[DFDateFormatterFactory sharedFactory] dateFormatterWithFormat:@"yyyy-MM-dd HH:mm:ss" andLocaleIdentifier:@"zh-Hans"];
    
    NSString *dateTimeString = [dateTimeFormatter stringFromDate:date];
    return [self dateDisplayWithDateTimeStringForList:dateTimeString showTime:showTime];

}

+ (NSString *)dateDisplayWithDateTimeStringForList:(NSString *)dateTimeString  {
    return [self dateDisplayWithDateTimeStringForList:dateTimeString showTime:NO];
}

+ (NSString *)dateDisplayWithDateTimeStringForList:(NSString *)dateTimeString showTime:(BOOL)showTime {
    if(!dateTimeString || [dateTimeString isEqual:[NSNull null]] || dateTimeString.length == 0) return @"0000-00-00 00:00";
    
    NSDateFormatter *dateTimeFormatter = [[DFDateFormatterFactory sharedFactory] dateFormatterWithFormat:@"yyyy-MM-dd HH:mm:ss" andLocaleIdentifier:@"zh-Hans"];
    NSDateFormatter *dateFormatter = [[DFDateFormatterFactory sharedFactory] dateFormatterWithFormat:@"yyyy-MM-dd" andLocaleIdentifier:@"zh-Hans"];
    NSArray *weeks = @[@"星期日", @"星期一", @"星期二", @"星期三", @"星期四",
                       @"星期五", @"星期六"];
    
    // 目标日期
    NSDate *dateDate = [dateFormatter dateFromString:[dateTimeString substringToIndex:10]];
    // 现在(今天)
    NSDate *now = [NSDate date];
    NSString *nowString = [dateTimeFormatter stringFromDate:now]; // 2014-04-17 13:07:23
    // 今天
    NSString *todayString = [nowString substringToIndex:10];       // 2014-04-17
    NSDate *todayDate = [dateFormatter dateFromString:todayString];
    // 昨天
    //NSString *yesterdayString = [dateFormatter stringFromDate:[todayDate dateByAddingTimeInterval:-(60*60*24)]];
    // 年
    NSString *yearString = [nowString substringToIndex:4];         // 2014
    // 时间
    NSString *timeString = [dateTimeString substringWithRange:NSMakeRange(11,5)];
    // 天数差值（因为都是取日期计算差值，故应该总是整数）
    NSUInteger dayDiff = [todayDate timeIntervalSinceDate:dateDate] / 60 / 60 / 24;
    
    NSString *result = nil;
    if (dayDiff == 0) {
        // 今天显示： 12:34
        return timeString;
    } else if(dayDiff == 1) {
        // 昨天显示： 昨天
        result = @"昨天";
    } else if(dayDiff > 1 && dayDiff < 7) {
        // 昨天的前一周，避免和本周冲突只计共5天： 星期X
        NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
        NSInteger unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSWeekdayCalendarUnit |
        NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit;
        NSDateComponents *comps = [calendar components:unitFlags fromDate:dateDate];
        NSInteger week = [comps weekday];
        //DLog(@"----- %@ %ld", dateTimeString, (long)week);
        NSString *weekString = [weeks objectAtIndex:week - 1];
        result = weekString;
    } else if([[dateTimeString substringToIndex:4] isEqualToString:yearString]) {
        // 本年(月)显示： 03-05
        NSString *currentYearOrMonthString = [dateTimeString substringWithRange:NSMakeRange(5,5)];
        result = currentYearOrMonthString;
    } else {
        // 其他显示： 2014-03-05
        NSString *otherYearString = [dateTimeString substringWithRange:NSMakeRange(2,8)];
        result = otherYearString;
    }

    result = showTime ? [NSString stringWithFormat:@"%@ %@", result, timeString] : result;

    return result;
}

+ (NSString *)todayDisplayWithDate:(NSDate *)date
{
    NSDateFormatter *dateTimeFormatter = [[DFDateFormatterFactory sharedFactory] dateFormatterWithFormat:@"yyyy-MM-dd HH:mm:ss" andLocaleIdentifier:@"zh-Hans"];
    
    NSString *dateString = [dateTimeFormatter stringFromDate:date];
    
    return [self todayDisplayWithDateTimeString:dateString];
}

+ (NSString *)todayDisplayWithDateTimeString:(NSString *)dateTimeString
{
    if(!dateTimeString || [dateTimeString isEqual:[NSNull null]] || dateTimeString.length == 0) return @"";
    
    NSDateFormatter *dateTimeFormatter = [[DFDateFormatterFactory sharedFactory] dateFormatterWithFormat:@"yyyy-MM-dd HH:mm:ss" andLocaleIdentifier:@"zh-Hans"];
    NSDate *now = [NSDate date];
    NSString *nowString = [dateTimeFormatter stringFromDate:now];
    NSString *todayString = [nowString substringToIndex:10];
    
    if ([dateTimeString hasPrefix:todayString]) {
        return [dateTimeString substringWithRange:NSMakeRange(11, 5)];
    }
    
    return @"";
}

@end
