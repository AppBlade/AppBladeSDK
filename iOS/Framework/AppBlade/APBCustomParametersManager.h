/*!
 @header  APBCustomParametersManager.h
 @abstract  Holds all methods pertaining to custom parameters, which affect the subsequent web calls. 
 @framework AppBlade
 @author AndrewTremblay on 7/16/13.
 @copyright Raizlabs 2013. All rights reserved.
 */


#import <Foundation/Foundation.h>

#import "APBBasicFeatureManager.h"
#import "AppBlade+PrivateMethods.h"

/*!
 @class APBCustomParametersManager
 @abstract The Custom Parameter meta-feature
 @discussion This manager contains the storage and retrieval of the custom paramter meta-feature. For the other primary "reporter" functions, custom parameters are uselful for containing metadata for third part integration or other analytical protocols. 
 */
@interface APBCustomParametersManager : NSObject<APBBasicFeatureManager>
@property (nonatomic, strong) id<APBWebOperationDelegate> delegate;

-(NSDictionary *)getCustomParams;
-(void)setCustomParams:(NSDictionary *)newFieldValues;
-(void)setCustomParam:(id)newObject withValue:(NSString*)key;
-(void)setCustomParam:(id)object forKey:(NSString*)key;
-(void)clearAllCustomParams;

@end


//Our additional requirements
@interface AppBlade (CustomParameters)

@property (nonatomic, strong) APBCustomParametersManager* customParamsManager;

@end