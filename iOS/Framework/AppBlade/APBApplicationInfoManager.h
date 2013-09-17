/*!
 @framework AppBlade
 @header  APBApplicationInfoManager.h
 @abstract  Holds all application information methods, linked through to the APBApplicationInfoManager
 @author AndrewTremblay on 7/16/13.
 @copyright Raizlabs 2013. All rights reserved.
 */

#import <Foundation/Foundation.h>
#import "AppBlade.h"

/*!
 @class APBApplicationInfoManager
 @brief Core Manager for our Application Infomation retreival.
 */
@interface APBApplicationInfoManager : NSObject

/*!
 @return a uuid of the executable (00000-0000-0000-0000-00000000 if simulator)
 @discussion we find the uuid of the executable by using the symbol _mh_execute_header and walking the load commands of its program to determine the ending (or beginning) of any section or segment in the program.
 
 The value of the link editor defined symbol _MH_EXECUTE_SYM is the address of the mach header
 
 This should not be confused with the hashExecutable call, which returns an MD5 hash
 
 */
@property (nonatomic, strong) NSString *executableUUID;

/*!
 @return a uuid of the executable
 @discussion we find the uuid of the executable by using the symbol _mh_execute_header and walking the load commands of its program to determine the ending (or beginning) of any section or segment in the program.
 */
- (NSString*)hashInfoPlist;


/*!
 @return A MD5 hash file value of the executable
 
 @discussion we find the hash of the executable by first taking [NSBundle mainBundle] executablePath] and finding the hashFile value.
 
 This should not be confused with the executableUUID call, which walks the load commands and does not return an MD5 hash
 
 */
- (NSString*)hashExecutable;


/*!
 @param filePath the path to the file you'd like to know the hash of
 @return A MD5 hash file value of an arbitrary filepath, or the hash of an empty string if it does not exist
 
 @discussion The file we are finding the hash of should not be affected in any way by the Hashing function. 
 If no file exists at the path, the hash of an empty string will be returned "d41d8cd98f00b204e9800998ecf8427e"
 
 */
- (NSString*)hashFile:(NSString *)filePath;

@end


/*!
 @category AppBlade(ApplicationInfo)
 An AppBlade category for ApplicationInfo methods.
 Basically, instead of having direct calls to applicationInfoManager, AppBlade can call the hot-potato helper method.
 */
@interface AppBlade (ApplicationInfo)
@property (nonatomic, strong) APBApplicationInfoManager *applicationInfoManager;

/*!
 @return a uuid of the executable (00000-0000-0000-0000-00000000 if simulator)
 @discussion we find the uuid of the executable by using the symbol _mh_execute_header and walking the load commands of its program to determine the ending (or beginning) of any section or segment in the program.
 
 The value of the link editor defined symbol _MH_EXECUTE_SYM is the address of the mach header
 
 This should not be confused with the hashExecutable call, which returns an MD5 hash

 */
- (NSString *)executableUUID;


/*!
 @return a uuid of the executable
 @discussion we find the uuid of the executable by using the symbol _mh_execute_header and walking the load commands of its program to determine the ending (or beginning) of any section or segment in the program.
 */
- (NSString *)hashInfoPlist;

/*!
 @return A MD5 hash file value of the executable

 @discussion we find the hash of the executable by first taking [NSBundle mainBundle] executablePath] and finding the hashFile value.
 
 This should not be confused with the executableUUID call, which walks the load commands and does not return an MD5 hash

 */
- (NSString *)hashExecutable;

/*! 
 @brief Detects if whether the application is signed by Apple.

 @return true if fairplay encryption is detected. False otherwise.

 @discussion This method uses LC_ENCRYPTION_INFO (a non simulator method) to detect whether a fairplay encryption is enabled in the binary.
 
 For debug purposes, this call respects the  APPBLADE_TEST_FAIRPLAY_ENCRYPTED compiler flag. If defined, this function will always return true.
 
 Equally, this function will always return false if detect TARGET_IPHONE_SIMULATOR is detected.

 */
- (BOOL)isAppStoreBuild;

/*!
 @brief Detects if the application is being debugged.
 
 @return true if the application is being debugged.
 
 @discussion Detects if whether the application is being debugged. Returns true if the P_TRACED flag is set.
 src https://developer.apple.com/library/mac/qa/qa1361/_index.html
 */
- (BOOL)isBeingDebugged;
@end
