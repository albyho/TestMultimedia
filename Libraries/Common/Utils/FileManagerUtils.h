//
//  FileManagerUtils.h
//  ProjectLibrary
//
//  Created by alby on 14/9/28.
//  Copyright (c) 2014年 alby. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FileManagerUtils : NSObject

// 通过文件名获取文件在主包中的路径
+ (NSString *)bundlePath:(NSString *)fileName;
// 通过文件名获取文件在文档目录的路径
+ (NSString *)documentPath:(NSString *)fileName;
// 通过文件名获取文件在临时目录的路径
+ (NSString *)tempPath:(NSString *)fileName;

// 路径对应的文件是否存在
+ (BOOL)fileExistsAtPath:(NSString *)filePath;
// 获取某个目录下的所有文件的文件名
+ (NSArray *)filesAtPath:(NSString *)dir;
// 通过文件名获取文件在AppFiles目录的路径(AppFiles位于文档目录下)
+ (NSString *)pathAtAppFiles:(NSString *)fileName;
// 文件是否存在于AppFiles目录下
+ (BOOL)fileExistsAtAppFiles:(NSString *)fileName;
// 删除AppFiles目录下的指定文件
+ (BOOL)removeFileAtAppFiles:(NSString *)fileName;
// 删除指定路径下的文件
+ (BOOL)removeFileAtPath:(NSString *)filePath;


@end
