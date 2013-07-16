//
//  AppBladeConstants.h
//  AppBlade
//
//  Created by AndrewTremblay on 7/16/13.
//  Copyright (c) 2013 Raizlabs. All rights reserved.
//


#ifndef AppBlade_AppBladeSharedConstants_h
#define AppBlade_AppBladeSharedConstants_h

UIKIT_EXTERN NSString* const kAppBladeErrorDomain;
UIKIT_EXTERN int const kAppBladeOfflineError;
UIKIT_EXTERN int const kAppBladeParsingError;
UIKIT_EXTERN int const kAppBladePermissionError;
UIKIT_EXTERN NSString* const kAppBladeCacheDirectory;



static NSString* const s_sdkVersion                     = @"0.5.0";
static NSString* const kAppBladeDefaultHost             = @"https://appblade.com";
NSString* const kAppBladeErrorDomain                    = @"com.appblade.sdk";

const int kUpdateAlertTag                               = 316;
const int kTokenRefreshStatusCode                       = 401; 
//if the above status code is ever returned, that means the token is expired and needs renewing before the api can be called
const int kTokenInvalidStatusCode                       = 403;
//if the above status code is ever returned, that means the app is being used illegally and should be closed



//Feature file names and paths
static NSString* const kAppBladeBacklogFileName         = @"AppBladeBacklog.plist";

static NSString* const kAppBladeFeedbackKeyNotes        = @"notes";
static NSString* const kAppBladeFeedbackKeyScreenshot   = @"screenshot";
static NSString* const kAppBladeFeedbackKeyFeedback     = @"feedback";
static NSString* const kAppBladeFeedbackKeyBackup       = @"backupFileName";
static NSString* const kAppBladeCrashReportKeyFilePath  = @"queuedFilePath";
static NSString* const kAppBladeCustomFieldsFile        = @"AppBladeCustomFields.plist";

static NSString* const kAppBladeSessionFile             = @"AppBladeSessions.txt";

//Keychain Values
static NSString* const kAppBladeKeychainTtlKey          = @"appBlade_ttl";
static NSString* const kAppBladeKeychainDeviceSecretKey = @"appBlade_device_secret";
static NSString* const kAppBladeKeychainDeviceSecretKeyOld = @"old_secret";
static NSString* const kAppBladeKeychainDeviceSecretKeyNew = @"new_secret";
static NSString* const kAppBladeKeychainPlistHashKey       = @"plist_hash";


static NSString* const kAppBladeKeychainDisabledKey        = @"appBlade_disabled";
static NSString* const kAppBladeKeychainDisabledValueTrue    = @"is_disabled";
static NSString* const kAppBladeKeychainDisabledValueFalse   = @"not_disabled";

//Plist Key Values
static NSString* const kAppBladePlistApiDictionaryKey    = @"api_keys";
static NSString* const kAppBladePlistDeviceSecretKey     = @"device_secret";
static NSString* const kAppBladePlistProjectSecretKey    = @"project_secret";
static NSString* const kAppBladePlistEndpointKey         = @"host";
static NSString* const kAppBladePlistDefaultDeviceSecretValue    = @"DEFAULT";
static NSString* const kAppBladePlistDefaultProjectSecretValue   = @"DEFAULT";


const int kAppBladeOfflineError                         = 1200;
const int kAppBladeParsingError                         = 1208;
const int kAppBladePermissionError                      = 1216;

NSString* const kAppBladeCacheDirectory                 = @"AppBladeCache";

static NSString* const s_letters                        = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";

//API Response Values
static NSString* const kAppBladeApiTokenResponseDeviceSecretKey     = @"device_secret";
static NSString* const kAppBladeApiTokenResponseTimeToLiveKey       = @"ttl";


#endif
