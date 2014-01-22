/*!
 @framework AppBlade
 @header  APBDeviceInfoManager.h
 @abstract  Holds all device information methods, linked through to the APBDeviceInfoManager
 @author AndrewTremblay on 7/16/13.
 @copyright AppBlade 2013. All rights reserved.
 */

#import <Foundation/Foundation.h>
#import "AppBlade.h"

/*!
 @class APBDeviceInfoManager
 @brief Core Manager for our Device Infomation retreival
 */
@interface APBDeviceInfoManager : NSObject

/*!
 @return the user defined name of the current device (read only)
*/
-(NSString *)deviceName;


/*!
 @return the alphanumeric build number of the operating system
 
 @discussion This method is not the same as [[UIDevice currentDevice] systemVersion], which woud return something human readable like 4.2.1 or 7.0.1
 
 We take CTL_KERN KERN_OSVERSION from the system header file sys/sysctl.h and build a string from those kernel values.
 
 http://stackoverflow.com/questions/4857195/how-to-programmatically-get-ioss-alphanumeric-version-string
 */
@property (nonatomic, strong) NSString* osVersionBuild;

/*!
 Finds Base Hardware platform name and returns it.
 @return a semi-readable, unique string identifier for the hardware platform
 @discussion
 the hardware platform is accessed via internal system header <sys/sysctl.h>
 
 From sysctlbyname("hw.machine") we create the unique platform identifier that Apple publically uses to identify hardware systems
 
 */
@property (nonatomic, strong) NSString* platform;


@end

/*!
 @category AppBlade(DeviceInfo)
 An AppBlade category for DeviceInfo methods.
 Bascally, instead of having direct calls to deviceInfoManager, AppBlade can call the hot-potato helper method.
 */
@interface AppBlade (DeviceInfo)

@property (nonatomic, strong) APBDeviceInfoManager* deviceInfoManager;

/*!
 @return the user defined name of the current device (read only)
 */
-(NSString*) userDefinedDeviceName;

/*!
 @return the alphanumeric build number of the operating system
 
 @discussion This method is not the same as [[UIDevice currentDevice] systemVersion], which woud return something human readable like 4.2.1 or 7.0.1
 
 We take CTL_KERN KERN_OSVERSION from the system header file sys/sysctl.h and build a string from those kernel values.
 
 http://stackoverflow.com/questions/4857195/how-to-programmatically-get-ioss-alphanumeric-version-string
 */
-(NSString*)  osVersionBuild;

/*!
 Removes all non ascii characters in the value of osVersionBuild and returns that sanitized string.

 @return a sanitized, ascii-only string of osVersionBuild
 */
-(NSString *) iosVersionSanitized;

/*!
 Finds Base Hardware platform name and returns it.
 @return a semi-readable, unique string identifier for the hardware platform
 @discussion
 the hardware platform is accessed via internal system header <sys/sysctl.h>
 
 From sysctlbyname("hw.machine") we create the unique platform identifier that Apple publically uses to identify hardware systems
 
 */
-(NSString*)  platform;

/*!
 @brief detects if the device is Jailbroken through a few standard checks
 
 @return True if a few basic checks for jailbreaking succeeeds.  
 
 @discussion Detecting whether a device is jailbroken from inside an an app is very difficult, since even a basic jailbreak user issue runtime code patches to change the values that certain methods return
 
 We have a preprocessor flag for testing purposes, APPBLADE_TEST_JAILBROKEN, that when set will make this method alwayse return true.
 
 */
-(BOOL) simpleJailBreakCheck;

@end
