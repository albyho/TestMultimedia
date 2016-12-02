//
//  FileManagerUtils.m
//  ProjectLibrary
//
//  Created by alby on 14/9/28.
//  Copyright (c) 2014年 alby. All rights reserved.
//

#import "FileManagerUtils.h"

@implementation FileManagerUtils

+ (NSString *)bundlePath:(NSString *)fileName {
    return [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:fileName];
}

+ (NSString *)documentPath:(NSString *)fileName {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    return [documentsDirectory stringByAppendingPathComponent:fileName];
}

+ (NSString *)tempPath:(NSString *)fileName
{
    return [NSTemporaryDirectory() stringByAppendingPathComponent:fileName];
}

+ (BOOL)fileExistsAtPath:(NSString *)filePath
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    return [fileManager fileExistsAtPath:filePath];
}

+ (NSArray *)filesAtPath:(NSString *)dir
{
    // dir，如：@"/System/Library/Audio/UISounds/"
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:10];
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    NSArray *tempArray = [fileMgr contentsOfDirectoryAtPath:dir error:nil];
    for (NSString *fileName in tempArray) {
        BOOL flag = YES;
        NSString *fullPath = [dir stringByAppendingPathComponent:fileName];
        if ([fileMgr fileExistsAtPath:fullPath isDirectory:&flag]) {
            if (!flag) {
                [array addObject:fullPath];
            }
        }
    }
    
    return array;
}


+ (NSString *)pathAtAppFiles:(NSString *)fileName
{
    //1、获取目录
    //获取Documents文件夹目录
    NSArray *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentPath = [path objectAtIndex:0];
    //指定新建文件夹路径
    NSString *appFiles = [documentPath stringByAppendingPathComponent:@"AppFiles"];
    
    //2、获取文件路径
    //返回保存文件的路径（文件保存在AppFiles文件夹下）
    NSString * filePath = [appFiles stringByAppendingPathComponent:fileName];
    
    //3、文件管理器（创建目录）
    //获取文件管理器
    NSFileManager *fileManager = [NSFileManager defaultManager];
    //创建AppFiles文件夹
    [fileManager createDirectoryAtPath:appFiles withIntermediateDirectories:YES attributes:nil error:nil];
    
    //DLog(@"getFilePath:%@",filePath);
    return filePath;
}

+ (BOOL)fileExistsAtAppFiles:(NSString *)fileName
{
    return [FileManagerUtils fileExistsAtPath:[FileManagerUtils pathAtAppFiles:fileName]];
}

+ (BOOL)removeFileAtAppFiles:(NSString *)fileName
{
    NSString *filePath = [FileManagerUtils pathAtAppFiles:fileName];
    return [FileManagerUtils removeFileAtPath:filePath];
}

+ (BOOL)removeFileAtPath:(NSString *)filePath
{
    //1、判断文件是否存在
    if (![FileManagerUtils fileExistsAtPath:filePath])
    {
        return NO;
    }
    
    //2、删除文件
    //创建文件管理器
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL result = [fileManager removeItemAtPath:filePath error:nil];
    return result;
}

@end
