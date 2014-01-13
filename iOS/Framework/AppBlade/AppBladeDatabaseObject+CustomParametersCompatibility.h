//
//  AppBladeDatabaseObject+CustomParamtersCompatibility.h
//  AppBlade
//
//  Created by AndrewTremblay on 1/11/14.
//  Copyright (c) 2014 AppBlade Corporation. All rights reserved.
//

#import "AppBladeDatabaseObject.h"
#import "APBDatabaseCustomParameter.h"

//database object that database object classes will always need to import in order to have / not have custom parameters attached to them
/* steps to use:
    import this header file.
 @property (nonatomic, strong) NSString *customParameterId; //must be implemented in the class
 
 
 */

@interface AppBladeDatabaseObject (CustomParametersCompatibility)
    -(NSDictionary *)getCustomParamSnapshot; //Returns custom params when the feature is enabled. False otherwise.
    -(void)setCustomParamSnapshot;  //sets custom param object from the current parameters.
    @property (nonatomic, strong) NSString *customParameterId; //must be implemented in the class

    -(APBDatabaseCustomParameter *)customParameterObj;

@end
