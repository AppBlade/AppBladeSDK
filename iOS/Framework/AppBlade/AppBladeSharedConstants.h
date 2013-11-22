/*!
 @header AppBladeSharedConstants
 @brief Header containing the shared constants used throughout AppBlade
 @discussion Support and FAQ can be found at http://support.appblade.com
*/

/*!
 @header AppBladeSharedConstants
 @brief Header containing all the constants that are used throughout the SDK.
 */

#ifndef AppBlade_AppBladeSharedConstants_h
#define AppBlade_AppBladeSharedConstants_h
/*!
 @brief If this status code is ever returned, that means the token is expired and needs renewing before the api can be called
 @discussion Other Non-essential Pending reqests will be paused in the interim.
 @seealso //apple_ref/doc/anysymbol/APBTokenManager APBTokenManager
 */
static const int kTokenRefreshStatusCode                       = 401;
/*!
 @brief  If the above status code is ever returned, that means the app is being used illegally and should be closed
 @discussion If not closable, like if the app were in production, for example. The SDK is merely disabled.
 @seealso //apple_ref/doc/anysymbol/APBTokenManager APBTokenManager
 */
static const int kTokenInvalidStatusCode                       = 403;




/*! @constant */
static NSString* const s_sdkVersion                     = @"0.5.0";
/*! @constant */
static NSString* const kAppBladeDefaultHost             = @"https://appblade.com";
/*! @constant */
static NSString* const kAppBladeErrorDomain             = @"com.appblade.sdk";

/*!
 @brief Alert tag for the "Update Available" dialog.
 Every alert view should have a unique tag for behavior control
 */
static const int kUpdateAlertTag                               = 316;

/*!
 @brief Alert tag for the "Permission Denied" dialog.
 Every alert view should have a unique tag for behavior control
 */
static const int kPermissionDeniedAlertTag                     = 613;


/*!
 The Appblade cache folder name
 */
static NSString* const kAppBladeCacheDirectory          = @"AppBladeCache";

static NSString* const kAppBladeBacklogFileName         = @"AppBladeBacklog.plist";

static NSString* const kAppBladeFeedbackKeyNotes        = @"notes";
static NSString* const kAppBladeFeedbackKeyScreenshot   = @"screenshot";
static NSString* const kAppBladeFeedbackKeyFeedback     = @"feedback";
static NSString* const kAppBladeFeedbackKeyBackup       = @"backupFileName";

static NSString* const kAppBladeCrashReportKeyFilePath  = @"queuedFilePath";
static NSString* const kAppBladeCustomFieldsFile        = @"AppBladeCustomFields.plist";

static NSString* const kAppBladeSessionFile             = @"AppBladeSessions.txt";

static NSString* const kAppBladeKeychainTtlKey          = @"appBlade_ttl";
/*! 
 AppBlade Dictionary key
 */
static NSString* const kAppBladeKeychainDeviceSecretKey = @"appBlade_device_secret";
/*!
 Key of the second-freshest secret in the kAppBladeKeychainDeviceSecretKey Dictionary
 */
static NSString* const kAppBladeKeychainDeviceSecretKeyOld = @"old_secret";
/*!
 Key of the freshest secret in the kAppBladeKeychainDeviceSecretKey Dictionary
 */
static NSString* const kAppBladeKeychainDeviceSecretKeyNew = @"new_secret";
/*!
 Key for the last plist hash in the kAppBladeKeychainDeviceSecretKey Dictionary
 */
static NSString* const kAppBladeKeychainPlistHashKey       = @"plist_hash";

/*!
 Key for the SDK Disabled flag
 */
static NSString* const kAppBladeKeychainDisabledKey        = @"appBlade_disabled";

static NSString* const kAppBladeKeychainDisabledValueTrue    = @"is_disabled";
static NSString* const kAppBladeKeychainDisabledValueFalse   = @"not_disabled";

static NSString* const kAppBladePlistApiDictionaryKey    = @"api_keys";
static NSString* const kAppBladePlistDeviceSecretKey     = @"device_secret";
static NSString* const kAppBladePlistProjectSecretKey    = @"project_secret";
static NSString* const kAppBladePlistEndpointKey         = @"host";
static NSString* const kAppBladePlistDefaultDeviceSecretValue    = @"DEFAULT";
static NSString* const kAppBladePlistDefaultProjectSecretValue   = @"DEFAULT";

static const int kAppBladeOfflineError = 1200;
static const int kAppBladeParsingError = 1208;
static const int kAppBladePermissionError = 1216;
static NSString* const s_letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
static NSString* const kAppBladeApiTokenResponseDeviceSecretKey     = @"device_secret";
static NSString* const kAppBladeApiTokenResponseTimeToLiveKey       = @"ttl";


typedef NS_OPTIONS(NSUInteger, AppBladeFeedbackSetupOptions) {
    AppBladeFeedbackSetupDefault                 = 0,      // default behavior
    AppBladeFeedbackSetupTripleFingerDoubleTap   = 1 <<  0,   // on all touch downs
    AppBladeFeedbackSetupCustomPrompt            = 1 <<  1    // on multiple touchdowns (tap count > 1)
};

typedef NS_OPTIONS(NSUInteger, AppBladeFeedbackDisplayOptions) {
    AppBladeFeedbackDisplayDefault                 = 0,      // default behavior
    AppBladeFeedbackDisplayWithScreenshot          = 1 <<  0,   // Take a screenshot to send with the feedback (default)
    AppBladeFeedbackDisplayWithoutScreenshot       = 1 <<  1    // Do not take a screenshot
};



#endif
