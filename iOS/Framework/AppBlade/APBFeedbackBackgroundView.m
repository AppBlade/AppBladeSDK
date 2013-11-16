//
//  FeedbackBackgroundView.m
//  AppBlade
//
//  Created by Michele Titolo on 5/15/12.
//  Copyright (c) 2012 AppBlade Corporation. All rights reserved.
//

#import "APBFeedbackBackgroundView.h"
#import "APBFeedbackDialogue.h"

@implementation APBFeedbackBackgroundView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}


- (void)drawRect:(CGRect)rect
{
    //// General 
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    //// Color 
    UIColor* color = [UIColor colorWithRed: 1 green: 1 blue: 1 alpha: 1];
    UIColor* color3 = [UIColor colorWithRed: 0.95 green: 0.95 blue: 0.95 alpha: 1];
    
    //// Gradient 
    NSArray* gradient7Colors = [NSArray arrayWithObjects: 
                                (id)color3.CGColor, 
                                (id)[UIColor whiteColor].CGColor, nil];
    CGFloat gradient7Locations[] = {0, 1};
    CGGradientRef gradient7 = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)(gradient7Colors), gradient7Locations);
    
    //// Shadow 
    CGColorRef shadow4 = [UIColor lightGrayColor].CGColor;
    CGSize shadow4Offset = CGSizeMake(1, 2);
    CGFloat shadow4BlurRadius = 2;
    CGColorRef shadow5 = [UIColor lightGrayColor].CGColor;
    CGSize shadow5Offset = CGSizeMake(0, 3);
    CGFloat shadow5BlurRadius = 5;
    CGColorRef shadow7 = color.CGColor;
    CGSize shadow7Offset = CGSizeMake(0, 1);
    CGFloat shadow7BlurRadius = 1;
    
    
    //// Rounded Rectangle Drawing
    UIBezierPath* roundedRectanglePath = [UIBezierPath bezierPathWithRoundedRect: CGRectMake(0, 0, feedbackWidthMin, feedbackHeightMin) cornerRadius: 4];
    CGContextSaveGState(context);
    CGContextSetShadowWithColor(context, shadow4Offset, shadow4BlurRadius, shadow4);
    [[UIColor whiteColor] setFill];
    [roundedRectanglePath fill];
    CGContextRestoreGState(context);
    
    [[UIColor lightGrayColor] setStroke];
    roundedRectanglePath.lineWidth = 1;
    [roundedRectanglePath stroke];
    
    
    //// Rounded Rectangle 4 Drawing
    UIBezierPath* roundedRectangle4Path = [UIBezierPath bezierPathWithRoundedRect: CGRectMake(0, 0, feedbackWidthMin, 47) byRoundingCorners: UIRectCornerTopLeft | UIRectCornerTopRight cornerRadii: CGSizeMake(4, 4)];
    CGContextSaveGState(context);
    CGContextSetShadowWithColor(context, shadow5Offset, shadow5BlurRadius, shadow5);
    CGContextSetFillColorWithColor(context, shadow5);
    [roundedRectangle4Path fill];
    [roundedRectangle4Path addClip];
    CGContextDrawLinearGradient(context, gradient7, CGPointMake(feedbackWidthMin / 2, 47.5), CGPointMake(feedbackWidthMin / 2, 0), 0);
    
    ////// Rounded Rectangle 4 Inner Shadow
    CGRect roundedRectangle4BorderRect = CGRectInset([roundedRectangle4Path bounds], -shadow7BlurRadius, -shadow7BlurRadius);
    roundedRectangle4BorderRect = CGRectOffset(roundedRectangle4BorderRect, -shadow7Offset.width, -shadow7Offset.height);
    roundedRectangle4BorderRect = CGRectInset(CGRectUnion(roundedRectangle4BorderRect, [roundedRectangle4Path bounds]), -1, -1);
    
    UIBezierPath* roundedRectangle4NegativePath = [UIBezierPath bezierPathWithRect: roundedRectangle4BorderRect];
    [roundedRectangle4NegativePath appendPath: roundedRectangle4Path];
    roundedRectangle4NegativePath.usesEvenOddFillRule = YES;
    
    CGContextSaveGState(context);
    {
        CGFloat xOffset = shadow7Offset.width + round(roundedRectangle4BorderRect.size.width);
        CGFloat yOffset = shadow7Offset.height;
        CGContextSetShadowWithColor(context,
                                    CGSizeMake(xOffset + copysign(0.1, xOffset), yOffset + copysign(0.1, yOffset)),
                                    shadow7BlurRadius,
                                    shadow7);
        
        [roundedRectangle4Path addClip];
        CGAffineTransform transform = CGAffineTransformMakeTranslation(-round(roundedRectangle4BorderRect.size.width), 0);
        [roundedRectangle4NegativePath applyTransform: transform];
        [[UIColor grayColor] setFill];
        [roundedRectangle4NegativePath fill];
    }
    CGContextRestoreGState(context);
    
    CGContextRestoreGState(context);
    
    [[UIColor lightGrayColor] setStroke];
    roundedRectangle4Path.lineWidth = 1;
    [roundedRectangle4Path stroke];
    
    //// Cleanup
    CGGradientRelease(gradient7);
    CGColorSpaceRelease(colorSpace);
}


@end
