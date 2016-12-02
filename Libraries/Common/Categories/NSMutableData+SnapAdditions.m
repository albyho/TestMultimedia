//
//  NSMutableData+SnapAdditions.m
//  ProjectLibrary
//
//  Created by alby on 14-4-13.
//  Copyright (c) 2014年 ho alby. All rights reserved.
//

#import "NSMutableData+SnapAdditions.h"

@implementation NSData (SnapAdditions)

@end

@implementation NSMutableData (SnapAdditions)

- (void)rw_appendInt64:(int64_t)value
{
    //value = htonl(value);
    [self appendBytes:&value length:8];
}

- (void)rw_appendInt32:(int32_t)value
{
    //value = htonl(value);
    [self appendBytes:&value length:4];
}

- (void)rw_appendInt16:(int16_t)value
{
    //value = htons(value);
    [self appendBytes:&value length:2];
}

- (void)rw_appendInt8:(int8_t)value
{
    [self appendBytes:&value length:1];
}

- (void)rw_appendString:(NSString *)string
{
    if(!string||[string length]==0) return;
    const char *cString = [string UTF8String];
    [self appendBytes:cString length:strlen(cString)];
}

- (void)rw_appendStringWithLength32:(NSString *)string
{
    int len = 0;
    if(!string||[string length]==0){
        [self rw_appendInt32:len];
        return;
    }
    const char *cString = [string UTF8String];
    len = (uint32_t)strlen(cString);
    [self rw_appendInt32:len];
    [self appendBytes:cString length:len];
}

- (void)rw_appendStringWithLength16:(NSString *)string
{
    int len = 0;
    if(!string||[string length]==0){
        [self rw_appendInt32:len];
        return;
    }
    const char *cString = [string UTF8String];
    len = (uint16_t)strlen(cString);
    [self rw_appendInt16:len];
    [self appendBytes:cString length:len];
}

- (void)rw_appendDataWithLength32:(NSData *)data
{
    int len = 0;
    if(!data||[data length]==0){
        [self rw_appendInt32:len];
        return;
    }
    [self rw_appendInt32:(int)[data length]];
    [self appendData:data];
}


@end
