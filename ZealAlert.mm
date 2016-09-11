#import "ZealAlert.h"
#import "Zeal.h"

#define RGBA(R,G,B,A) [UIColor colorWithRed:R/255.0f green:G/255.0f blue:B/255.0f alpha:A]

@implementation ZealAlert

@synthesize animate = _animate;
@synthesize userInteraction = _userInteraction;

static CGFloat calculateXPositionForAppNumber(int appNumber, int width){
	float spacing = (width - (AppIconSize*AppsPerRow) - (AppSpacing*2))/(AppsPerRow-1);
	int pageNumber = floor((appNumber-1)/AppsPerRow);
	int pageWidth = pageNumber*width;
	if((appNumber-1) % AppsPerRow == 0)	return pageWidth + AppSpacing;
	else	return pageWidth + AppSpacing + ((appNumber-(pageNumber*AppsPerRow))-1)*(AppIconSize+spacing);
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

-(void)_createAlert { // creates view heirarchy
	[self _calculateRender];

	//Drak mode option
	darkMode = [[dict objectForKey:@"darkMode"] boolValue];

	//Main Window
	zealWindow = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, screenWidth, screenHeight)]; // window to display on screen
	zealWindow.windowLevel = UIWindowLevelStatusBar + 100;
	zealWindow.backgroundColor = [UIColor clearColor];
	[zealWindow setUserInteractionEnabled:YES];
	[zealWindow makeKeyAndVisible];
	zealWindow.hidden = YES;

	//Dimmed background view
	backgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screenWidth * 2, screenHeight * 2)];
	backgroundView.center = zealWindow.center;
	backgroundView.alpha = 0.3;
	backgroundView.backgroundColor = [UIColor blackColor];
	backgroundView.autoresizingMask =  UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
	[backgroundView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_hideAlert)]];
	[zealWindow addSubview:backgroundView];

	//Main alert view
	alertView = [[UIView alloc] initWithFrame:CGRectMake(0,0,310,250)];
	alertView.center = backgroundView.center;
	alertFrame = alertView.frame;
	alertView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
	[[alertView layer] setCornerRadius:20.0f];
	[[alertView layer] setMasksToBounds:YES];
	[zealWindow addSubview:alertView];
	
	//Adding blurr
	_UIBackdropView *blurView = [[_UIBackdropView alloc] initWithFrame:CGRectZero autosizesToFitSuperview:YES settings:[[_UIBackdropViewSettings alloc] initWithDefaultValues]];
	[blurView transitionToPrivateStyle:2030];
	[alertView addSubview:blurView];

	//Alert icon
	alertIcon = [[UIImageView alloc] initWithFrame:CGRectMake(15,15,30,30)];
	alertIcon.image = [UIImage imageWithContentsOfFile:@"/Library/Application Support/Zeal/battery.png"];
	[alertView addSubview:alertIcon];

	//Alert title
	titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(55, 15, 200, 15)];
	titleLabel.text = dict[@"alertTitle"];
	titleLabel.font = [UIFont boldSystemFontOfSize:14];
	titleLabel.numberOfLines = 1;
	[alertView addSubview:titleLabel];

	//Alert message
	messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(55, 30, 200, 15)];
	messageLabel.font = [UIFont systemFontOfSize:12];
	messageLabel.numberOfLines = 1;
	messageLabel.text = dict[@"alertMessage"];
	[alertView addSubview:messageLabel];

	//Charging icon
	bolt = [[UIImageView alloc] initWithFrame:CGRectMake(270,20,20,20)];
	bolt.image = [UIImage imageWithContentsOfFile:@"/Library/Application Support/Zeal/bolt.png"];;
	bolt.image = [bolt.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
	[bolt setHidden:![dict[@"isCharging"] boolValue]];
	[bolt setTintColor:([powerSaver getPowerMode] == 1) ? [UIColor yellowColor] : [UIColor greenColor]];
	[alertView addSubview:bolt];

	//Power saving button
	powerSavingButton = [UIButton buttonWithType:UIButtonTypeCustom];
	powerSavingButton.frame = CGRectMake(15, 65, 280, 30);
	powerSavingButton.backgroundColor = [UIColor colorWithRed:196.0/255 green:196.0/255 blue:201.0/255 alpha:0.5];
	powerSavingButton.layer.cornerRadius = 5.0;
	[powerSavingButton setTitle:([powerSaver getPowerMode] == 1) ? @"Deactivate battery saving mode" : @"Activate battery saving mode" forState:UIControlStateNormal];
	[powerSavingButton addTarget:self action:@selector(powerSavingMode) forControlEvents:UIControlEventTouchUpInside];
	[powerSavingButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
	[powerSavingButton.titleLabel setFont:[UIFont systemFontOfSize:16]];
	[powerSavingButton setClipsToBounds:YES];
	[alertView addSubview:powerSavingButton];

	//Line seperator 1
	lineView = [[UIView alloc] initWithFrame:CGRectMake(0, 105, 310, 0.5)];
	lineView.backgroundColor = darkMode ? [UIColor whiteColor] : [UIColor blackColor];
	lineView.alpha = 0.25;
	[alertView addSubview:lineView];

	//Low brightness icon
	lowBright = [[UIImageView alloc] initWithFrame:CGRectMake(5,115,20,20)];
	lowBright.image = [[UIImage imageWithContentsOfFile:@"/Library/Application Support/Zeal/lowBright.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
	[lowBright setTintColor:[UIColor grayColor]];
	[alertView addSubview:lowBright];

	//Brightness slider
	brightnessSlider = [[UISlider alloc] initWithFrame:CGRectMake(30, 105, 250, 40)];
	brightnessSlider.value = [UIScreen mainScreen].brightness;
	brightnessSlider.minimumValue = 0.0;
	brightnessSlider.maximumValue = 0.99;
	brightnessSlider.tintColor = [UIColor grayColor];
	[brightnessSlider addTarget:springBoard action:@selector(adjustBrightness:) forControlEvents:UIControlEventValueChanged];
	[alertView addSubview:brightnessSlider];

	//Max brightness icon
	highBright = [[UIImageView alloc] initWithFrame:CGRectMake(280,115,20,20)];
	highBright.image = [[UIImage imageWithContentsOfFile:@"/Library/Application Support/Zeal/highBright.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
	[highBright setTintColor:[UIColor grayColor]];
	[alertView addSubview:highBright];

	//Line seperator 2
	lineView2 = [[UIView alloc] initWithFrame:CGRectMake(0, 145, 310, 0.5)];
	lineView2.backgroundColor = darkMode ? [UIColor whiteColor] : [UIColor blackColor];
	lineView2.alpha = 0.25;
	[alertView addSubview:lineView2];

	//Flip Switch buttons
	NSBundle *templateBundle = [NSBundle bundleWithPath:@"/Library/Application Support/FlipControlCenter/TopShelf8.bundle"];
	NSArray *enabledSwitchesArray = [[NSDictionary dictionaryWithContentsOfFile:kSettingsPath] objectForKey:@"EnabledIdentifiers"];
	FSSwitchPanel *flipSwitchPanel = [FSSwitchPanel sharedPanel];

	if ([enabledSwitchesArray count] > 0){
		//Flip Switch scroll view + buttons
		flipSwitchScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 150, 310, 60)];
		flipSwitchScrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		flipSwitchScrollView.pagingEnabled = YES;
		flipSwitchScrollView.scrollsToTop = NO;
		flipSwitchScrollView.showsHorizontalScrollIndicator=NO;
		flipSwitchScrollView.showsVerticalScrollIndicator=NO;

		int i = 1;
		for(NSString *identifier in enabledSwitchesArray) {
			UIButton *flipSwitchButton = [flipSwitchPanel buttonForSwitchIdentifier:identifier usingTemplate:templateBundle];
			flipSwitchButton.frame = CGRectMake(calculateXPositionForAppNumber(i,310), (flipSwitchScrollView.frame.size.height-AppIconSize)/2, AppIconSize, AppIconSize);
			[flipSwitchScrollView addSubview:flipSwitchButton];
			i++;
		}

		flipSwitchScrollView.contentSize = CGSizeMake( ceil(enabledSwitchesArray.count/(AppsPerRow*1.0))*310, flipSwitchScrollView.frame.size.height);
		[alertView addSubview:flipSwitchScrollView];
	}

	//Line seperator 3
	lineView3 = [[UIView alloc] initWithFrame:CGRectMake(0, 215, 310, 0.5)];
	lineView3.backgroundColor = darkMode ? [UIColor whiteColor] : [UIColor blackColor];
	lineView3.alpha = 0.25;
	[alertView addSubview:lineView3];

	//Current amperage
	currentAmps = [[UILabel alloc] initWithFrame:CGRectMake(3, 220, 170, 20)];
	currentAmps.font = [UIFont systemFontOfSize:11];
	currentAmps.textColor = darkMode ? [UIColor whiteColor] : [UIColor blackColor];
	currentAmps.text = dict[@"currentCapacity"];
	[currentAmps boldSubstring: @"Current Capacity:"];
	[alertView addSubview:currentAmps];

	//Max amperage
	maxAmps = [[UILabel alloc] initWithFrame:CGRectMake(3, 240, 170, 20)];
	maxAmps.font = [UIFont systemFontOfSize:11];
	maxAmps.textColor = darkMode ? [UIColor whiteColor] : [UIColor blackColor];
	maxAmps.text = dict[@"maxCapacity"];
	[maxAmps boldSubstring: @"Max Capacity:"];
	[alertView addSubview:maxAmps];

	//Battery temperature
	temprature = [[UILabel alloc] initWithFrame:CGRectMake(170, 220, 140, 20)];
	temprature.font = [UIFont systemFontOfSize:11];
	temprature.textColor = darkMode ? [UIColor whiteColor] : [UIColor blackColor];
	temprature.text = [dict objectForKey:@"temprature"];
	[temprature boldSubstring: @"Temperature:"];
	[alertView addSubview:temprature];

	//Number of cycles
	cycles = [[UILabel alloc] initWithFrame:CGRectMake(170, 240, 140, 20)];
	cycles.font = [UIFont systemFontOfSize:11];
	cycles.textColor = darkMode ? [UIColor whiteColor] : [UIColor blackColor];
	cycles.text = dict[@"cycleCount"];
	[cycles boldSubstring: @"Cycles:"];
	[alertView addSubview:cycles];

	//Line seperator 4
	lineView4 = [[UIView alloc] initWithFrame:CGRectMake(0, 215, 310, 0.5)];
	lineView4.backgroundColor = darkMode ? [UIColor whiteColor] : [UIColor blackColor];
	lineView4.alpha = 0.25;
	[alertView addSubview:lineView4];

	//Swipe/Close view
	swiper = [[UIView alloc] initWithFrame:CGRectMake(0,220,310,30)];
	[alertView addSubview:swiper];

	//Swipe gesture
	UIPanGestureRecognizer *swipeGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(swipeGesture:)];
	swipeGesture.maximumNumberOfTouches = swipeGesture.minimumNumberOfTouches = 1;
	[swiper addGestureRecognizer:swipeGesture];

	//Tap gesture
	UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_hideAlert)];
	[swiper addGestureRecognizer:tapGesture];

	//Grabber view
	_grabber = [[NSClassFromString(@"SBChevronView") alloc] initWithFrame:CGRectMake(136, 10, 38, 10)];
	_grabber.transform = CGAffineTransformMakeRotation(M_PI);
	[(SBChevronView *)_grabber setColor:[UIColor whiteColor]];
	[(SBChevronView *)_grabber setState:0 animated:NO];
	[_grabber setUserInteractionEnabled:NO];
	[swiper addSubview:_grabber];

	if(darkMode){
		messageLabel.textColor = [UIColor whiteColor];
		titleLabel.textColor = [UIColor whiteColor];
		alertView.backgroundColor = RGBA(40,40,40,0.93);
		[lowBright setTintColor:[UIColor whiteColor]];
		[brightnessSlider setTintColor:[UIColor whiteColor]];
		[highBright setTintColor:[UIColor whiteColor]];
	}else{
		messageLabel.textColor = [UIColor blackColor];
		titleLabel.textColor = [UIColor blackColor];
		alertView.backgroundColor = RGBA(245,245,245,0.975);
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

	alertView.backgroundColor = [UIColor clearColor];

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
	[(SBChevronView *)_grabber setState:0 animated:YES];

	if ([panGestureRecognizer state] == UIGestureRecognizerStateChanged) {

		if((currentPoint.y >= alertFrame.size.height) && (currentPoint.y < alertFrame.size.height+75)){

			float percentage = (currentPoint.y-alertFrame.size.height)/50;

			currentAmps.alpha = percentage;
			maxAmps.alpha = percentage;
			temprature.alpha = percentage;
			cycles.alpha = percentage;
			lineView4.alpha = percentage * 0.25;

			[UIView animateWithDuration:0.01f animations:^{
				alertView.frame = CGRectMake(alertFrame.origin.x, alertFrame.origin.y, alertFrame.size.width, currentPoint.y);
				swiper.frame = CGRectMake(0, alertView.frame.size.height - 30, 310, 30);
				lineView4.frame = CGRectMake(0, alertView.frame.size.height - 35, 310, 0.5);
			}];

		}

	} else if ([panGestureRecognizer state] == UIGestureRecognizerStateEnded) {

		if (currentPoint.y > alertFrame.size.height+50) {

			[UIView animateWithDuration:0.25 animations:^{
				alertView.frame = CGRectMake(alertFrame.origin.x, alertFrame.origin.y, alertFrame.size.width, alertFrame.size.height+50);
				swiper.frame = CGRectMake(0, alertView.frame.size.height - 30, 310, 30);
				lineView4.frame = CGRectMake(0, alertView.frame.size.height - 35, 310, 0.5);

				currentAmps.alpha = 1.0;
				maxAmps.alpha = 1.0;
				temprature.alpha = 1.0;
				cycles.alpha = 1.0;
				lineView4.alpha = 0.25;
			}];
			[(SBChevronView *)_grabber setState:1 animated:YES];

		} else {

			[UIView animateWithDuration:0.25f animations:^{
				alertView.frame = alertFrame;
				swiper.frame = CGRectMake(0, alertView.frame.size.height - 30, 310, 30);
				lineView4.frame = CGRectMake(0, alertView.frame.size.height - 35, 310, 0.5);

				currentAmps.alpha = 0.0;
				maxAmps.alpha = 0.0;
				temprature.alpha = 0.0;
				cycles.alpha = 0.0;
				lineView4.alpha = 0.0;
			}];

		}

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