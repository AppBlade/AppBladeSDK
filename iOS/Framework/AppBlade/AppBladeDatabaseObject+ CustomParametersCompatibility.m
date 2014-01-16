//
//  AppBladeDatabaseObject+CustomParamtersCompatibilityLayer.m
//  AppBlade
//
//  Created by AndrewTremblay on 1/11/14.
//  Copyright (c) 2014 AppBlade Corporation. All rights reserved.
//

#import "AppBladeDatabaseObject+CustomParametersCompatibility.h"

#ifndef SKIP_CUSTOM_PARAMS
#import "AppBlade.h"
#import "APBCustomParametersManager.h"
#endif

@implementation AppBladeDatabaseObject (CustomParametersCompatibility)
@dynamic customParameterId;

-(NSDictionary *)getCustomParamSnapshot {
#ifndef SKIP_CUSTOM_PARAMS
    return [self.customParameterObj asDictionary];
#else
    return @{ };
#endif
}

-(void)setCustomParamSnapshot {
#ifndef SKIP_CUSTOM_PARAMS
    if(self.customParameterId == nil){
        NSError *error = nil;
        APBDatabaseCustomParameter *newCustomParamDataObj = [[[AppBlade sharedManager] customParamsManager]  generateCustomParameterFromCurrentParamsWithError:&error];
        self.customParameterId = [newCustomParamDataObj getId];
    }//currently we only cover setting the custom parameter once.
#endif
    //if we don't have custom parameters enabled, this call does nothing
}

#ifndef SKIP_CUSTOM_PARAMS
-(APBDatabaseCustomParameter *)customParameterObj{
    //lookup custom parameter obj, this should occur rarely if ever.
    return [[[AppBlade sharedManager] customParamsManager] getCustomParamById:self.customParameterId];
}
#endif

@end
