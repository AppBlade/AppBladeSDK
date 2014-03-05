//
//  APBDataBaseSubSession.h
//  AppBlade
//
//  Created by AndrewTremblay on 3/5/14.
//  Copyright (c) 2014 AppBlade Corporation. All rights reserved.
//

#import "AppBladeDatabaseObject.h"

static NSString* const kDbSubSessionTrackColumnNameStartedAt = @"startedSubSessionAt";
static NSString* const kDbSubSessionTrackColumnNameEndedAt   = @"endedSubSessionAt";
static NSString* const kDbSubSessionTrackColumnNameParentSession = @"parentSessionId";
static NSString* const kDbSubSessionTrackColumnNameEventHash   = @"event";

@interface APBDataBaseSubSession : AppBladeDatabaseObject

@end
