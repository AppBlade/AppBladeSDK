//
//  APBApplicationInfoManager.m
//  AppBlade
//
//  Created by AndrewTremblay on 9/3/13.
//  Copyright (c) 2013 Raizlabs. All rights reserved.
//

#import "APBApplicationInfoManager.h"
#import "AppBladeLogging.h"

#import <CommonCrypto/CommonHMAC.h>
#import <mach-o/ldsyms.h>
#import <mach-o/dyld.h>
#import <dlfcn.h>
#import <TargetConditionals.h>
#include "APBFileMD5Hash.h"

@implementation APBApplicationInfoManager

@synthesize executableUUID;

- (NSString *)executable_uuid
{
#if TARGET_IPHONE_SIMULATOR
    return @"00000-0000-0000-0000-00000000";
#else
    return [self genExecutableUUID];
#endif
}


//_mh_execute_header is declared in mach-o/ldsyms.h (and not an iVar as you might have thought).
-(NSString *)genExecutableUUID //will break in simulator, please be careful
{
#if TARGET_IPHONE_SIMULATOR
    return @"00000-0000-0000-0000-00000000";
#else
    if(self.executableUUID == nil){
        const uint8_t *command = (const uint8_t *)(&_mh_execute_header + 1);
        for (uint32_t idx = 0; idx < _mh_execute_header.ncmds; ++idx) {
            if (((const struct load_command *)command)->cmd == LC_UUID) {
                command += sizeof(struct load_command);
                self.executableUUID = [NSString stringWithFormat:@"%02X%02X%02X%02X-%02X%02X-%02X%02X-%02X%02X-%02X%02X%02X%02X%02X%02X",
                                   command[0], command[1], command[2], command[3],
                                   command[4], command[5],
                                   command[6], command[7],
                                   command[8], command[9],
                                   command[10], command[11], command[12], command[13], command[14], command[15]];
                break;
            }
            else
            {
                command += ((const struct load_command *)command)->cmdsize;
            }
        }
    }
    return self.executableUUID;
#endif
}

#pragma mark - MD5 Hashing


- (NSString*)hashFile:(NSString *)filePath
{
    
    NSString* returnString = nil;
    CFStringRef executableFileMD5Hash =
    FileMD5HashCreateWithPath((__bridge CFStringRef)(filePath), APBFileHashDefaultChunkSizeForReadingData);
    if (executableFileMD5Hash) {
        returnString = (__bridge NSString *)(executableFileMD5Hash);
        CFRelease(executableFileMD5Hash);
    }
    return returnString ;
}

- (NSString*)hashExecutable
{
    NSString *executablePath = [[NSBundle mainBundle] executablePath];
    return [self hashFile:executablePath];
}

- (NSString*)hashInfoPlist
{
    NSString *plistPath = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"Info.plist"];
    return [self hashFile:plistPath];
}

@end

@implementation AppBlade (ApplicationInfo)
@dynamic applicationInfoManager;

- (NSString *)executableUUID
{
    return self.applicationInfoManager.executable_uuid;
}

- (NSString *)hashInfoPlist
{
    return self.applicationInfoManager.hashInfoPlist;
}

- (NSString *)hashExecutable
{
    return self.applicationInfoManager.hashExecutable;
}


/* The encryption info struct and constants are missing from the iPhoneSimulator SDK, but not from the iPhoneOS or
 * Mac OS X SDKs. Since one doesn't ever ship a Simulator binary, we'll just provide the definitions here. */
#if TARGET_IPHONE_SIMULATOR && !defined(LC_ENCRYPTION_INFO)
#define LC_ENCRYPTION_INFO 0x21
struct encryption_info_command {
    uint32_t cmd;
    uint32_t cmdsize;
    uint32_t cryptoff;
    uint32_t cryptsize;
    uint32_t cryptid;
};
#endif
int main (int argc, char *argv[]);


-(BOOL)isAppStoreBuild
{
    return is_encrypted();
}

static BOOL is_encrypted () {
#if TARGET_IPHONE_SIMULATOR
    return NO;
#else
    const struct mach_header *header;
    Dl_info dlinfo;
    
    /* Fetch the dlinfo for main() */
    if (dladdr(main, &dlinfo) == 0 || dlinfo.dli_fbase == NULL) {
        ABErrorLog(@"Could not find main() symbol (very odd)");
        return NO;
    }
    header = dlinfo.dli_fbase;
    
    /* Compute the image size and search for a UUID */
    struct load_command *cmd = (struct load_command *) (header+1);
    
    for (uint32_t i = 0; cmd != NULL && i < header->ncmds; i++) {
        /* Encryption info segment */
        if (cmd->cmd == LC_ENCRYPTION_INFO) {
            struct encryption_info_command *crypt_cmd = (struct encryption_info_command *) cmd;
            /* Check if binary encryption is enabled */
            if (crypt_cmd->cryptid < 1) {
                /* Disabled, probably pirated */
                return NO;
            }
            
            /* Probably not pirated? */
            return YES;
        }
        
        cmd = (struct load_command *) ((uint8_t *) cmd + cmd->cmdsize);
    }
    
    /* Encryption info not found */
    return NO;
#endif
}



@end

