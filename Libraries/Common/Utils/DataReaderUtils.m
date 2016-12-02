//
//  DataReaderUtils.m
//  ProjectLibrary
//
//  Created by alby on 14/9/28.
//  Copyright (c) 2014年 alby. All rights reserved.
//

#import "DataReaderUtils.h"

@interface DataReaderUtils () {

}

@property (atomic, retain) NSData *buffer;

@end

@implementation DataReaderUtils

+ (DataReaderUtils *)dataWithNSData:(NSData *)data {
  return [[DataReaderUtils alloc] initWithNSData:data];
}

- (instancetype)initWithNSData:(NSData *)data {
  self = [super init];
  if (self) {
    _data = data;
    _position = 0;
  }
  return self;
}

- (void)dealloc {

}

- (const void *)bytes {
  return [_data bytes];
}

- (NSUInteger)length {
  return [_data length];
}

- (void)getBytes:(void *)bytes range:(NSRange)range {
  [_data getBytes:bytes range:range];
}

- (int64_t)getInt64 {
  int64_t i = 0;
  NSRange range;
  range.length = 8;
  range.location = _position;
  [self getBytes:(void *)&i range:range];
  _position += range.length;
  return i;
}

- (int32_t)getInt32 {
  int32_t i = 0;
  NSRange range;
  range.length = 4;
  range.location = _position;
  [self getBytes:(void *)&i range:range];
  _position += range.length;
  return CFSwapInt32HostToBig(i);
}

- (int16_t)getInt16 {
  int16_t i = 0;
  NSRange range;
  range.length = 2;
  range.location = _position;
  [self getBytes:(void *)&i range:range];
  _position += range.length;
  return CFSwapInt16HostToBig(i);
}

- (int8_t)getInt8 {
  int8_t i = 0;
  NSRange range;
  range.length = 1;
  range.location = _position;
  [self getBytes:(void *)&i range:range];
  _position += range.length;
  return i;
}

- (NSString *)getString:(NSUInteger)size {
  NSRange range;
  range.length = size;
  range.location = _position;
  char *buf = malloc(size + 1);
  [self getBytes:buf range:range];
  _position += size;
  buf[size] = 0;
  NSString *str = [NSString stringWithUTF8String:buf];
  free(buf);
  return str;
}

- (NSData *)getBytes:(NSUInteger)size {
  NSRange range;
  range.length = size;
  range.location = _position;
  char *buf = malloc(size);
  [self getBytes:buf range:range];
  _position += size;
  NSData *data = [NSData dataWithBytes:buf length:size];
  free(buf);
  return data;
}

- (void)skip:(NSInteger)p {
  _position += p;
}

- (void)reset {
  _position = 0;
}

@end
