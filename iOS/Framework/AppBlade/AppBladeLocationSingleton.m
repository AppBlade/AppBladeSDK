//
//  AppBladeLocationSingleton.m
//  AppBlade
//
//  Created by AndrewTremblay on 2/18/13.
//  Copyright (c) 2013 Raizlabs Corporation. All rights reserved.
//

#import "AppBlade.h"
#import "AppBladeLocationSingleton.h"

static AppBladeLocationSingleton* sharedSingleton = nil;

@implementation AppBladeLocationSingleton
@synthesize locationManager, latestLocation, delegate;
@synthesize loggingEnabled, currentStoredLocations;
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
        self.loggingEnabled = false;
        self.currentStoredLocations = [NSMutableArray array];
	}
	return self;
}

#pragma mark - Location update lifecycle
-(void)enableLocationTracking
{
//    if([CLLocationManager locationServicesEnabled] && [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized)
//    {
        self.loggingEnabled = true;
        [[self locationManager] startMonitoringSignificantLocationChanges];
//    }else{
//        self.loggingEnabled = false;
//        NSLog(@"Location Services are not enabled for this device.");
//    }
}

-(void)disableLocationTracking
{
    self.loggingEnabled = false;
    [[self locationManager] stopMonitoringSignificantLocationChanges];
    self.currentStoredLocations = [NSMutableArray array];

}

- (void)setLocationUpdateDistance:(int)meters andTimeOut:(int)seconds
{
    if(self.loggingEnabled)
    {
        self.minUpdateDistance = [NSNumber numberWithInt:meters];
        self.minUpdateTime = [NSNumber numberWithInt:seconds];
        
        self.locationManager.distanceFilter = [self.minUpdateDistance doubleValue];
        
        [[self locationManager] startUpdatingLocation];
        
        if([CLLocationManager deferredLocationUpdatesAvailable])
        {
            [[self locationManager] allowDeferredLocationUpdatesUntilTraveled:[self.minUpdateDistance doubleValue] timeout:[self.minUpdateTime doubleValue]];
            [locationManager startMonitoringSignificantLocationChanges];

        }
    }
}

- (void)updateStoredLocations
{
    if(self.loggingEnabled)
    {
        if(nil != self.latestLocation)
        {
            NSNumber *latitude = [NSNumber numberWithDouble:self.latestLocation.coordinate.latitude];
            NSNumber *longitude = [NSNumber numberWithDouble:self.latestLocation.coordinate.longitude];
            NSNumber *timeOfLocation = [NSNumber numberWithDouble: self.latestLocation.timestamp.timeIntervalSince1970];
            
            [self.currentStoredLocations addObject:[NSArray arrayWithObjects: latitude, longitude, timeOfLocation, nil]];
        }else{
            NSLog(@"AppBlade Location not yet set, enable location loggingfor AppBlade");
        }
    }
    else
    {
        NSLog(@"AppBlade Location logging disabled, not updating stored locations");
    }
}


- (void)clearStoredLocations
{
    self.currentStoredLocations = [NSMutableArray array];
}



#pragma mark -
#pragma mark CLLocationManagerDelegate Methods
- (void)locationManager:(CLLocationManager*)manager
	didUpdateToLocation:(CLLocation*)newLocation
		   fromLocation:(CLLocation*)oldLocation
{
    if(newLocation != nil && oldLocation != nil)
    {
        NSLog(@"Location Update: %@ - %@", newLocation, oldLocation);
        if (nil == self.latestLocation)
        {
            self.latestLocation = newLocation;
        }
        else
        {
            if ((-[self.latestLocation.timestamp timeIntervalSinceNow]) > [self.minUpdateTime doubleValue])
            {
                if (!self.latestLocation || NSOrderedDescending == [oldLocation.timestamp compare:self.latestLocation.timestamp])
                {
                    self.latestLocation = oldLocation;
                }
                if (!self.latestLocation || NSOrderedDescending == [newLocation.timestamp compare:self.latestLocation.timestamp])
                {
                    self.latestLocation = newLocation;
                }
            }
        }
    }
    [self updateStoredLocations];
}


- (void)locationManager:(CLLocationManager*)manager
	   didFailWithError:(NSError*)error
{
    NSLog(@"AppBlade Location failed with error %@", [error debugDescription]);
    
}


#pragma mark Deferred Locations (iOS 6.0 and higher)
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    if(locations.count > 0)
    {
        [self locationManager:manager didUpdateToLocation:[locations objectAtIndex:0] fromLocation:[locations objectAtIndex:0]];
    }
}


- (void)locationManager:(CLLocationManager *)manager didFinishDeferredUpdatesWithError:(NSError *)error
{
    if(error)
    {
        NSLog(@"AppBlade Location finished deferred updates with error %@", [error debugDescription]);
    }
    else
    {
        NSLog(@"AppBlade Location finished deferred updates");
    }
}


@end
