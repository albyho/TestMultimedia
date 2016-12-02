//
//  HexUtils.m
//  Project
//
//  Created by alby on 14-2-18.
//  Copyright (c) 2014年 ho alby. All rights reserved.
//

#import "HexUtils.h"

@implementation HexUtils

+ (Byte)numFromChar:(char) c
{
    
    if ( c >='0' && c <= '9')
    {
        return c - '0';
    }
    else if (c >='A' && c <='Z')
    {
        return c - 'A' + 10;
    }
    else if (c >='a' && c <= 'z')
    {
        return c - 'a' + 10;
    }
    
    return -1;
}

+ (NSData * )dataFromHexString :(NSString *)s_t
{
    // 4F60 597D
    // 0100 1111
    
    s_t = [s_t stringByReplacingOccurrencesOfString:@" "  withString:@""];
    if ([s_t length]%2 !=0)
    {
        return nil;
    }
    
    Byte * retBytes = malloc(sizeof(Byte) * [s_t length]);
    Byte * ori = retBytes;
    
    for ( int i = 0 ; i < [s_t length]; )
    {
        
        char highBit = [s_t characterAtIndex:i ++];
        char lowBit = [s_t characterAtIndex:i ++];
        
        //to byte
        Byte a = [HexUtils numFromChar:highBit];
        Byte b = [HexUtils numFromChar:lowBit];
        
        *(retBytes ++)= (a<<4) | b;
    }
    
    NSData * data = [NSData dataWithBytes:ori length:[s_t length]/2];
    free(ori);
    ori = NULL;
    retBytes = NULL;
    return data;
    
}

+ (NSString * )stringFromByte:(Byte )byteVal
{
    NSMutableString *str = [NSMutableString string];
    Byte byte1 = byteVal >> 4;
    Byte byte2 = byteVal & 0xf;
    [str appendFormat:@"%x" , byte1];
    [str appendFormat:@"%x" , byte2];
    
    return str;
}

//0000 0000 0000 0000
+ (NSString *)stringFromShort :(short)shortVal
{
    
    NSMutableString *str = [NSMutableString string];
    
    [str appendFormat:@"%x" , shortVal >> 12];
    [str appendFormat:@"%x" , (shortVal >> 8 ) & 0xf];
    [str appendFormat:@"%x" , (shortVal >> 4 ) & 0xf];
    [str appendFormat:@"%x" , shortVal &0xf];
    
    return str;
    
}

+ (NSString * )hexStringfromData:(NSData * )data
{
    NSMutableString * str = [NSMutableString string];
    Byte * byte = (Byte *)[data bytes];
    
    for ( int i = 0 ;i < [data length] ;i ++)
    {
        [str appendString:[self stringFromByte: *(byte + i)]];
    }
    
    return str;
}

@end

