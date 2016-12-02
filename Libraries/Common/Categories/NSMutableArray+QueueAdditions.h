//
//  NSMutableArray+QueueAdditions.h
//  ProjectLibrary
//
//  Created by alby on 14/9/24.
//  Copyright (c) 2014年 alby. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableArray (QueueAdditions) 
- (id)dequeue;
- (void)enqueue:(id)obj;
- (id)peek:(NSUInteger)index;
- (id)peekHead;
- (id)peekTail;
- (BOOL)isEmpty;
@end