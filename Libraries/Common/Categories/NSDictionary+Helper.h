//
//  NSDictionary+Helper.h
//  ProjectLibrary
//
//  Created by tanghongping on 15/2/10.
//  Copyright (c) 2015年 alby. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

@interface NSDictionary (Helper)

- (NSString *)stringForKey:(id)key;
- (NSString *)stringForKey:(id)key defaultString:(NSString*)defaultString;
- (NSArray *)arrayForKey:(id)key;
- (NSMutableArray *)mutableArrayForKey:(id)key;
- (NSDictionary *)dictionaryForKey:(id)key;
- (NSMutableDictionary *)mutableDictionaryForKey:(id)key;
- (NSInteger)integerForKey:(id)key;
- (NSUInteger)unsignedIntegerForKey:(id)key;
- (char)charForKey:(id)key;
- (unsigned char)unsignedCharForKey:(id)key;
- (short)shortForKey:(id)key;
- (unsigned short)unsignedShortForKey:(id)key;
- (int)intForKey:(id)key;
- (unsigned int)unsignedIntForKey:(id)key;
- (long)longForKey:(id)key;
- (unsigned long)unsignedLongForKey:(id)key;
- (long long)longLongForKey:(id)key;
- (unsigned long long)unsignedLongLongForKey:(id)key;
- (float)floatForKey:(id)key;
- (double)doubleForKey:(id)key;
- (CGFloat)CGFloatForKey:(id)key;
- (BOOL)boolForKey:(id)key;

@end
