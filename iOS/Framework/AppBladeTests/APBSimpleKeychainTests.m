//
//  AppBladeSimpleKeychainTests.m
//  AppBlade
//
//  Created by AndrewTremblay on 7/30/13.
//  Copyright (c) 2013 AppBlade. All rights reserved.
//

#import "APBSimpleKeychainTests.h"

#import "APBSimpleKeychain.h"

@implementation APBSimpleKeychainTests
- (void)setUp
{
    [super setUp];
}

- (void)tearDown
{
    // Tear-down code here.
    [APBSimpleKeychain deleteLocalKeychain]; //Deletes every deletable thing we have in the app.
    [super tearDown];
}


-(void)test01keychainStoresAndLoads
{

}

-(void)test02keychainDeletesSpecificKey
{
    
}

-(void)test03errorMessageReturnsValidValue
{
    
}

-(void)test04sanitizeClearsKeychain
{
    
}



@end
