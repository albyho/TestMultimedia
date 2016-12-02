//
//  UIButton+Helper.m
//  ProjectLibrary
//
//  Created by alby on 14/9/24.
//  Copyright (c) 2014年 alby. All rights reserved.
//

#import "UIButton+Helper.h"
#import <objc/runtime.h>

@implementation UIButton (Helper)

#pragma mark - EnlargeTouchArea

static char topNameKey;
static char rightNameKey;
static char bottomNameKey;
static char leftNameKey;

#pragma mark - EnlargeEdge
- (void)setEnlargeEdge:(CGFloat)value
{
    [self setEnlargeEdgeWithTop:value right:value bottom:value left:value];
}
- (void)setEnlargeEdgeWithTop:(CGFloat)top right:(CGFloat)right bottom:(CGFloat)bottom left:(CGFloat)left
{
    objc_setAssociatedObject(self, &topNameKey, @(top), OBJC_ASSOCIATION_COPY_NONATOMIC);
    objc_setAssociatedObject(self, &rightNameKey, @(right), OBJC_ASSOCIATION_COPY_NONATOMIC);
    objc_setAssociatedObject(self, &bottomNameKey, @(bottom), OBJC_ASSOCIATION_COPY_NONATOMIC);
    objc_setAssociatedObject(self, &leftNameKey, @(left), OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (CGRect)enlargedRect
{
    NSNumber* topEdge = objc_getAssociatedObject(self, &topNameKey);
    NSNumber* rightEdge = objc_getAssociatedObject(self, &rightNameKey);
    NSNumber* bottomEdge = objc_getAssociatedObject(self, &bottomNameKey);
    NSNumber* leftEdge = objc_getAssociatedObject(self, &leftNameKey);
    
    CGRect edge = self.bounds;
    if(topEdge && topEdge.floatValue > 0.0)
    {
        edge = CGRectMake(edge.origin.x,
                         edge.origin.y - topEdge.floatValue,
                         edge.size.width,
                         edge.size.height + topEdge.floatValue);
    }
    if(bottomEdge && bottomEdge.floatValue > 0.0)
    {
        edge = CGRectMake(edge.origin.x,
                          edge.origin.y ,
                          edge.size.width,
                          edge.size.height + bottomEdge.floatValue);
    
    }
    if(leftEdge && leftEdge.floatValue > 0.0)
    {
        edge = CGRectMake(edge.origin.x - leftEdge.floatValue,
                          edge.origin.y ,
                          edge.size.width + leftEdge.floatValue,
                          edge.size.height);
        
    }
    if(rightEdge && rightEdge.floatValue > 0.0)
    {
        edge = CGRectMake(edge.origin.x,
                          edge.origin.y,
                          edge.size.width  + rightEdge.floatValue,
                          edge.size.height);
        
    }
    
    return edge;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    CGRect rect = [self enlargedRect];
    if (CGRectEqualToRect(rect, self.bounds))
    {
        return [super hitTest:point withEvent:event];
    }
    return CGRectContainsPoint(rect, point) ? self : nil;
}

#pragma mark - VerticalAlignCenter
- (void)centerImageAndTitle:(float)spacing
{
    // get the size of the elements here for readability
    CGSize imageSize = self.imageView.frame.size;
    CGSize titleSize = self.titleLabel.frame.size;
    
    // get the height they will take up as a unit
    CGFloat totalHeight = (imageSize.height + titleSize.height + spacing);
    
    // raise the image and push it right to center it
    self.imageEdgeInsets = UIEdgeInsetsMake(- (totalHeight - imageSize.height), 0.0, 0.0, - titleSize.width);
    
    // lower the text and push it left to center it
    self.titleEdgeInsets = UIEdgeInsetsMake(0.0, - imageSize.width, - (totalHeight - titleSize.height), 0.0);
}

- (void)centerImageAndTitle
{
    const int DEFAULT_SPACING = 0.0f;
    [self centerImageAndTitle:DEFAULT_SPACING];
}

- (void)sd_setImageWithURLEx:(NSString *)url placeholderImage:(NSString *)placeholderImage
{
    [self sd_setImageWithURLEx:url placeholderImage:placeholderImage completed:nil];
}

- (void)sd_setImageWithURLEx:(NSString *)url completed:(SDWebImageCompletionBlock)completedBlock
{
    [self sd_setImageWithURLEx:url placeholderImage:nil completed:completedBlock];
}

- (void)sd_setImageWithURLEx:(NSString *)url placeholderImage:(NSString *)placeholderImage completed:(SDWebImageCompletionBlock)completedBlock
{
    if (url && ![url isEqual:[NSNull null]] && url.length > 0 && [url hasPrefix:@"http"]) {
        url = [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        [self sd_setImageWithURL:[NSURL URLWithString:url]
                        forState:UIControlStateNormal
                placeholderImage:[UIImage imageNamed:placeholderImage]
                       completed:completedBlock];
    }else{
        [self setImage:[UIImage imageNamed:placeholderImage] forState:UIControlStateNormal];
        //[self setImage:[UIImage imageWithContentsOfFile:url] forState:UIControlStateNormal];
    }
}


@end
