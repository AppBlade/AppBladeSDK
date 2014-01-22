//
//  APBDeviceInfoManager.m
//  AppBlade
//
//  Created by AndrewTremblay on 9/3/13.
//  Copyright (c) 2013 AppBlade. All rights reserved.
//

#import "APBDeviceInfoManager.h"

#include <sys/sysctl.h>


@implementation APBDeviceInfoManager

-(NSString *)deviceName
{
    return [[UIDevice currentDevice] name];
}

// From: http://stackoverflow.com/questions/4857195/how-to-get-programmatically-ioss-alphanumeric-version-string
- (NSString *)osVersionBuild {
    if(_osVersionBuild == nil){
        int mib[2] = {CTL_KERN, KERN_OSVERSION};
        u_int namelen = sizeof(mib) / sizeof(mib[0]);
        size_t bufferSize = 0;
        
        NSString *osBuildVersion = nil;
        
        // Get the size for the buffer
        sysctl(mib, namelen, NULL, &bufferSize, NULL, 0);
        
        u_char buildBuffer[bufferSize];
        int result = sysctl(mib, namelen, buildBuffer, &bufferSize, NULL, 0);
        
        if (result >= 0) {
            osBuildVersion = [[NSString alloc] initWithBytes:buildBuffer length:bufferSize encoding:NSUTF8StringEncoding];
        }
        _osVersionBuild = osBuildVersion;
    }
    return _osVersionBuild;
}

- (NSString *)iosVersionSanitized
{
    NSMutableString *asciiCharacters = [NSMutableString string];
    for (NSInteger i = 32; i < 127; i++)  {
        [asciiCharacters appendFormat:@"%c", i];
    }
    NSCharacterSet *nonAsciiCharacterSet = [[NSCharacterSet characterSetWithCharactersInString:asciiCharacters] invertedSet];
    NSString *rawVersionString = [self osVersionBuild];
    return [[rawVersionString componentsSeparatedByCharactersInSet:nonAsciiCharacterSet] componentsJoinedByString:@""];
}

- (NSString *) platform {
    if(_platform == nil){
        size_t size;
        sysctlbyname("hw.machine", NULL, &size, NULL, 0);
        char *machine = malloc(size);
        sysctlbyname("hw.machine", machine, &size, NULL, 0);
        _platform = [NSString stringWithCString:machine encoding:NSUTF8StringEncoding];
        free(machine);
    }
    return _platform;
}


-(BOOL) simpleJailBreakCheck
{
    return (
#if !TARGET_IPHONE_SIMULATOR
            [[NSFileManager defaultManager] fileExistsAtPath:@"/bin/bash"] || //tests fail on this for simulator
#endif
            [[NSFileManager defaultManager] fileExistsAtPath:@"/Applications/Cydia.app"] ||
            [[NSFileManager defaultManager] fileExistsAtPath:@"/private/var/lib/apt"]);
}

@end


@implementation AppBlade (DeviceInfo)

@dynamic deviceInfoManager;

-(NSString*) userDefinedDeviceName
{
    return self.deviceInfoManager.deviceName;
}


-(NSString*) osVersionBuild
{
    return self.deviceInfoManager.osVersionBuild;
}

- (NSString *)iosVersionSanitized
{
    return self.deviceInfoManager.iosVersionSanitized;
}

-(NSString*) platform
{
    return self.deviceInfoManager.platform;
}

-(BOOL) simpleJailBreakCheck
{
#ifdef APPBLADE_TEST_JAILBROKEN
    return true;
#else
    return [self.deviceInfoManager simpleJailBreakCheck];
#endif
}

@end