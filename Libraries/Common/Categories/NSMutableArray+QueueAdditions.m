//
//  NSMutableArray+QueueAdditions.m
//  ProjectLibrary
//
//  Created by alby on 14/9/24.
//  Copyright (c) 2014年 alby. All rights reserved.
//

#import "NSMutableArray+QueueAdditions.h"

@implementation NSMutableArray (QueueAdditions)

// Add to the tail of the queue (no one likes it when people cut in line!)
- (void)enqueue:(id)anObject {
    [self addObject:anObject];
    //this method automatically adds to the end of the array
}

- (id)dequeue {
    if ([self count] == 0) {
        return nil;
    }
    id queueObject = [self objectAtIndex:0];
    [self removeObjectAtIndex:0];       // beginning of the array is the back of the queue
    return queueObject;
}

- (id)peek:(NSUInteger)index {
    if (index >= [self count]) {
        return nil;
    }
    id queueObject = [self objectAtIndex:index];
    return queueObject;
}

// if there aren't any objects in the queue
// peek returns nil, and we will too
- (id)peekHead {
	return [self peek:0];
}

// if 0 objects, we call peek:-1 which returns nil
- (id)peekTail {
	return [self peek:[self count] - 1];
}

- (BOOL)isEmpty
{
    return [self count] == 0;
}

@end
