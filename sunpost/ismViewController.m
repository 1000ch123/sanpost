//
//  ismViewController.m
//  sunpost
//
//  Created by kanade on 13/06/15.
//  Copyright (c) 2013年 kanade. All rights reserved.
//

#import "ismViewController.h"
#import "ismPostView.h"
#import "ismAnnotation.h"

@interface ismViewController ()

@end

@implementation ismViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
	
	
	
	//
	// location navigator
	//
	//現在地取得のための
	locationManager = [[CLLocationManager alloc] init];
	
    // 位置情報サービスが利用できるかどうかをチェック
    if ([CLLocationManager locationServicesEnabled]) {
        locationManager.delegate = self; // ……【1】
        // 測位開始
		locationManager.distanceFilter = 5; // [m]歩くたびに更新
		locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation; // 精度
		
        [locationManager startUpdatingLocation];
    } else {
        NSLog(@"Location services not available.");
    }
	locationManager.delegate = self;
	
	//
	// mapkit
	//
	// 画面全体に表示
    _mapView = [[MKMapView alloc] initWithFrame:CGRectMake(0, 0, 320, 480)];
    [self.view addSubview:_mapView];
	_mapView.delegate = self;
    
    // ユーザの現在位置を表示
    _mapView.showsUserLocation = YES;

    // 地図の種類をハイブリッドにする
    _mapView.mapType = MKMapTypeStandard;
	
	//拡大率だけ設定しておく
	MKCoordinateRegion region = MKCoordinateRegionMake(_mapView.centerCoordinate, MKCoordinateSpanMake(0.05, 0.05));
    [_mapView setRegion:region];
	
	
    // デバイスの向きに合わせて地図を回転(headingのことっぽい)
    [_mapView setUserTrackingMode:MKUserTrackingModeNone animated:YES];
	
	_regionCalclationFlag = true;
	
	_regionDict = [[NSMutableDictionary alloc] init];
	
	//アノテーションテスト
	ismAnnotation* annotation = [[ismAnnotation alloc]
								 initWithLocationCoordinate:CLLocationCoordinate2DMake(35.681666, 139.764869)
																			title:@"HiroseTanikawa"
																		 subtitle:@"絶賛ハッカソン！"];
	[_mapView addAnnotation:annotation];
	
	//network
	_engine = [[ismEngine alloc]initWithHostName:@"sunpost.cyber.t.u-tokyo.ac.jp"];
	[_engine useCache];
	

	
	//ナビゲーションアイテム関連
	self.navigationItem.title = @"SunPost";
	UIBarButtonItem *postButton =
	[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
												  target:self
												  action:@selector(commentPost)];
	self.navigationItem.rightBarButtonItem = postButton;
	
	
	//ツールバーアイテム関連
	self.navigationController.toolbarHidden = false;
	UIBarButtonItem *refreshButton =
	[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
												  target:self
												  action:@selector(refreshGPS)];
	
	UIBarButtonItem *alwaysRefresh=
	[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay
												  target:self
												  action:@selector(alwaysRefreshSwitch)];
	NSArray *array = @[refreshButton,alwaysRefresh];
	[self setToolbarItems:array animated:YES];
	
	//UIID
	//NSString* string = [[UIDevice currentDevice].identifierForVendor UUIDString];
}

-(void)viewWillAppear:(BOOL)animated{
	[self refreshGPS];
}

-(void)updateLabels{
	NSDictionary* params = @{@"latitude":[NSString stringWithFormat:@"%f",_tmpLatitude],
						  @"longitude":[NSString stringWithFormat:@"%f",_tmpLongitude],
						  @"radius":@"10000"};
	
	[_engine useApi:@"/api/region_labels"
		 parameters:params
	   onCompletion:^(NSArray *resArray) {
		   
		   // NSLog(@"%@",resArray);
		   int regionRadius;
		   //for (NSDictionary *record in resArray) {
		   for (int i=0; i<[resArray count]; i++) {
			 
			   NSDictionary* record = resArray[i];
			   ismAnnotation* annotation = [[ismAnnotation alloc]
											initWithLocationCoordinate:CLLocationCoordinate2DMake(
																								  [record[@"latitude"] doubleValue],
																								  [record[@"longitude"] doubleValue])
											title:record[@"label"]
											subtitle:record[@"time"]];
			   
			   //TODO 初期登録半径計算．distance値を利用
			   
			   annotation.distantFromUser = [record[@"distance"] doubleValue];
			   
			   
			   if (_regionCalclationFlag) {
				   regionRadius = 10000; // region_max
				   NSLog(@"regionrad:%d",[record[@"distance"] intValue]);
				   while (regionRadius > annotation.distantFromUser) {
					   regionRadius -= 10;
				   }
				   NSLog(@"targetRegion:%d",regionRadius);
			
				   annotation.regionRadius = regionRadius;
				   [_regionDict setObject:[NSNumber numberWithInt:regionRadius] forKey:record[@"label"]];
				   
				   //NSLog(@"will regist region");
				   [self registerRegion:annotation.coordinate
								 radius:(double)regionRadius
							 identifier:[NSString stringWithFormat:@"%@",record[@"id"]]];
				   
			   }else{
				   annotation.regionRadius = [_regionDict[record[@"label"]] intValue];
			   }
			   
			   [_mapView addAnnotation:annotation];
		   }
		   NSLog(@"second time");
		   _regionCalclationFlag = false;
	   } onError:^(NSError *error) {
		   NSLog(@"error!");
	   }];

}


-(void)registerRegion:(CLLocationCoordinate2D)coordinate radius:(double)rad identifier:(NSString*)identifier
{
	//　作成可能かチェック
	NSLog(@"here1");
	if ( ![CLLocationManager regionMonitoringAvailable] ||
		![CLLocationManager regionMonitoringEnabled] )
		return;
	
	NSLog(@"here2");
	// 半径を最大値に固定
	//if (rad > locationManager.maximumRegionMonitoringDistance)rad = locationManager.maximumRegionMonitoringDistance;
	
	NSLog(@"here3");
	// 領域を作成し観測を開始する
	NSLog(@"coordinate:%f %f rad:%f identifier:%@",coordinate.latitude,coordinate.longitude,rad,identifier);
	CLRegion* region = [[CLRegion alloc]
						initCircularRegionWithCenter:coordinate
						radius:(CLLocationDistance)rad
						identifier:identifier];
	NSLog(@"here4");
	[locationManager startMonitoringForRegion:region
							  desiredAccuracy:kCLLocationAccuracyHundredMeters];
	NSLog(@"here5");
	
}


-(void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region{
	NSLog(@"you find letter!");
	
	// アラートを表示する
    UIAlertView*    alertView;
	NSString* message = [NSString stringWithFormat:@"%f[m]以内に手紙があります．",region.radius];
    alertView = [[UIAlertView alloc] initWithTitle:@"Attention!"
										   message:message
										  delegate:nil
								 cancelButtonTitle:@"OK"
								 otherButtonTitles:NULL];
	[alertView show];
	
	
	//リージョンの再定義
	if(region.radius > 10){
	CLRegion *newRegion = [[CLRegion alloc] initCircularRegionWithCenter:region.center
																  radius:region.radius - 10.0
															  identifier:region.identifier];
	
	[locationManager startMonitoringForRegion:newRegion];
	}
}


// 位置情報更新時
- (void)locationManager:(CLLocationManager *)manager
	didUpdateToLocation:(CLLocation *)newLocation
		   fromLocation:(CLLocation *)oldLocation {
	
    //緯度・経度を出力
    NSLog(@"didUpdateToLocation latitude=%f, longitude=%f",
		  [newLocation coordinate].latitude,
		  [newLocation coordinate].longitude);
	
	//位置情報アップデート
	/*
	MKCoordinateRegion tmpRegion = _mapView.region;
	
	MKCoordinateRegion region = MKCoordinateRegionMake([newLocation coordinate], MKCoordinateSpanMake(0.5, 0.5));
    [_mapView setCenterCoordinate:[newLocation coordinate]];
    [_mapView setRegion:region];
	 */
	_mapView.centerCoordinate = [newLocation coordinate];
	_tmpLatitude = [newLocation coordinate].latitude;
	_tmpLongitude = [newLocation coordinate].longitude;
	
	[self updateLabels];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



// mapView_delegate
/*
-(MKAnnotationView*)mapView:(MKMapView*)mapView
		  viewForAnnotation:(id <MKAnnotation>)annotation {
	
    if (annotation == mapView.userLocation) { //……【2】
        return nil;
    } else {
        CustomAnnotationView *annotationView;
        NSString* identifier = @"flag"; // 再利用時の識別子
		
        // 再利用可能な MKAnnotationView を取得
        annotationView = (CustomAnnotationView*)[mapView dequeueReusableAnnotationViewWithIdentifier:identifier];
		
        if(nil == annotationView) {
            //再利用可能な MKAnnotationView がなければ新規作成
            annotationView = [[[CustomAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:identifier] autorelease];
        }
        annotationView.annotation = annotation;
        return annotationView;
    }
}*/


- (void)mapView:(MKMapView*)mapView didAddAnnotationViews:(NSArray*)views
{
    // アノテーションビューを取得する
	//NSLog(@"get anotation view");
    for (MKAnnotationView* annotationView in views) {
        // アノテーションがismAnnotationの場合
        if ([annotationView.annotation isKindOfClass:[ismAnnotation class]]) {
            // ボタンを作成する
			//NSLog(@"class:ismAnnotation");
            UIButton*   button;
            button = [UIButton buttonWithType:UIButtonTypeInfoLight];
			
            // コールアウトのアクセサリビューを設定する
            annotationView.rightCalloutAccessoryView = button;
        }
    }
}

- (void)mapView:(MKMapView*)mapView
 annotationView:(MKAnnotationView*)view
calloutAccessoryControlTapped:(UIControl*)control
{
	NSLog(@"call alert");
   
    // メッセージを作成する
    NSMutableString*    message;
	//message = ((ismAnnotation*)view.annotation).title;
	
   // message = @"hogehoge";
	//message = view
   
	// アラートを表示する
    UIAlertView*    alertView;
    alertView = [[UIAlertView alloc] initWithTitle:((ismAnnotation*)view.annotation).title
										   message:[NSString stringWithFormat:@"distant from %f /n region rad: %f",((ismAnnotation*)view.annotation).distantFromUser,((ismAnnotation*)view.annotation).regionRadius]
										  delegate:nil
								 cancelButtonTitle:@"OK"
								 otherButtonTitles:NULL];
   // [alertView autorelease];
    [alertView show];
}

//システムボタン
-(void)commentPost{
	NSLog(@"post button pushed");
	ismPostView *postView = [[ismPostView alloc]init];
	NSLog(@"lat:%f",_mapView.centerCoordinate.latitude);
	postView.latitude = _mapView.centerCoordinate.latitude;
	postView.longitude = _mapView.centerCoordinate.longitude;
	[self presentViewController:postView
					   animated:YES
					 completion:nil];
}

-(void)alwaysRefreshSwitch{
	NSLog(@"always button pushed");
	//[_mapView setUserTrackingMode:MKUserTrackingModeFollowWithHeading animated:YES];
	if (!_autoDirectionFlag) {
		[_mapView setUserTrackingMode:MKUserTrackingModeFollowWithHeading animated:YES];
	}else{
		[_mapView setUserTrackingMode:MKUserTrackingModeNone animated:YES];
	}
	_autoDirectionFlag = !_autoDirectionFlag;
}

-(void)refreshGPS{
	NSLog(@"refresh button pushed");
	[locationManager stopUpdatingLocation];
	[locationManager startUpdatingLocation];
	
}



@end
