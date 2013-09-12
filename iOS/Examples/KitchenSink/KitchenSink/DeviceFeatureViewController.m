//
//  DeviceFeatureViewController.m
//  KitchenSink
//
//  Created by AndrewTremblay on 9/12/13.
//  Copyright (c) 2013 Raizlabs Corporation. All rights reserved.
//

#import "DeviceFeatureViewController.h"

@interface DeviceFeatureViewController ()

@end

@implementation DeviceFeatureViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.viewList = [[NSArray alloc] initWithObjects:
                     self.mdmDescriptionWrapperView,
                     self.nsUserDefaultsWrapperView,
                     self.kioskModeWrapperView,
                     self.appblockingWrapperView,
                     self.jailbreakDetectionWrapperView,
                     self.remoteWipeWrapperView,
                     self.batchDeviceControlView,
                     nil];
}

-(void)viewWillLayoutSubviews
{
	//Build the cards in the scroll view.
    [self buildViewListForScrollView:self.scrollView];
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
