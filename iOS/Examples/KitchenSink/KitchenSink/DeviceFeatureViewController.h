//
//  DeviceFeatureViewController.h
//  KitchenSink
//
//  Created by AndrewTremblay on 9/12/13.
//  Copyright (c) 2013 AppBlade Corporation. All rights reserved.
//

#import "BaseFeatureViewController.h"

@interface DeviceFeatureViewController : BaseFeatureViewController
@property (strong, nonatomic) IBOutlet UIView *mdmDescriptionWrapperView;
@property (strong, nonatomic) IBOutlet UIView *nsUserDefaultsWrapperView;
@property (strong, nonatomic) IBOutlet UIView *kioskModeWrapperView;
@property (strong, nonatomic) IBOutlet UIView *appblockingWrapperView;
@property (strong, nonatomic) IBOutlet UIView *jailbreakDetectionWrapperView;
@property (strong, nonatomic) IBOutlet UIView *remoteWipeWrapperView;
@property (strong, nonatomic) IBOutlet UIView *batchDeviceControlView;

@end
