//
//  APBCustomParametersAppTests.m
//  KitchenSink
//
//  Created by AndrewTremblay on 1/26/14.
//  Copyright (c) 2014 AppBlade Corporation. All rights reserved.
//

#import "APBCustomParametersAppTests.h"

@implementation APBCustomParametersAppTests
- (void)setUp
{
    [super setUp];
    // Set-up code here.
    [[AppBlade sharedManager] clearAppBladeKeychain]; //start with nothing every time (logic for this stuff is handled in the SDK test)
    [[AppBlade sharedManager] clearCacheDirectory];
    [[AppBlade sharedManager] setDisabled:false]; //also make sure we start enabled
}

- (void)tearDown
{
    // Tear-down code here.
    [[AppBlade sharedManager] clearAllCustomParams]; //clear any parameters we used during the test
    
    [super tearDown];
}

-(void)test01CustomParametersBehaviorInitialized
{
    STAssertTrue(([[AppBlade sharedManager] initializedFeatures] && AppBladeFeaturesCustomParametersEnabled), @"Custom parameters feature must be enabled in order for tests to run.");
}

-(void) test02CustomParametersCreate
{
    STAssertNotNil([[[AppBlade sharedManager] customParamsManager] getCustomParams], @"Custom parameters should never be nil");
}

-(void) test03CustomParametersAreSetAndUnset
{
    NSString *storeTestString   = @"testValueString";
    NSDictionary *storeTestDict = @{@"testDictValue":@"testDictKey"};
    NSNumber *storeTestNumber   = @1;
    
     [[AppBlade sharedManager] setCustomParam:storeTestString forKey:@"stringKeyTest"];
     [[AppBlade sharedManager] setCustomParam:storeTestDict forKey:@"dictionaryKeyTest"];
     [[AppBlade sharedManager] setCustomParam:storeTestNumber forKey:@"numberKeyTest"];
    NSDictionary *dictTest1 = [[AppBlade sharedManager] getCustomParams];
    
    STAssertEqualObjects([dictTest1 objectForKey:@"stringKeyTest"], storeTestString, @"Strings must be storable");
    STAssertEqualObjects([dictTest1 objectForKey:@"dictionaryKeyTest"], storeTestDict, @"Dictionaries must be storable");
    STAssertEqualObjects([dictTest1 objectForKey:@"numberKeyTest"], storeTestNumber, @"Dictionaries must be storable");
    
    
    [[[AppBlade sharedManager] customParamsManager] setCustomParam:nil forKey:@"stringKeyTest"];
    NSDictionary *dictTest2 = [[AppBlade sharedManager] getCustomParams];
    STAssertNil([dictTest2 objectForKey:@"stringKeyTest"], @"Values must be clearable");
    STAssertNotNil([dictTest1 objectForKey:@"dictionaryKeyTest"], @"Clearable values must not affect other variables");

    [[AppBlade sharedManager] clearAllCustomParams];

    NSDictionary *dictTest3 = [[AppBlade sharedManager] getCustomParams];
    STAssertNil([dictTest3 objectForKey:@"dictionaryKeyTest"], @"Values must be clearable");
    STAssertNil([dictTest3 objectForKey:@"numberKeyTest"], @"Values must be clearable");
    
}

-(void) test04CustomParametersAreStoredInSnapshots
{
    //any parameters
    NSString *storeTestString   = @"testValueString";
    NSDictionary *storeTestDict = @{@"testDictValue":@"testDictKey"};
    NSNumber *storeTestNumber   = @1;
    [[AppBlade sharedManager] setCustomParam:storeTestString forKey:@"stringKeyTest"];
    [[AppBlade sharedManager] setCustomParam:storeTestDict forKey:@"dictionaryKeyTest"];
    [[AppBlade sharedManager] setCustomParam:storeTestNumber forKey:@"numberKeyTest"];

    NSError *errorTest1 = nil;
    APBDatabaseCustomParameter *customParam1 = [[[AppBlade sharedManager] customParamsManager] generateCustomParameterFromCurrentParamsWithError:&errorTest1];
    STAssertNil(errorTest1, @"Storing Custom Params snapshot returned error: %@", [errorTest1 debugDescription]);
    NSLog(@"%@", [errorTest1 debugDescription]);
    STAssertNotNil(customParam1, @"Custom parameters should have been generated");
    //storage test
    STAssertEqualObjects([customParam1 asDictionary], [[AppBlade sharedManager] getCustomParams], @"all values should be stored");
    
    //empty parameters
    NSError *errorTest2 = nil;
    [[AppBlade sharedManager] clearAllCustomParams];
    APBDatabaseCustomParameter *customParam2 = [[[AppBlade sharedManager] customParamsManager] generateCustomParameterFromCurrentParamsWithError:&errorTest2];
    NSLog(@"%@", [errorTest2 debugDescription]);
    STAssertNil(errorTest2, @"Storing Custom Params snapshot returned error");
    STAssertNotNil(customParam1, @"Custom parameters should have been generated");
    
    STAssertFalse([[customParam1 asDictionary] isEqualToDictionary:[customParam2 asDictionary]], @"custom parameters  snapshots should be different");

    
    //data retrieval
    APBDatabaseCustomParameter *customParam1Compare = [[[AppBlade sharedManager] customParamsManager] getCustomParamById:[customParam1 getId]];
    STAssertNotNil(customParam1Compare, @"custom params could not be retrieved.");
    STAssertEqualObjects([customParam1 asDictionary], [customParam1Compare asDictionary], @"stored values should be equal to the original values");
    STAssertFalse([[customParam1Compare asDictionary] isEqualToDictionary:[[AppBlade sharedManager] getCustomParams]], @"custom parameters should be different from the snapshot");
    
    APBDatabaseCustomParameter *customParam2Compare = [[[AppBlade sharedManager] customParamsManager] getCustomParamById:[customParam2 getId]];
    STAssertNotNil(customParam2Compare, @"custom params could not be retrieved.");
    STAssertEqualObjects([customParam2 asDictionary], [customParam2Compare asDictionary], @"stored values should be equal to the original values");
}


-(void) test05CustomParameterSnapshotsStoredAndRemoved
{
    //any parameters
    NSString *storeTestString   = @"testValueString";
    NSDictionary *storeTestDict = @{@"testDictValue":@"testDictKey"};
    NSNumber *storeTestNumber   = @1;
    [[AppBlade sharedManager] setCustomParam:storeTestString forKey:@"stringKeyTest"];
    [[AppBlade sharedManager] setCustomParam:storeTestDict forKey:@"dictionaryKeyTest"];
    [[AppBlade sharedManager] setCustomParam:storeTestNumber forKey:@"numberKeyTest"];

    NSError *errorTest1 = nil;
    APBDatabaseCustomParameter *customParam1 = [[[AppBlade sharedManager] customParamsManager] generateCustomParameterFromCurrentParamsWithError:&errorTest1];
    STAssertNil(errorTest1, @"Storing Custom Params snapshot returned error: %@", [errorTest1 debugDescription]);
    NSLog(@"%@", [errorTest1 debugDescription]);
    STAssertNotNil(customParam1, @"Custom parameters should have been generated");
    //storage test
    STAssertEqualObjects([customParam1 asDictionary], [[AppBlade sharedManager] getCustomParams], @"all values should be stored");

    //data retrieval
    APBDatabaseCustomParameter *customParam1Compare = [[[AppBlade sharedManager] customParamsManager] getCustomParamById:[customParam1 getId]];
    STAssertEqualObjects([customParam1 asDictionary], [customParam1Compare asDictionary], @"stored values should be equal to the original values");

    //data removal
    NSError *errorTest2 = nil;
    [[[AppBlade sharedManager] customParamsManager] removeCustomParamById:[customParam1 getId] error:&errorTest2];
    STAssertNil(errorTest1, @"removing Custom Params snapshot returned error: %@", [errorTest1 debugDescription]);

    //data should not exist
    APBDatabaseCustomParameter *customParam1Get = [[[AppBlade sharedManager] customParamsManager] getCustomParamById:[customParam1 getId]];
    STAssertNil(customParam1Get, @"Custom Params snapshot should be removed");

}

@end
