//
//  APBApplicationInfoManager.h
//  AppBlade
//
//  Created by AndrewTremblay on 9/3/13.
//  Copyright (c) 2013 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AppBlade.h"

@interface APBApplicationInfoManager : NSObject

@property (nonatomic, strong) NSString *executableUUID;
- (NSString*)hashInfoPlist;
- (NSString*)hashExecutable;
- (NSString*)hashFile:(NSString *)filePath;

@end


@interface AppBlade (ApplicationInfo)
@property (nonatomic, strong) APBApplicationInfoManager *applicationInfoManager;

- (NSString *)executableUUID;
- (NSString *)hashInfoPlist;
- (NSString *)hashExecutable;

- (BOOL)isAppStoreBuild;
- (BOOL)isBeingDebugged;
@end
