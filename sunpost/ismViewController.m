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
	_locMan = [[CLLocationManager alloc] init];
	
    // 位置情報サービスが利用できるかどうかをチェック
    if ([CLLocationManager locationServicesEnabled]) {
        _locMan.delegate = self; // ……【1】
        // 測位開始
		//_locMan.distanceFilter = 500; // [m]歩くたびに更新
		_locMan.distanceFilter = kCLDistanceFilterNone;
		//locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation; // 精度
		_locMan.desiredAccuracy = kCLLocationAccuracyBest; // 精度
		
        [_locMan startUpdatingLocation];
    } else {
        NSLog(@"Location services not available.");
    }
	
	
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
	
	UIBarButtonItem *calcRegion=
	[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
												  target:self
												  action:@selector(calcRegion)];
	
	UIBarButtonItem *space=
	[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
												  target:self
												  action:nil];
	

	
	NSArray *array = @[refreshButton,space,alwaysRefresh,space,calcRegion];
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
						  @"radius":@"1000"};
	
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
			   
			   annotation.regionRadius = [_regionDict[record[@"label"]] intValue];
	
			   //[_mapView addAnnotation:annotation];
		   }
		   NSLog(@"second time");
		   //_regionCalclationFlag = false;
	   } onError:^(NSError *error) {
		   NSLog(@"error!");
	   }];

}

-(void)regionCalclationWithMaxregion:(double)maxRegion resDict:(NSDictionary*)resDict{
	int regionRadius = maxRegion; // region_max
	
		NSLog(@"regionrad:%d",[resDict[@"distance"] intValue]);
		while (regionRadius > [resDict[@"distance"] doubleValue]) {
			regionRadius -= 10;
		}
		NSLog(@"targetRegion:%d",regionRadius);
		
		//annotation.regionRadius = regionRadius;
		[_regionDict setObject:[NSNumber numberWithInt:regionRadius] forKey:resDict[@"id"]];
		
		//NSLog(@"will regist region");
	/*
		[self registerRegion:CLLocationCoordinate2DMake(
					  radius:(double)regionRadius
				  identifier:[NSString stringWithFormat:@"%@",resDict[@"id"]]];
	*/
	
	CLLocationCoordinate2D location = CLLocationCoordinate2DMake([resDict[@"latitude"]	floatValue],
																 [resDict[@"longitude"] floatValue]);
	 
	
	// 半径、キー文字列をもとにオブジェクトを生成
	CLRegion *region = [[CLRegion alloc] initCircularRegionWithCenter:location
															   radius:regionRadius
														   identifier:[NSString stringWithFormat:@"%@",resDict[@"id"]]];
	// サービスの開始
	[_locMan setDesiredAccuracy:kCLLocationAccuracyBest];
	[_locMan startMonitoringForRegion:region];// desiredAccuracy:kCLLocationAccuracyBest];
	// 不要なものを解放
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
	[_locMan startMonitoringForRegion:region
							  desiredAccuracy:kCLLocationAccuracyBest];
	NSLog(@"here5");
	
}

// 領域観測の登録に失敗した場合
- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error
{
    // ここで任意の処理
    NSLog(@"register failed | %@, %@", region, error);
}


-(void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region{
	NSLog(@"you find letter!");
	
	// アラートを表示する
    UIAlertView*    alertView;
	NSString* message = [NSString stringWithFormat:@"%f[m]以内に手紙があります．in",region.radius];
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
	
	[_locMan startMonitoringForRegion:newRegion];
	}
}

-(void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region{
	
	// アラートを表示する
	//*
    UIAlertView*    alertView;
	NSString* message = [NSString stringWithFormat:@"%f[m]以内に手紙があります．out",region.radius];
    alertView = [[UIAlertView alloc] initWithTitle:@"Attention!"
										   message:message
										  delegate:nil
								 cancelButtonTitle:@"OK"
								 otherButtonTitles:NULL];
	[alertView show];
	//*/
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
	//[_locMan stopUpdatingLocation];
	//[_locMan startUpdatingLocation];
	
}

-(void)calcRegion{
	//周囲のコメントよみこみ
	NSDictionary* params = @{@"latitude":[NSString stringWithFormat:@"%f",_tmpLatitude],
						  @"longitude":[NSString stringWithFormat:@"%f",_tmpLongitude],
						  @"radius":@"1000"};
	
	[_engine useApi:@"/api/region_labels"
		 parameters:params
	   onCompletion:^(NSArray *resArray) {
		   double minLen=10000.0;
		   int minIndex = -1;;
		   
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
			   if (minLen > annotation.distantFromUser) {
				   minLen = annotation.distantFromUser;
				   minIndex = i;
			   }
			   //[self regionCalclationWithMaxregion:100 resDict:record];
			   
			   annotation.regionRadius = [_regionDict[record[@"id"]] intValue];
			   
			   [_mapView addAnnotation:annotation];
		   }
		   [self regionCalclationWithMaxregion:1000 resDict:resArray[minIndex]];
		  // NSLog(@"%",(ismAnnotation*)([_mapView annotations][minIndex]).title);
		   //NSLog(@"second time");
		   //_regionCalclationFlag = false;
	   } onError:^(NSError *error) {
		   NSLog(@"error!");
	   }];
	

}


@end
