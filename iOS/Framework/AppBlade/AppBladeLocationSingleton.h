//
//  AppBladeLocationSingleton.h
//  AppBlade
//
//  Created by AndrewTremblay on 2/18/13.
//  Copyright (c) 2013 Raizlabs Corporation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@protocol AppBladeLocationControllerDelegate
@required
- (void)locationUpdate:(CLLocation*)location;
@end
// protocol for sending location updates to another view controller

@interface AppBladeLocationSingleton : NSObject<CLLocationManagerDelegate>  {
	CLLocationManager* locationManager;
	CLLocation* location;
	__weak id delegate;
}

+ (AppBladeLocationSingleton*)sharedInstance; // Singleton method

@property (nonatomic, weak) id  delegate;
@property (nonatomic, strong) CLLocationManager* locationManager;
@property (nonatomic, strong) CLLocation* latestLocation;
@property (nonatomic, strong) NSMutableArray* currentStoredLocations;


-(void)enableLocationTracking;
-(void)disableLocationTracking;


@property (nonatomic, assign) bool loggingEnabled;
- (void)setLocationUpdateDistance:(int)meters andTimeOut:(int)seconds;
- (void)updateStoredLocations;
- (void)clearStoredLocations;

@property (nonatomic, strong) NSNumber* minUpdateDistance;
@property (nonatomic, strong) NSNumber* minUpdateTime;



@end

