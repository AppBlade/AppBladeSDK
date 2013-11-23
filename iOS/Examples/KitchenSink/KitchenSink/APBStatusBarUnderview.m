//
//  APBStatusBarUnderView.m
//  KitchenSink
//  AppBladeHelperView for a custom UIStatusBar experience.
//  Created by AndrewTremblay on 11/22/13.
//  Copyright (c) 2013 AppBlade Corporation. All rights reserved.
//

#import "APBStatusBarUnderview.h"

@implementation APBStatusBarUnderview

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
    }
    return self;
}

//distance in pixles that the view offset must travel before transitioning fully to its final color
+(CGFloat) transitionDistance
{
    return 10;
}

//Our initial color when the offset is at zero (completely transparent by default)
+(UIColor *) initialColor
{
    return [UIColor colorWithRed:225.0f/255.0f green:0.0f/255.0f blue:0.0f/255.0f alpha:0.0f];
}

//Our final color when the offset is at our transition distance (red by default)
+(UIColor *) finalColor
{
    
    return [UIColor colorWithRed:225.0f/255.0f green:0.0f/255.0f blue:0.0f/255.0f alpha:1.0f];
}

//Changes the color based on the passed contentOffset of our scrollview
-(void)updateColorFromOffset:(CGFloat) contentOffset
{
    float ratio = contentOffset / [APBStatusBarUnderview transitionDistance];
    
    self.backgroundColor = [APBStatusBarUnderview blendInitialColor:[APBStatusBarUnderview initialColor] withSecondaryColor:[APBStatusBarUnderview finalColor] byRatio:ratio];
}



+(UIColor*) blendInitialColor:(UIColor*)c1 withSecondaryColor:(UIColor*) c2 byRatio:(float) ratio
{
    float inverse = 1.f - ratio;
    CGFloat r1, g1, b1, a1, r2, g2, b2, a2;
    [c1 getRed:&r1 green:&g1 blue:&b1 alpha:&a1];
    [c2 getRed:&r2 green:&g2 blue:&b2 alpha:&a2];
    CGFloat r = r1 * inverse + r2 * ratio;
    CGFloat g = g1 * inverse + g2 * ratio;
    CGFloat b = b1 * inverse + b2 * ratio;
    CGFloat alpha = a1 *inverse + a2 * ratio;
    return [UIColor colorWithRed:r green:g blue:b alpha:alpha];
}


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
