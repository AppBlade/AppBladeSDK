/*!
 @framework AppBlade
 @header  APBDeviceInfoManager.h
 @abstract  Holds all device information methods, linked through to the APBDeviceInfoManager
 @author AndrewTremblay on 7/16/13.
 @copyright Raizlabs 2013. All rights reserved.
 */

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
