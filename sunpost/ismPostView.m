//
//  ismPostView.m
//  sunpost
//
//  Created by kanade on 13/06/15.
//  Copyright (c) 2013年 kanade. All rights reserved.
//

#import "ismPostView.h"

@interface ismPostView ()

@end

@implementation ismPostView

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
		
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
	_spotLabel.text = [NSString stringWithFormat:@"Lat:%f,Lon%f",_latitude,_longitude];
	_textView.text = @"hogehoge";
	_textView.keyboardType = UIReturnKeyDone;
	
	NSDate *date = [NSDate date];
	_timeLabel.text = [date description];
	
	UIView* accessoryView =[[UIView alloc] initWithFrame:CGRectMake(0,0,320,50)];
	accessoryView.backgroundColor = [UIColor whiteColor];
	
	// ボタンを作成する。
	UIButton* closeButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	closeButton.frame = CGRectMake(210,10,100,30);
	[closeButton setTitle:@"閉じる" forState:UIControlStateNormal];
	// ボタンを押したときによばれる動作を設定する。
	[closeButton addTarget:self action:@selector(closeKeyboard:) forControlEvents:UIControlEventTouchUpInside];
	// ボタンをViewに貼る
	[accessoryView addSubview:closeButton];
	
	_textView.inputAccessoryView = accessoryView;
	
	//network
	_engine = [[ismEngine alloc]initWithHostName:@"sunpost.cyber.t.u-tokyo.ac.jp"];
	[_engine useCache];
	
	
}

-(void)viewDidAppear:(BOOL)animated{
	NSLog(@"lat:%f,lon:%f",_latitude,_longitude);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)closeKeyboard:(id)sender{
	[_textView resignFirstResponder];
}

//--Button Action ---------

- (IBAction)postButton:(id)sender {
	//TODO:アラート表示
	NSDictionary* params=@{@"label": _textView.text,
						@"user_id":[[UIDevice currentDevice].identifierForVendor UUIDString],
						@"latitude":[NSString stringWithFormat:@"%f",_latitude],
						@"longitude":[NSString stringWithFormat:@"%f",_longitude]};
	
	[_engine useApi:@"/api/post_label"
		 parameters:params
	   onCompletion:^(NSArray *resArray) {
		   NSLog(@"%@",resArray);
	   } onError:^(NSError *error) {
		   NSLog(@"error");
	   }];
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)returnButton:(id)sender {
	
	//TODO:アラート表示
	[self dismissViewControllerAnimated:YES completion:nil];
}
@end
