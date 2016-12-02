//
//  NSDate+Helper.m
//  qsx
//
//  Created by alby on 15/8/11.
//  Copyright (c) 2015年 alby. All rights reserved.
//

#import "NSDate+Helper.h"
#import "DateUtils.h"

@implementation NSDate (Helper)

- (NSString *)display
{
    return [DateUtils dateDisplayWithDate:self];
}

@end
