//
//  AppBladeTokenRequestManager.h
//  AppBlade
//
//  Created by AndrewTremblay on 8/29/13.
//  Copyright (c) 2013 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AppBlade.h"

@interface AppBladeTokenRequestManager : NSObject
-(NSOperationQueue *) tokenRequests;
-(NSOperationQueue *) addTokenRequest:(NSOperation *)request;

- (void)refreshToken:(NSString *)tokenToConfirm;
- (void)confirmToken:(NSString *)tokenToConfirm;
- (BOOL)isCurrentToken:(NSString *)token;
- (BOOL)tokenConfirmRequestPending;
- (BOOL)tokenRefreshRequestPending;

@end
