//
//  CounterUtils.m
//  ProjectLibrary
//
//  Created by alby on 14/12/27.
//  Copyright (c) 2014年 alby. All rights reserved.
//

#import "CounterUtils.h"

@interface CounterUtils ()
{
    NSMutableDictionary *_countersImpl;
}
@end

@implementation CounterUtils

+ (instancetype)getInstance
{
    static CounterUtils *gcounter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        gcounter = [CounterUtils new];
    });
    return gcounter;
}

- (instancetype)init
{
    self = [super init];
    if (!self)
        return nil;
    
    _countersImpl = [NSMutableDictionary dictionary];
    return self;
}

- (void)add:(NSString *)name
{
    NSNumber *count = [_countersImpl objectForKey:name];
    if(!count)
        count = @(0);
    [_countersImpl setObject:@([count intValue] + 1) forKey:name];
}

- (int)get:(NSString *)name
{
    return [[_countersImpl objectForKey:name] intValue];
}

- (NSDictionary *)counters
{
    return _countersImpl;
}

@end
