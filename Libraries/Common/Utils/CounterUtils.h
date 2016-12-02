//
//  CounterUtils.h
//  ProjectLibrary
//
//  Created by alby on 14/12/27.
//  Copyright (c) 2014年 alby. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CounterUtils : NSObject

@property (nonatomic,readonly) NSDictionary *counters;

+ (instancetype)getInstance;
- (void)add:(NSString *)name;
- (int)get:(NSString *)name;

@end
