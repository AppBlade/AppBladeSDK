//
//  APBStatusBarUnderView.h
//  KitchenSink
//
//  Created by AndrewTremblay on 11/22/13.
//  Copyright (c) 2013 AppBlade Corporation. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface APBStatusBarUnderview : UIView

//distance in pixles that the view offset must travel before transitioning fully to its final color
+(CGFloat) transitionDistance;

//Our initial color when the offset is at zero (completely transparent by default)
+(UIColor *) initialColor;

//Our final color when the offset is at our transition distance (red by default)
+(UIColor *) finalColor;

//Changes the color based on the passed contentOffset of our scrollview
-(void)updateColorFromOffset:(CGFloat) contentOffset;


@end
