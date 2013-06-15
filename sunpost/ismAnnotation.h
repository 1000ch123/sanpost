//
//  ismAnnotation.h
//  sunpost
//
//  Created by kanade on 13/06/15.
//  Copyright (c) 2013年 kanade. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface ismAnnotation : NSObject<MKAnnotation>{
    CLLocationCoordinate2D coordinate;
    NSString *annotationTitle;
    NSString *annotationSubtitle;
}

	@property double distantFromUser;
@property double regionRadius;

	@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;
	@property (nonatomic, retain) NSString *annotationTitle;
	@property (nonatomic, retain) NSString *annotationSubtitle;
	- (id)initWithLocationCoordinate:(CLLocationCoordinate2D) coordinate
title:(NSString *)annotationTitle subtitle:(NSString *)annotationannSubtitle;
	- (NSString *)title;
	- (NSString *)subtitle;
@end
