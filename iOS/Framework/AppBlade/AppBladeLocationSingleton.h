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


@property (nonatomic, strong) CLLocationManager* locationManager;
@property (nonatomic, strong) CLLocation* location;
@property (nonatomic, weak) id  delegate;


@end

