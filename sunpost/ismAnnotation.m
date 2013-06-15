//
//  ismAnnotation.m
//  sunpost
//
//  Created by kanade on 13/06/15.
//  Copyright (c) 2013年 kanade. All rights reserved.
//

#import "ismAnnotation.h"

@implementation ismAnnotation

- (NSString *)title {
    return _annotationTitle;
}

- (NSString *)subtitle {
    return _annotationSubtitle;
}

- (id)initWithLocationCoordinate:(CLLocationCoordinate2D) coordinate
						   title:(NSString *)annotationTitle
						subtitle:(NSString *)annotationSubtitle
{
    _coordinate = coordinate;
    self.annotationTitle = annotationTitle;
    self.annotationSubtitle = annotationSubtitle;
    return self;
}

@end
