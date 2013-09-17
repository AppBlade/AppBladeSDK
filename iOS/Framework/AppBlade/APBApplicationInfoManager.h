/*!
 @framework AppBlade
 @header  APBApplicationInfoManager.h
 @abstract  Holds all application information methods, linked through to the APBApplicationInfoManager
 @author AndrewTremblay on 7/16/13.
 @copyright Raizlabs 2013. All rights reserved.
 */

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
