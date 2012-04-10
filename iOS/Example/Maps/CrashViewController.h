//
//  CrashViewController.h
//  Maps
//
//  Created by Craig Spitzkoff on 6/18/11.
//  Copyright 2011 Raizlabs Corporation. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface CrashViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>
{
    NSArray* crashLabels;
}

- (IBAction)cancelPressed:(id)sender;

@end
