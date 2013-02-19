//
//  AppBladeLocationSingleton.m
//  AppBlade
//
//  Created by AndrewTremblay on 2/18/13.
//  Copyright (c) 2013 Raizlabs Corporation. All rights reserved.
//

#import "AppBladeLocationSingleton.h"

static AppBladeLocationSingleton* sharedSingleton = nil;

@implementation AppBladeLocationSingleton
@synthesize locationManager, location, delegate;
#pragma mark Singleton Object Methods
+ (AppBladeLocationSingleton*)sharedInstance {
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
    sharedSingleton = [[self alloc] init];
    });
    return sharedSingleton;
}

#pragma mark -
#pragma mark Memory Lifecycle

- (id)init
{
 	self = [super init];
	if (self != nil) {
		self.locationManager = [[CLLocationManager alloc] init];
		self.locationManager.delegate = self;
		self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
	}
	return self;
}

-(void) dealloc
{
    [super dealloc];
}


#pragma mark -
#pragma mark CLLocationManagerDelegate Methods
- (void)locationManager:(CLLocationManager*)manager
	didUpdateToLocation:(CLLocation*)newLocation
		   fromLocation:(CLLocation*)oldLocation
{
    NSLog(@"AppBlade Location did update to %@ ", [newLocation debugDescription]);
}

- (void)locationManager:(CLLocationManager*)manager
	   didFailWithError:(NSError*)error
{
    NSLog(@"AppBlade Location failed with error %@", [error debugDescription]);
    
}


@end
