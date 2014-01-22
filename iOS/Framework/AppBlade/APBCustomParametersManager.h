/*!
 @header  APBCustomParametersManager.h
 @abstract  Holds all methods pertaining to custom parameters, which affect the subsequent web calls. 
 @framework AppBlade
 @author AndrewTremblay on 7/16/13.
 @copyright AppBlade 2013. All rights reserved.
 */


#import <Foundation/Foundation.h>

#import "APBBasicFeatureManager.h"
#import "AppBlade+PrivateMethods.h"

#import "APBDatabaseCustomParameter.h"
#import "APBDataManager.h"

static NSString* const kDbCustomParametersMainTableName = @"customparams";

/*!
 @class APBCustomParametersManager
 @abstract The Custom Parameter meta-feature
 @discussion This manager contains the storage and retrieval of the custom paramter meta-feature. For the other primary "reporter" functions, custom parameters are uselful for containing metadata for third part integration or other analytical protocols. 
 */
@interface APBCustomParametersManager : NSObject<APBBasicFeatureManager>
@property (nonatomic, strong) id<APBWebOperationDelegate, APBDataManagerDelegate> delegate;

@property (nonatomic, strong, readwrite) NSString *dbMainTableName;
@property (nonatomic, strong, readwrite) NSArray  *dbMainTableAdditionalColumns;

+(NSString *)getDefaultForeignKeyDefinition:(NSString *)referencingColumn;
-(APBDatabaseCustomParameter *)getCustomParamById:(NSString *)paramId;
-(APBDatabaseCustomParameter *)generateCustomParameterFromCurrentParamsWithError:(NSError * __autoreleasing *) error;

-(NSDictionary *)getCustomParams;
-(void)setCustomParams:(NSDictionary *)newFieldValues;
-(void)setCustomParam:(id)newObject withValue:(NSString*)key;
-(void)setCustomParam:(id)object forKey:(NSString*)key;
-(void)clearAllCustomParams;


-(void)removeCustomParamById:(NSString *)paramId error:(NSError * __autoreleasing *) error;

@end


//Our additional requirements
@interface AppBlade (CustomParameters)

@property (nonatomic, strong) APBCustomParametersManager* customParamsManager;

@end



@interface APBDataManager (CustomParameters)
@property (nonatomic) sqlite3 *db;

-(APBDatabaseCustomParameter *)insertNewCustomParams:(NSDictionary *)paramsToStore error:(NSError * __autoreleasing *) error;
-(APBDatabaseCustomParameter *)getCustomParameterWithID:(NSString *)customParamId;
-(NSError *)removeCustomParameterWithID:(NSString *)customParamId;

@end
