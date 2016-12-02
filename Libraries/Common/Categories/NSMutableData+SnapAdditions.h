//
//  NSMutableData+SnapAdditions.h
//  ProjectLibrary
//
//  Created by alby on 14-4-13.
//  Copyright (c) 2014年 ho alby. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (SnapAdditions)

@end

@interface NSMutableData (SnapAdditions)

- (void)rw_appendInt64:(int64_t)value;
- (void)rw_appendInt32:(int32_t)value;
- (void)rw_appendInt16:(int16_t)value;
- (void)rw_appendInt8:(int8_t)value;
- (void)rw_appendString:(NSString *)string;
- (void)rw_appendStringWithLength32:(NSString *)string;
- (void)rw_appendStringWithLength16:(NSString *)string;
- (void)rw_appendDataWithLength32:(NSData *)data;

@end