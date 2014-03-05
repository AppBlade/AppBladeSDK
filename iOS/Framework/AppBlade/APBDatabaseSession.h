//
//  APBDatabaseSession.h
//  AppBlade
//
//  Created by AndrewTremblay on 3/5/14.
//  Copyright (c) 2014 AppBlade Corporation. All rights reserved.
//

#import "AppBladeDatabaseObject.h"

static NSString* const kDbSessionTrackColumnNameStartedAt = @"startedSessionAt";
static NSString* const kDbSessionTrackColumnNameEndedAt   = @"endedSessionAt";
static NSString* const kDbSessionTrackColumnNameEventsHash   = @"eventsHash";
static NSString* const kDbSessionTrackColumnNameSubSessions   = @"eventsHash";

static NSString* const kDbSessionTrackColumnNameCustomParamsRef = @"customParamsId";

static NSInteger const kDbSessionTrackColumnIndexOffsetStartedAt = 1;
static NSInteger const kDbSessionTrackColumnIndexOffsetEndedAt   = 2;
static NSInteger const kDbSessionTrackColumnIndexOffsetCustomParamsRef = 3;

@interface APBDatabaseSession : AppBladeDatabaseObject

@end
