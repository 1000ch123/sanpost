//
//  ismAnnotationView.m
//  sunpost
//
//  Created by kanade on 13/06/16.
//  Copyright (c) 2013年 kanade. All rights reserved.
//

#import "ismAnnotationView.h"

@implementation ismAnnotationView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
		self.image = [UIImage imageNamed:@"letter.jpeg"];
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
