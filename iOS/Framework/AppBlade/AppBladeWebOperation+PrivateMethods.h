//
//  AppBladeWebOperation+PrivateMethods.h
//  AppBlade
//
//  Created by AndrewTremblay on 7/31/13.
//  Copyright (c) 2013 Raizlabs. All rights reserved.
//

#import "AppBladeWebOperation.h"


@interface AppBladeWebOperation (PrivateMethods)

-(void)issueRequest;
-(void)scheduleTimeout;
-(void)cancelTimeout;

// Crypto methods.
- (NSString *)HMAC_SHA256_Base64:(NSString *)data with_key:(NSString *)key;
- (NSString *)SHA_Base64:(NSString *)raw;
- (NSString *)genRandStringLength:(int)len;
- (NSString *)urlEncodeValue:(NSString*)string; //no longer being used
- (NSString *)hashFile:(NSString*)filePath;
- (NSString *)hashExecutable;
- (NSString *)hashInfoPlist;
//Device info
- (NSString *)genExecutableUUID;
- (NSString *)executable_uuid;
- (NSString *)ios_version_sanitized;

@end
