//
//  APBDeviceInfoManager.h
//  AppBlade
//
//  Created by AndrewTremblay on 9/3/13.
//  Copyright (c) 2013 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AppBlade.h"

@interface APBDeviceInfoManager : NSObject

@property (nonatomic, strong) NSString* osVersionBuild;
@property (nonatomic, strong) NSString* platform;


@end

@interface AppBlade (DeviceInfo)

@property (nonatomic, strong) APBDeviceInfoManager* deviceInfoManager;

//helper getters for the inner functions
-(NSString*)  osVersionBuild;
-(NSString *) iosVersionSanitized;

-(NSString*)  platform;

-(BOOL) simpleJailBreakCheck;

@end
