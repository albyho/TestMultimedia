//
//  NSArray+Helper.m
//  ProjectLibrary
//
//  Created by alby on 15/11/18.
//  Copyright © 2015年 alby. All rights reserved.
//

#import "NSArray+Helper.h"

@implementation NSArray (Helper)

- (NSString *)descriptionWithLocale:(id)locale {
    NSMutableString *result = [NSMutableString stringWithString:@"[\n"];
    
    NSUInteger count = self.count;
    [self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if(idx < count - 1) {
            [result appendFormat:@"\t%@,\n", obj];
        } else {
            [result appendFormat:@"\t%@\n", obj];
        }
    }];
    
    [result appendString:@"]"];
    
    return result;
}

@end
