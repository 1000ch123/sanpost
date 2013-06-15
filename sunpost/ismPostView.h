//
//  ismPostView.h
//  sunpost
//
//  Created by kanade on 13/06/15.
//  Copyright (c) 2013年 kanade. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ismEngine.h"

@interface ismPostView : UIViewController

@property double latitude;
@property double longitude;

@property (nonatomic,strong) ismEngine *engine;

@property (weak, nonatomic) IBOutlet UILabel *spotLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UITextView *textView;

- (IBAction)postButton:(id)sender;
- (IBAction)returnButton:(id)sender;

@end
