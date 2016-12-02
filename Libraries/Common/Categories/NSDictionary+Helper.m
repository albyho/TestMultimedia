//
//  NSDictionary+Helper.m
//  eliu
//
//  Created by tanghongping on 15/2/10.
//  Copyright (c) 2015年 THP. All rights reserved.
//

#import "NSDictionary+Helper.h"

// NSString 仅有如下方法： doubleValue floatValue intValue integerValue longLongValue boolValue
// 所以 unsignedIntValue 等方法需转换成等长或更长数据再转换成需要的值
@implementation NSDictionary (Helper)

- (NSString *)stringForKey:(id)key
{
    return [self stringForKey:key defaultString:@""];
}

- (NSString *)stringForKey:(id)key defaultString:(NSString *)defaultString
{
    id obj = [self objectForKey:key];
    if ([self validateNullValue:obj]) {
        if([obj isKindOfClass:[NSString class]]) {
            NSString *string = obj;
            return string.length > 0 ? obj : defaultString;
        }else if([obj isKindOfClass:[NSNumber class]])
        {
            return [obj stringValue];
        }
    }
    return defaultString;
}

- (NSArray *)arrayForKey:(id)key
{
    id obj = [self objectForKey:key];
    if ([self validateNullValue:obj] && [obj isKindOfClass:[NSArray class]]) {
        return obj;
    }
    return [NSArray array];
}

- (NSMutableArray *)mutableArrayForKey:(id)key
{
    id obj = [self objectForKey:key];
    if ([self validateNullValue:obj] && [obj isKindOfClass:[NSMutableArray class]]) {
        return obj;
    }
    return [NSMutableArray array];
}

- (NSDictionary *)dictionaryForKey:(id)key
{
    id obj = [self objectForKey:key];
    if ([self validateNullValue:obj] && [obj isKindOfClass:[NSDictionary class]]) {
        return obj;
    }
    return [NSDictionary dictionary];
}

- (NSMutableDictionary *)mutableDictionaryForKey:(id)key
{
    id obj = [self objectForKey:key];
    if ([self validateNullValue:obj] && [obj isKindOfClass:[NSMutableDictionary class]]) {
        return obj;
    }
    return [NSMutableDictionary dictionary];
}

- (NSInteger)integerForKey:(id)key
{
    id obj = [self objectForKey:key];
    if ([self validateNullValue:obj]) {
        return [obj integerValue];
    }
    return 0;
}

- (NSUInteger)unsignedIntegerForKey:(id)key
{
    id obj = [self objectForKey:key];
    if ([self validateNullValue:obj]) {
        if([obj isKindOfClass:[NSNumber class]]) {
            return [obj unsignedIntegerValue];
        } else if([obj isKindOfClass:[NSString class]]) {
            return (NSUInteger)[obj integerValue];
        }
    }
    return 0;
}

- (char)charForKey:(id)key
{
    id obj = [self objectForKey:key];
    if ([self validateNullValue:obj]) {
        if([obj isKindOfClass:[NSNumber class]]) {
            return [obj charValue];
        } else if([obj isKindOfClass:[NSString class]]) {
            return (char)[obj intValue];
        }
    }
    return 0;
}

- (unsigned char)unsignedCharForKey:(id)key
{
    id obj = [self objectForKey:key];
    if ([self validateNullValue:obj]) {
        if([obj isKindOfClass:[NSNumber class]]) {
            return [obj unsignedCharValue];
        } else if([obj isKindOfClass:[NSString class]]) {
            return (unsigned char)[obj intValue];
        }
    }
    return 0;
}

- (short)shortForKey:(id)key
{
    id obj = [self objectForKey:key];
    if ([self validateNullValue:obj]) {
        if([obj isKindOfClass:[NSNumber class]]) {
            return [obj shortValue];
        } else if([obj isKindOfClass:[NSString class]]) {
            return (short)[obj intValue];
        }
    }
    return 0;
}

- (unsigned short)unsignedShortForKey:(id)key
{
    id obj = [self objectForKey:key];
    if ([self validateNullValue:obj]) {
        if([obj isKindOfClass:[NSNumber class]]) {
            return [obj unsignedShortValue];
        } else if([obj isKindOfClass:[NSString class]]) {
            return (unsigned short)[obj intValue];
        }
    }
    return 0;
}

- (int)intForKey:(id)key
{
    id obj = [self objectForKey:key];
    if ([self validateNullValue:obj]) {
        return [obj intValue];
    }
    return 0;
}

- (unsigned int)unsignedIntForKey:(id)key
{
    id obj = [self objectForKey:key];
    if ([self validateNullValue:obj]) {
        if([obj isKindOfClass:[NSNumber class]]) {
            return [obj unsignedIntValue];
        } else if([obj isKindOfClass:[NSString class]]) {
            return (unsigned int)[obj intValue];
        }
    }
    return 0;
}

- (long)longForKey:(id)key
{
    id obj = [self objectForKey:key];
    if ([self validateNullValue:obj]) {
        if([obj isKindOfClass:[NSNumber class]]) {
            return [obj longValue];
        } else if([obj isKindOfClass:[NSString class]]) {
            return (long)[obj longLongValue];
        }
    }
    return 0;
}

- (unsigned long)unsignedLongForKey:(id)key
{
    id obj = [self objectForKey:key];
    if ([self validateNullValue:obj]) {
        if([obj isKindOfClass:[NSString class]]) {
            return (unsigned long)[obj longLongValue];
        } else if([obj isKindOfClass:[NSNumber class]]) {
            return [obj unsignedLongValue];
        }
    }
    return 0;
}

- (long long)longLongForKey:(id)key
{
    id obj = [self objectForKey:key];
    if ([self validateNullValue:obj]) {
        return [obj longLongValue];
    }
    return 0;
}

- (unsigned long long)unsignedLongLongForKey:(id)key
{
    id obj = [self objectForKey:key];
    if ([self validateNullValue:obj]) {
        if([obj isKindOfClass:[NSString class]]) {
            return (unsigned long long)[obj longLongValue];
        } else if([obj isKindOfClass:[NSNumber class]]) {
            return [obj unsignedLongLongValue];
        }

    }
    return 0;
}


- (float)floatForKey:(id)key
{
    id obj = [self objectForKey:key];
    if ([self validateNullValue:obj]) {
        return [obj floatValue];
    }
    return 0.;
}

- (double)doubleForKey:(id)key
{
    id obj = [self objectForKey:key];
    if ([self validateNullValue:obj]) {
        return [obj doubleValue];
    }
    return 0.;
}

- (CGFloat)CGFloatForKey:(id)key
{
#if CGFLOAT_IS_DOUBLE
    return [self doubleForKey:key];
#else
    return [self floatForKey:key];
#endif
}

- (BOOL)boolForKey:(id)key
{
    id obj = [self objectForKey:key];
    if ([self validateNullValue:obj]) {
        return [obj boolValue];
    }
    return NO;
}

- (BOOL)validateNullValue:(id)obj
{
    return obj && ![obj isEqual:[NSNull null]];//&& [obj isKindOfClass:[NSNumber class]];
}

- (NSString *)descriptionWithLocale:(id)locale
{
    NSMutableString *result = [NSMutableString stringWithString:@"[\n"];
    
    [self enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [result appendFormat:@"\t%@ = %@,\n", key, obj];
    }];
    
    [result appendString:@"]"];
    
    NSRange range = [result rangeOfString:@"," options:NSBackwardsSearch];
    if (range.length != 0) {
        [result deleteCharactersInRange:range];
    }
    
    return result;
}


@end
