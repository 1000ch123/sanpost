//
//  ismViewController.h
//  sunpost
//
//  Created by kanade on 13/06/15.
//  Copyright (c) 2013年 kanade. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ismEngine.h"

@interface ismViewController : UIViewController<CLLocationManagerDelegate,MKMapViewDelegate>{
	CLLocationManager *locationManager;
}

@property CLLocationManager *locMan;
@property MKMapView *mapView;
@property (nonatomic,strong) ismEngine *engine;
@property BOOL autoDirectionFlag;
@property BOOL regionCalclationFlag;


@property NSMutableDictionary *regionDict;
@property double tmpLatitude;
@property double tmpLongitude;

-(void)updateLabels;
-(void)registerRegionCenter:(CLLocationCoordinate2D)coordinate radius:(double)rad identifier:(NSString*)identifier;

@end
