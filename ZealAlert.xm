#import "ZealAlert.h"
#import "Zeal.h"
#import <sys/utsname.h>

@implementation ZealAlert

@synthesize animate = _animate;
@synthesize userInteraction = _userInteraction;

+ (id)sharedManager {
    static ZealAlert *zAlert = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        zAlert = [[self alloc] init];
    });
    return zAlert;
}

- (id)initWithData:(NSDictionary *)data andOrientation:(UIInterfaceOrientation)orientation{
	if (self = [super init]) {

		if(data) {
			dict = data;
		}

		struct utsname systemInfo;
    	uname(&systemInfo);
    	NSString *result = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];

    	//The most popular devices are now 4.7 inch and bigger 
    	kAlertWidth = 300;
		kAlertFontSize = 12;
		kAlertTextSpacing = 170;

		//support for 4 inch devices (iPhone 5-5S-5C-SE and iPodtouch 5-6) 
    	if ([result isEqualToString:@"iPod5,1"] || [result isEqualToString:@"iPod7,1"] || [result isEqualToString:@"iPhone8,4"] || [result isEqualToString:@"iPhone5,1"] || [result isEqualToString:@"iPhone5,2"] || [result isEqualToString:@"iPhone5,3"] || [result isEqualToString:@"iPhone5,4"] || [result isEqualToString:@"iPhone6,1"] || [result isEqualToString:@"iPhone6,2"]) {
    		kAlertWidth = 275;
			kAlertFontSize = 11;
			kAlertTextSpacing = 155;
		}

		[self _calculateRender];

		//Drak mode option
		darkMode = [[dict objectForKey:@"darkMode"] boolValue];

		//Number of apps per page
		appsPerRow = [[dict objectForKey:@"appsPerRow"] intValue];

		//Main Window
		zealWindow = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, screenWidth, screenHeight)];
		zealWindow.windowLevel = UIWindowLevelStatusBar + 100;
		zealWindow.backgroundColor = [UIColor clearColor];
		[zealWindow setUserInteractionEnabled:YES];
		[zealWindow makeKeyAndVisible];
		zealWindow.hidden = YES;

		//Dimmed background view
		backgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screenWidth * 2, screenHeight * 2)];
		backgroundView.center = zealWindow.center;
		backgroundView.alpha = 0.35;
		backgroundView.backgroundColor = [UIColor blackColor];
		backgroundView.autoresizingMask =  UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
		[backgroundView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_hideAlert)]];
		[zealWindow addSubview:backgroundView];

		//Main alert view
		alertView = [[UIView alloc] initWithFrame:CGRectMake(0,0,kAlertWidth,250)];
		alertView.center = backgroundView.center;
		alertFrame = alertView.frame;
		alertView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
		[[alertView layer] setCornerRadius:20.0f];
		[[alertView layer] setMasksToBounds:YES];
		[zealWindow addSubview:alertView];
		
		//Adding blurr
		_UIBackdropView *blurView = [[_UIBackdropView alloc] initWithFrame:CGRectZero autosizesToFitSuperview:YES settings:[[_UIBackdropViewSettings alloc] initWithDefaultValues]];
		[blurView transitionToPrivateStyle:2010];
		[alertView addSubview:blurView];

		//Alert icon
		alertIcon = [[UIImageView alloc] initWithFrame:CGRectMake(15,15,30,30)];
		alertIcon.image = [UIImage imageWithContentsOfFile:@"/Library/Application Support/Zeal/battery.png"];
		[alertView addSubview:alertIcon];

		//Alert title
		titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(55, 15, 200, 15)];
		titleLabel.text = dict[@"alertTitle"];
		titleLabel.font = [UIFont boldSystemFontOfSize:kAlertFontSize+2];
		titleLabel.numberOfLines = 1;
		[alertView addSubview:titleLabel];

		//Alert message
		messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(55, 30, 200, 15)];
		messageLabel.font = [UIFont systemFontOfSize:kAlertFontSize];
		messageLabel.numberOfLines = 1;
		messageLabel.text = dict[@"alertMessage"];
		[alertView addSubview:messageLabel];

		//Charging icon
		bolt = [[UIImageView alloc] initWithFrame:CGRectMake(kAlertWidth - 40,20,20,20)];
		bolt.image = [UIImage imageWithContentsOfFile:@"/Library/Application Support/Zeal/bolt.png"];;
		bolt.image = [bolt.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
		[bolt setHidden:![dict[@"isCharging"] boolValue]];
		[bolt setTintColor:([powerSaver getPowerMode] == 1) ? [UIColor yellowColor] : [UIColor greenColor]];
		[alertView addSubview:bolt];

		//Power saving button
		powerSavingButton = [UIButton buttonWithType:UIButtonTypeCustom];
		powerSavingButton.frame = CGRectMake(15, 60, kAlertWidth - 30, 30);
		powerSavingButton.backgroundColor = darkMode ? RGBA(196,196,196,0.5) : RGBA(191,191,191,0.5);
		powerSavingButton.layer.cornerRadius = 5.0;
		[powerSavingButton setTitle:([powerSaver getPowerMode] == 1) ? @"Deactivate battery saving mode" : @"Activate battery saving mode" forState:UIControlStateNormal];
		[powerSavingButton addTarget:self action:@selector(powerSavingMode) forControlEvents:UIControlEventTouchUpInside];
		[powerSavingButton setTitleColor:( darkMode ? [UIColor whiteColor] : [UIColor blackColor]) forState:UIControlStateNormal];
		[powerSavingButton.titleLabel setFont:[UIFont systemFontOfSize:kAlertFontSize+4]];
		[powerSavingButton setClipsToBounds:YES];
		[alertView addSubview:powerSavingButton];

		//Line seperator 1
		lineView = [[UIView alloc] initWithFrame:CGRectMake(0, 105, kAlertWidth, 0.5)];
		lineView.backgroundColor = darkMode ? [UIColor whiteColor] : [UIColor blackColor];
		lineView.alpha = darkMode ? 0.25 : 0.4;
		[alertView addSubview:lineView];

		//Low brightness icon
		lowBright = [[UIImageView alloc] initWithFrame:CGRectMake(5,115,20,20)];
		lowBright.image = [[UIImage imageWithContentsOfFile:@"/Library/Application Support/Zeal/lowBright.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
		[lowBright setTintColor:( darkMode ? [UIColor whiteColor] : [UIColor blackColor])];
		lowBright.alpha = darkMode ? 1.0 : 0.85;
		[alertView addSubview:lowBright];

		//Brightness slider
		brightnessSlider = [[UISlider alloc] initWithFrame:CGRectMake(30, 105, kAlertWidth - 60, 40)];
		brightnessSlider.value = [UIScreen mainScreen].brightness;
		brightnessSlider.minimumValue = 0.0;
		brightnessSlider.maximumValue = 0.99;
		brightnessSlider.tintColor = [UIColor grayColor];
		[brightnessSlider addTarget:self action:@selector(adjustBrightness:) forControlEvents:UIControlEventValueChanged];
		[alertView addSubview:brightnessSlider];

		//Max brightness icon
		highBright = [[UIImageView alloc] initWithFrame:CGRectMake(kAlertWidth - 25,115,20,20)];
		highBright.image = [[UIImage imageWithContentsOfFile:@"/Library/Application Support/Zeal/highBright.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
		[highBright setTintColor:( darkMode ? [UIColor whiteColor] : [UIColor blackColor])];
		highBright.alpha = darkMode ? 1.0 : 0.85;
		[alertView addSubview:highBright];

		//Line seperator 2
		lineView2 = [[UIView alloc] initWithFrame:CGRectMake(0, 145, kAlertWidth, 0.5)];
		lineView2.backgroundColor = darkMode ? [UIColor whiteColor] : [UIColor blackColor];
		lineView2.alpha = darkMode ? 0.25 : 0.4;
		[alertView addSubview:lineView2];

		//Flip Switch buttons
		NSBundle *templateBundle = nil;
		NSArray *enabledSwitchesArray = [[NSDictionary dictionaryWithContentsOfFile:kSettingsPath] objectForKey:@"EnabledIdentifiers"];

		if (enabledSwitchesArray == nil || [enabledSwitchesArray count] == 0) {
			enabledSwitchesArray = [NSArray arrayWithObjects:@"com.a3tweaks.switch.airplane-mode", @"com.a3tweaks.switch.wifi", @"com.a3tweaks.switch.bluetooth", @"com.a3tweaks.switch.do-not-disturb", @"com.a3tweaks.switch.rotation-lock", nil];
		}

		if (darkMode){
			templateBundle = [NSBundle bundleWithPath:@"/Library/Application Support/Zeal/ZealFSDark.bundle"];
		}else{
			templateBundle = [NSBundle bundleWithPath:@"/Library/Application Support/Zeal/ZealFSLight.bundle"];
		}

		FSSwitchPanel *flipSwitchPanel = [FSSwitchPanel sharedPanel];

		if ([enabledSwitchesArray count] > 0){
			//Flip Switch scroll view + buttons
			flipSwitchScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 150, kAlertWidth, 60)];
			flipSwitchScrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
			flipSwitchScrollView.pagingEnabled = YES;
			flipSwitchScrollView.scrollsToTop = NO;
			flipSwitchScrollView.showsHorizontalScrollIndicator=NO;
			flipSwitchScrollView.showsVerticalScrollIndicator=NO;

			int i = 1;
			for(NSString *identifier in enabledSwitchesArray) {
				UIButton *flipSwitchButton = [flipSwitchPanel buttonForSwitchIdentifier:identifier usingTemplate:templateBundle];
				flipSwitchButton.frame = CGRectMake(calculateXPositionForAppNumber(i,kAlertWidth,appsPerRow), (flipSwitchScrollView.frame.size.height-AppIconSize)/2, AppIconSize, AppIconSize);
				[flipSwitchScrollView addSubview:flipSwitchButton];
				i++;
			}

			flipSwitchScrollView.contentSize = CGSizeMake( ceil(enabledSwitchesArray.count/(appsPerRow*1.0))*kAlertWidth, flipSwitchScrollView.frame.size.height);
			[alertView addSubview:flipSwitchScrollView];
		}

		//Line seperator 3
		lineView3 = [[UIView alloc] initWithFrame:CGRectMake(0, 215, kAlertWidth, 0.5)];
		lineView3.backgroundColor = darkMode ? [UIColor whiteColor] : [UIColor blackColor];
		lineView3.alpha = darkMode ? 0.25 : 0.4;
		[alertView addSubview:lineView3];

		//Current amperage
		currentAmps = [[UILabel alloc] initWithFrame:CGRectMake(5, 220, kAlertTextSpacing, 20)];
		currentAmps.font = [UIFont systemFontOfSize:kAlertFontSize];
		currentAmps.textColor = darkMode ? [UIColor whiteColor] : [UIColor blackColor];
		currentAmps.text = dict[@"currentCapacity"];
		[currentAmps boldSubstring: @"Current Capacity:"];
		[alertView addSubview:currentAmps];

		//Max amperage
		maxAmps = [[UILabel alloc] initWithFrame:CGRectMake(5, 240, kAlertTextSpacing, 20)];
		maxAmps.font = [UIFont systemFontOfSize:kAlertFontSize];
		maxAmps.textColor = darkMode ? [UIColor whiteColor] : [UIColor blackColor];
		maxAmps.text = dict[@"maxCapacity"];
		[maxAmps boldSubstring: @"Max Capacity:"];
		[alertView addSubview:maxAmps];

		//Designed capacity
		designAmps = [[UILabel alloc] initWithFrame:CGRectMake(5, 260, kAlertTextSpacing, 20)];
		designAmps.font = [UIFont systemFontOfSize:kAlertFontSize];
		designAmps.textColor = darkMode ? [UIColor whiteColor] : [UIColor blackColor];
		designAmps.text = dict[@"designCapacity"];
		[designAmps boldSubstring: @"Design Capacity:"];
		[alertView addSubview:designAmps];

		//Battery temperature
		temprature = [[UILabel alloc] initWithFrame:CGRectMake(kAlertTextSpacing+5, 220, 140, 20)];
		temprature.font = [UIFont systemFontOfSize:kAlertFontSize];
		temprature.textColor = darkMode ? [UIColor whiteColor] : [UIColor blackColor];
		temprature.text = dict[@"temprature"];
		[temprature boldSubstring: @"Temperature:"];
		[alertView addSubview:temprature];

		//Number of cycles
		cycles = [[UILabel alloc] initWithFrame:CGRectMake(kAlertTextSpacing+5, 240, 140, 20)];
		cycles.font = [UIFont systemFontOfSize:kAlertFontSize];
		cycles.textColor = darkMode ? [UIColor whiteColor] : [UIColor blackColor];
		cycles.text = dict[@"cycleCount"];
		[cycles boldSubstring: @"Cycles:"];
		[alertView addSubview:cycles];

		//Wear level
		wearLevel = [[UILabel alloc] initWithFrame:CGRectMake(kAlertTextSpacing+5, 260, 140, 20)];
		wearLevel.font = [UIFont systemFontOfSize:kAlertFontSize];
		wearLevel.textColor = darkMode ? [UIColor whiteColor] : [UIColor blackColor];
		wearLevel.text = dict[@"wearLevel"];
		[wearLevel boldSubstring: @"Wear Level:"];
		[alertView addSubview:wearLevel];

		//Line seperator 4
		lineView4 = [[UIView alloc] initWithFrame:CGRectMake(0, 215, kAlertWidth, 0.5)];
		lineView4.backgroundColor = darkMode ? [UIColor whiteColor] : [UIColor blackColor];
		lineView4.alpha = darkMode ? 0.25 : 0.4;
		[alertView addSubview:lineView4];

		//Swipe/Close view
		swiper = [[UIView alloc] initWithFrame:CGRectMake(0,220,kAlertWidth,30)];
		[alertView addSubview:swiper];

		//Swipe gesture
		UIPanGestureRecognizer *swipeGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(swipeGesture:)];
		swipeGesture.maximumNumberOfTouches = swipeGesture.minimumNumberOfTouches = 1;
		[swiper addGestureRecognizer:swipeGesture];

		//Tap gesture
		UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_hideAlert)];
		[swiper addGestureRecognizer:tapGesture];

		//Grabber view
		if([[[UIDevice currentDevice] systemVersion] floatValue] >= 10.0){//iOS 10 Chevron View
			grabber = [[NSClassFromString(@"SBUIChevronView") alloc] initWithFrame:CGRectMake((kAlertWidth - 36)/2, 10, 36, 10)];
			[(SBUIChevronView *)grabber setState:0 animated:NO];
		}else{ //iOS8-9 Chevron View
			grabber = [[NSClassFromString(@"SBChevronView") alloc] initWithFrame:CGRectMake((kAlertWidth - 36)/2, 10, 36, 10)];
			[(SBChevronView *)grabber setState:0 animated:NO];
		}

		grabber.transform = CGAffineTransformMakeRotation(M_PI);
		grabber.alpha = darkMode ? 0.5 : 0.75;
		[grabber setUserInteractionEnabled:NO];
		[swiper addSubview:grabber];

		if(darkMode){
			messageLabel.textColor = [UIColor whiteColor];
			titleLabel.textColor = [UIColor whiteColor];
			//alertView.backgroundColor = RGBA(40,40,40,0.93);
			[blurView transitionToPrivateStyle:2030];

			if([[[UIDevice currentDevice] systemVersion] floatValue] >= 10.0){
				[(SBUIChevronView *)grabber setColor:[UIColor whiteColor]];
			}else{
				[(SBChevronView *)grabber setColor:[UIColor whiteColor]];
			}
		}else{
			messageLabel.textColor = [UIColor blackColor];
			titleLabel.textColor = [UIColor blackColor];
			alertView.backgroundColor = RGBA(245,245,245,0.975);

			if([[[UIDevice currentDevice] systemVersion] floatValue] >= 10.0){
				[(SBUIChevronView *)grabber setColor:[UIColor blackColor]];
			}else{
				[(SBChevronView *)grabber setColor:[UIColor blackColor]];
			}
		}

		//Animation stuff
		backgroundView.transform = CGAffineTransformMakeScale(1.1, 1.1);
		alertView.transform = CGAffineTransformMakeScale(1.1, 1.1);
		zealWindow.alpha = 0.0;
		currentAmps.alpha = 0.0;
		maxAmps.alpha = 0.0;
		temprature.alpha = 0.0;
		cycles.alpha = 0.0;
		lineView4.alpha = 0.0;
		designAmps.alpha = 0.0;
		wearLevel.alpha = 0.0;

		alertView.backgroundColor = [UIColor clearColor];

		//Fix orientation!!!
		[self adjustViewForOrientation:orientation animated:NO];

	}
	return self;
}

-(void)adjustViewForOrientation:(UIInterfaceOrientation)orientation animated:(BOOL)animateOrient {
	CGAffineTransform transform;
	CGRect bounds = zealWindow.bounds;

	switch (orientation) {
		case UIInterfaceOrientationPortraitUpsideDown:
		{
			transform = CGAffineTransformMakeRotation(M_PI);
			bounds.size.width = screenWidth;
		} break;

		case UIInterfaceOrientationLandscapeLeft:
		{
			transform = CGAffineTransformMakeRotation(M_PI / -2);
			bounds.size.width = screenHeight;
		} break;

		case UIInterfaceOrientationLandscapeRight:
		{
			transform = CGAffineTransformMakeRotation(M_PI / 2);
			bounds.size.width = screenHeight;
		} break;

		case UIInterfaceOrientationUnknown:

		case UIInterfaceOrientationPortrait:
		default:
		{
			transform = CGAffineTransformMakeRotation(0);
			bounds.size.width = screenWidth;
		} break;
	}

	if(animateOrient) {
		[UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
			[zealWindow setTransform:transform];
			zealWindow.bounds = bounds;
			zealWindow.center = CGPointMake(screenWidth / 2, screenHeight / 2);
		} completion:nil];
	} else {
		[zealWindow setTransform:transform];
		zealWindow.bounds = bounds;
		zealWindow.center = CGPointMake(screenWidth / 2, screenHeight / 2);
	}
}

-(void)_calculateRender { // does frame calculations and creates thumbImage
	CGSize screenSize = [[UIScreen mainScreen] bounds].size;
	screenSize = CGSizeMake(MIN(screenSize.width, screenSize.height), MAX(screenSize.width, screenSize.height));
	screenWidth = screenSize.width;
	screenHeight = screenSize.height;
}

-(void)_createAlert { // change of mind


}

- (void)updateData:(NSDictionary *)data{ // BatteryChange called gotta update the displayed info
	titleLabel.text = data[@"alertTitle"];
	messageLabel.text = data[@"alertMessage"];
	[bolt setHidden:![data[@"isCharging"] boolValue]];
	currentAmps.text = data[@"currentCapacity"];
	maxAmps.text = data[@"maxCapacity"];
	temprature.text = data[@"temprature"];
	cycles.text = data[@"cycleCount"];

	[currentAmps boldSubstring: @"Current Capacity:"];
	[maxAmps boldSubstring: @"Max Capacity:"];
	[designAmps boldSubstring: @"Design Capacity:"];
	[temprature boldSubstring: @"Temperature:"];
	[cycles boldSubstring: @"Cycles:"];
	[wearLevel boldSubstring: @"Wear Level:"];
}

- (void)powerSavingMode{
	[powerSaver setMode:![powerSaver getPowerMode]];
	[powerSavingButton setTitle:([powerSaver getPowerMode] == 1) ? @"Deactivate battery saving mode" : @"Activate battery saving mode" forState:UIControlStateNormal];
	[bolt setTintColor:([powerSaver getPowerMode] == 1) ? [UIColor yellowColor] : [UIColor greenColor]];
}

- (void)buttonTouchesBegan:(id)sender{
	UIButton *btn = (UIButton*)sender;
	btn.backgroundColor = RGBA(173,216,230,0.25);
}

- (void)buttonTouchesCanceled:(id)sender{
	UIButton *btn = (UIButton*)sender;
	btn.backgroundColor = RGBA(0,0,0,0);
}

- (void)swipeGesture:(UIPanGestureRecognizer *)panGestureRecognizer {

	CGPoint currentPoint = [panGestureRecognizer locationInView:alertView];

	if([[[UIDevice currentDevice] systemVersion] floatValue] >= 10.0){
		[(SBUIChevronView *)grabber setState:0 animated:YES];
	}else{
		[(SBChevronView *)grabber setState:0 animated:YES];
	}


	if ([panGestureRecognizer state] == UIGestureRecognizerStateChanged) {

		if((currentPoint.y >= alertFrame.size.height) && (currentPoint.y < alertFrame.size.height+95)){

			float percentage = (currentPoint.y-alertFrame.size.height)/70;

			currentAmps.alpha = percentage;
			maxAmps.alpha = percentage;
			temprature.alpha = percentage;
			designAmps.alpha = percentage;
			cycles.alpha = percentage;
			wearLevel.alpha = percentage;
			lineView4.alpha = percentage * 0.25;

			[UIView animateWithDuration:0.01f animations:^{
				alertView.frame = CGRectMake(alertFrame.origin.x, alertFrame.origin.y, alertFrame.size.width, currentPoint.y);
				alertView.center = backgroundView.center;

				swiper.frame = CGRectMake(0, alertView.frame.size.height - 30, kAlertWidth, 30);
				lineView4.frame = CGRectMake(0, alertView.frame.size.height - 35, kAlertWidth, 0.5);
			}];

		}

	} else if ([panGestureRecognizer state] == UIGestureRecognizerStateEnded) {

		if (currentPoint.y > alertFrame.size.height+70) {

			[UIView animateWithDuration:0.25 animations:^{
				alertView.frame = CGRectMake(alertFrame.origin.x, alertFrame.origin.y, alertFrame.size.width, alertFrame.size.height+70);
				alertView.center = backgroundView.center;

				swiper.frame = CGRectMake(0, alertView.frame.size.height - 30, kAlertWidth, 30);
				lineView4.frame = CGRectMake(0, alertView.frame.size.height - 35, kAlertWidth, 0.5);

				currentAmps.alpha = 1.0;
				maxAmps.alpha = 1.0;
				temprature.alpha = 1.0;
				cycles.alpha = 1.0;
				designAmps.alpha = 1.0;
				wearLevel.alpha = 1.0;
				lineView4.alpha = 0.25;
			}];
			if([[[UIDevice currentDevice] systemVersion] floatValue] >= 10.0){
				[(SBUIChevronView *)grabber setState:1 animated:YES];
			}else{
				[(SBChevronView *)grabber setState:1 animated:YES];
			}

		} else {

			[UIView animateWithDuration:0.25f animations:^{
				alertView.frame = alertFrame;
				alertView.center = backgroundView.center;

				swiper.frame = CGRectMake(0, alertView.frame.size.height - 30, kAlertWidth, 30);
				lineView4.frame = CGRectMake(0, alertView.frame.size.height - 35, kAlertWidth, 0.5);

				currentAmps.alpha = 0.0;
				maxAmps.alpha = 0.0;
				temprature.alpha = 0.0;
				cycles.alpha = 0.0;
				lineView4.alpha = 0.0;
				designAmps.alpha = 0.0;
				wearLevel.alpha = 0.0;
			}];

		}

	}
}

-(void)adjustBrightness:(id)sender{
	float brightness = [(UISlider *)sender value];
	if([[[UIDevice currentDevice] systemVersion] floatValue] > 8.0){
		if (_transaction == NULL) {
			_transaction = BKSDisplayBrightnessTransactionCreate(kCFAllocatorDefault);
		}
		BKSDisplayBrightnessSet(brightness, 1);
		if ([(UISlider *)sender isTracking] == NO && _transaction != NULL) {
			CFRelease(_transaction);
			_transaction = NULL;
		}
	}else{
		[[UIScreen mainScreen] setBrightness:brightness];
	}
}

-(void)_showAlert {
	zealWindow.hidden = NO;
	[UIView animateWithDuration:.2 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
		backgroundView.transform = CGAffineTransformIdentity;
		alertView.transform = CGAffineTransformIdentity;
		zealWindow.alpha = 1.0;
	} completion:nil];
}

-(void)_hideAlert {
	[UIView animateWithDuration:.2 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
		zealWindow.alpha = .0;
	} completion:^(BOOL finished){
		[backgroundView removeFromSuperview];
		[alertView removeFromSuperview];
		zealWindow.hidden = YES;
		if(_completion) {
			_completion();
        }
	}];
}

- (void)loadAlertWithData:(NSDictionary *)dictionary orientation:(UIInterfaceOrientation)orientation{
	dict = dictionary;
	[self _createAlert];
	[self adjustViewForOrientation:orientation animated:NO];
	[self _showAlert];
}

@end