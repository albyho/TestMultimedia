//
//  DataReaderUtils.h
//  ProjectLibrary
//
//  Created by alby on 14/9/28.
//  Copyright (c) 2014年 alby. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DataReaderUtils : NSObject

+ (DataReaderUtils *)dataWithNSData:(NSData *)data;

- (int8_t)getInt8;
- (int16_t)getInt16;
- (int32_t)getInt32;
- (int64_t)getInt64;
- (NSData *)getBytes:(NSUInteger)size;
- (NSString *)getString:(NSUInteger)size;
- (void)skip:(NSInteger)pos;
- (void)reset;
- (const void *)bytes;
- (NSUInteger)length;

@property (nonatomic, readonly) NSUInteger  position;
@property (nonatomic, readonly) NSData      *data;

@end
