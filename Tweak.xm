#import <substrate.h>
#import <CoreGraphics/CoreGraphics.h>
#import "MBA.h"
#import "MBACustomAlert.h"
#import "zealbannerui/FrontBoard.h"
#import "UILabel+Bold.h"

static NSMutableDictionary *extensions;
static NSUserDefaults *preferences;
static SBBulletinBannerController *bulletinBannerController;
static SBBannerController *bannerController;

#define kBounds 						[[UIScreen mainScreen] bounds]
#define kSettingsPath 					[NSHomeDirectory() stringByAppendingPathComponent:@"/Library/Preferences/com.rabih96.ZealPrefs.plist"]
#define PreferencesChangedNotification	"com.rabih96.ZealPrefs.Changed"
#define kRemoveBanner					"com.rabih96.ZealPrefs.Dismiss"
#define kPowerSaverMde					"com.rabih96.ZealPrefs.PSM"
#define kChangeBrightness				"com.rabih96.ZealPrefs.Brightness"

#define AppIconSize 45
#define AppSpacing 	15
#define AppsPerRow 	5

SBCCBrightnessSectionController *brightnessView	= nil;
UIWindow 						*wind 			= nil;
MBACustomAlert 					*vcView 		= nil;
UIButton 						*powerSavingButton;

static int 			 currentCapacity,	maxCapacity,	instantAmperage,	designCapacity,	cycleCount,	temperature, orient;
static BOOL 		 isCharging,	externalConnected,	externalChargeCapable,	fullyCharged,	enabled,	customTMA,	customTMB,	customSD,	addBU,	addS,	addB,	shouldShowBanner = NO;
static NSInteger 	 batteryLevel = 100,	customLevel,	bannerMode,	bannerTapAction,	soundPicked,	theme;
static NSString 	 *titleA,	*messageA,	*titleB,	*messageB,	*customTitleA,	*customTitleB,	*customMessageA,	*customMessageB;
static UIScrollView  *scrollView;
static float 		 thePlus;
//static char 		 dateFormatterHolder;

@interface UIApplication(ActivateSuspended)
-(BOOL)launchApplicationWithIdentifier:(id)identifier suspended:(BOOL)s;
@end

void loadSettings(){
	NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:kSettingsPath];

	NSNumber *enabledKey = prefs[@"enabled"];
	enabled = enabledKey ? [enabledKey boolValue] : 0;

	NSNumber *bannerModeKey = prefs[@"bannerMode"];
	bannerMode = bannerModeKey ? [bannerModeKey intValue] : 1;

	NSNumber *bannerTapActionKey = prefs[@"bannerTapAction"];
	bannerTapAction = bannerTapActionKey ? [bannerTapActionKey intValue] : 1;

	NSNumber *themeKey = prefs[@"theme"];
	theme = themeKey ? [themeKey intValue] : 1;

	NSNumber *soundPickedKey = prefs[@"soundPicked"];
	soundPicked = soundPickedKey ? [soundPickedKey intValue] : 4095;

	NSNumber *thePlusKey = prefs[@"thePlus"];
	thePlus = thePlusKey ? [thePlusKey floatValue] : 22.5;

	NSNumber *addBUKey = prefs[@"addBU"];
	addBU = addBUKey ? [addBUKey boolValue] : 0;

	NSNumber *addSKey = prefs[@"addS"];
	addS = addSKey ? [addSKey boolValue] : 1;

	NSNumber *addBKey = prefs[@"addB"];
	addB = addBKey ? [addBKey boolValue] : 0;

	NSNumber *customLevelKey = prefs[@"customLevel"];
	customLevel = [customLevelKey intValue];

	NSNumber *customTMAKey = prefs[@"customTMA"];
	customTMA = customTMAKey ? [customTMAKey boolValue] : 0;

	NSNumber *customSDKey = prefs[@"customSD"];
	customSD = customSDKey ? [customSDKey boolValue] : 0;

	NSNumber *customTMBKey = prefs[@"customTMB"];
	customTMB = customTMBKey ? [customTMBKey boolValue] : 0;

	customTitleA = [prefs objectForKey:@"customTitleA"];
	customTitleB = [prefs objectForKey:@"customTitleB"];

	customMessageA = [prefs objectForKey:@"customMessageA"];
	customMessageB = [prefs objectForKey:@"customMessageB"];
}

static BOOL darkMode(){
	return NO;

	NSDate *date = [NSDate date];
	NSDateFormatter *dateFormatter;
	dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setTimeZone:[NSTimeZone localTimeZone]];
	[dateFormatter setDateFormat:@"HH"];

	NSString *dateString = [dateFormatter stringFromDate:date];
	int timeInt = [dateString intValue];
	if((timeInt >= 20) || (timeInt <= 3)) return YES;
	else return NO;
}

void getTitles(){
	if([[[UIDevice currentDevice] systemVersion] floatValue] < 8.0)
		batteryLevel = (int)[[objc_getClass("SBUIController") sharedInstance] curvedBatteryCapacityAsPercentage];
	else
		batteryLevel = (int)[[objc_getClass("SBUIController") sharedInstance] batteryCapacityAsPercentage];

	if(customTMA){
		titleA = customTitleA;
		messageA = customMessageA;
	}else{
		titleA = [NSString stringWithFormat:@"Low Battery"];
		messageA = [NSString stringWithFormat:@"%ld%% of battery remaining",(long)batteryLevel];
	}

	if(customTMB){
		titleB = customTitleB;
		messageB = customMessageB;
	}else{
		titleB = [NSString stringWithFormat:@"Low Battery"];
		messageB = [NSString stringWithFormat:@"%ld%% of battery remaining",(long)batteryLevel];
	}
}

void dissmissBanner(void){
	if (bannerController._bannerContext != nil) {
		dispatch_async(dispatch_get_main_queue(), ^{
			[bannerController dismissBannerWithAnimation:YES reason:9999];
		});
	}
}

static void animateView(CGFloat time, NSInteger ort, BOOL positive){
	/*if(vcView != nil){
		int rotateAngle = 0;
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationDuration:time];
		switch (ort) {
			case 1:
			rotateAngle = 0.0f;
			break;
			case 2:
			rotateAngle = 180.0f;
			break;
			case 3:
			rotateAngle = 90.0f;
			break;
			case 4:
			rotateAngle = -90.0f;
			break;
			default:
			break;
		}
		vcView.transform = CGAffineTransformMakeRotation(rotateAngle * M_PI/180);
		[UIView commitAnimations];
	}*/
	if(vcView != nil){
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationDuration:time];
		if(positive) vcView.transform = CGAffineTransformMakeRotation(ort * M_PI/180);
		else vcView.transform = CGAffineTransformMakeRotation(-ort * M_PI/180);
		[UIView commitAnimations];
	}
}

CGFloat calculateXPositionForAppNumber(int appNumber, int width){
	float spacing = (width - (AppIconSize*AppsPerRow) - (AppSpacing*2))/(AppsPerRow-1);
	int pageNumber = floor((appNumber-1)/AppsPerRow);
	int pageWidth = pageNumber*width;
	if((appNumber-1) % AppsPerRow == 0)	return pageWidth + AppSpacing;
	else	return pageWidth + AppSpacing + ((appNumber-(pageNumber*AppsPerRow))-1)*(AppIconSize+spacing);
}

void showAlert(){
	getTitles();

	id sbSelf = (SpringBoard *)[%c(SpringBoard) sharedApplication];

	wind = [[UIWindow alloc] initWithFrame:kBounds];
	wind.windowLevel = UIWindowLevelAlert-1;
	[wind makeKeyAndVisible];

	UIViewController* vC = [[UIViewController alloc] init];
	wind.backgroundColor = [UIColor clearColor];

	UIView *test = [[UIView alloc]	init];
	UIView *customView = [[UIView alloc]	initWithFrame:CGRectMake(0,0,310,150)];
	UIView *customView2 = [[UIView alloc]	initWithFrame:CGRectMake(0,0,310,50)];

	UIView *lineView4 = [[UIView alloc] initWithFrame:CGRectMake(0, 49.5, 310, 0.5)];
	lineView4.backgroundColor = darkMode() ? [UIColor whiteColor] : [UIColor blackColor];
	lineView4.alpha = 0.25;
	[customView2 addSubview:lineView4];

	UILabel *currentAmps = [[UILabel alloc] initWithFrame:CGRectMake(5, 5, 175, 25)];
	currentAmps.font = [UIFont systemFontOfSize:12];
	currentAmps.textColor = darkMode() ? [UIColor whiteColor] : [UIColor blackColor];
	currentAmps.text = [NSString stringWithFormat:@"● Current Capacity: %.0f mAh", (float)currentCapacity];
	[currentAmps boldSubstring: @"Current Capacity:"];
	[customView2 addSubview:currentAmps];

	UILabel *maxAmps = [[UILabel alloc] initWithFrame:CGRectMake(5, 25, 175, 20)];
	maxAmps.font = [UIFont systemFontOfSize:12];
	maxAmps.textColor = darkMode() ? [UIColor whiteColor] : [UIColor blackColor];
	maxAmps.text = [NSString stringWithFormat:@"● Max Capacity: %.0f mAh", (float)maxCapacity];
	[maxAmps boldSubstring: @"Max Capacity:"];
	[customView2 addSubview:maxAmps];

	UILabel *temprature = [[UILabel alloc] initWithFrame:CGRectMake(180, 5, 130, 20)];
	temprature.font = [UIFont systemFontOfSize:12];
	temprature.textColor = darkMode() ? [UIColor whiteColor] : [UIColor blackColor];
	temprature.text = [NSString stringWithFormat:@"● Temprature: %.1f°C", (float)temperature/100];
	[temprature boldSubstring: @"Temprature:"];
	[customView2 addSubview:temprature];

	UILabel *cycles = [[UILabel alloc] initWithFrame:CGRectMake(180, 25, 130, 20)];
	cycles.font = [UIFont systemFontOfSize:12];
	cycles.textColor = darkMode() ? [UIColor whiteColor] : [UIColor blackColor];
	cycles.text = [NSString stringWithFormat:@"● Cycles: %.0f", (float)cycleCount];
	[cycles boldSubstring: @"Cycles:"];
	[customView2 addSubview:cycles];

	UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 85, 310, 60)];
	scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	scrollView.pagingEnabled = YES;
	scrollView.scrollsToTop = NO;
	scrollView.showsHorizontalScrollIndicator=NO;
	scrollView.showsVerticalScrollIndicator=NO;
	[customView addSubview:scrollView];

	UIImageView *lowBright = [[UIImageView alloc] initWithFrame:CGRectMake(5,50,20,20)];
	lowBright.image = [[UIImage imageWithContentsOfFile:@"/Library/Application Support/Zeal/lowBright.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
	[lowBright setTintColor:[UIColor grayColor]];
	[customView addSubview:lowBright];

	UIImageView *highBright = [[UIImageView alloc] initWithFrame:CGRectMake(280,50,20,20)];
	highBright.image = [[UIImage imageWithContentsOfFile:@"/Library/Application Support/Zeal/highBright.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
	[highBright setTintColor:[UIColor grayColor]];
	[customView addSubview:highBright];

	UISlider *brightnessSlider = [[UISlider alloc] initWithFrame:CGRectMake(30, 40, 250, 40)];
	brightnessSlider.value = [UIScreen mainScreen].brightness;
	brightnessSlider.minimumValue = 0.0;
	brightnessSlider.maximumValue = 0.99;
	brightnessSlider.tintColor = [UIColor grayColor];
	[brightnessSlider addTarget:sbSelf action:@selector(adjustBrightness:) forControlEvents:UIControlEventValueChanged];
	[customView addSubview:brightnessSlider];

	UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(0, 40, 310, 0.5)];
	lineView.backgroundColor = [UIColor blackColor];
	lineView.alpha = 0.25;
	[customView addSubview:lineView];

	UIView *lineView2 = [[UIView alloc] initWithFrame:CGRectMake(0, 80, 310, 0.5)];
	lineView2.backgroundColor = darkMode() ? [UIColor whiteColor] : [UIColor blackColor];
	lineView2.alpha = 0.25;
	[customView addSubview:lineView2];

	UIView *lineView3 = [[UIView alloc] initWithFrame:CGRectMake(0, 150, 310, 0.5)];
	lineView3.backgroundColor = darkMode() ? [UIColor whiteColor] : [UIColor blackColor];
	lineView3.alpha = 0.25;
	[customView addSubview:lineView3];

	powerSavingButton = [UIButton buttonWithType:UIButtonTypeCustom];
	powerSavingButton.frame = CGRectMake(15, 0, 280, 30);
	[powerSavingButton setTitle:([powerSaver getPowerMode] == 1) ? @"Deactivate battery saving mode" : @"Activate battery saving mode" forState:UIControlStateNormal];
	[powerSavingButton addTarget:sbSelf action:@selector(powerSavingMode) forControlEvents:UIControlEventTouchUpInside];
	powerSavingButton.backgroundColor = [UIColor colorWithRed:196.0/255 green:196.0/255 blue:201.0/255 alpha:0.5];
	powerSavingButton.layer.cornerRadius = 5.0;
	[powerSavingButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
	[powerSavingButton.titleLabel setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:16.0]];
	[powerSavingButton setClipsToBounds:YES];
	[customView addSubview:powerSavingButton];

	NSBundle *templateBundle = [NSBundle bundleWithPath:@"/Library/Application Support/FlipControlCenter/TopShelf8.bundle"];
	FSSwitchPanel *fsp = [FSSwitchPanel sharedPanel];
	NSArray *array = [[NSDictionary dictionaryWithContentsOfFile:kSettingsPath] objectForKey:@"EnabledIdentifiers"];
	///////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//if ([array count] == 0) array = stuff
	///////////////////////////////////////////////////////////////////////////////////////////////////////////////
	int i = 1;
	for(NSString *identifier in array) {
		UIButton *button = [fsp buttonForSwitchIdentifier:identifier usingTemplate:templateBundle];
		button.frame = CGRectMake(calculateXPositionForAppNumber(i,310), (scrollView.frame.size.height-AppIconSize)/2, AppIconSize, AppIconSize);
		[scrollView addSubview:button];
		i++;
	}
	scrollView.contentSize = CGSizeMake( ceil(array.count/(AppsPerRow*1.0))*310, scrollView.frame.size.height);

	vcView = [[MBACustomAlert alloc] initWithFrame:CGRectMake(0,0,kBounds.size.height,kBounds.size.height) title:[NSString stringWithFormat:@"Low Battery: %.0f%%", ((float)currentCapacity/maxCapacity)*100]	message:[NSString stringWithFormat:@"Current Capacity:%.0f mAh", (float)currentCapacity] customView:customView dropDownView:customView2 nightMode:darkMode() iconImage:[UIImage imageWithContentsOfFile:@"/Library/Application Support/Zeal/battery.png"]	isCharging:isCharging];
	vcView.center = (orient == 1||orient == 2) ? CGPointMake(kBounds.size.width/2,kBounds.size.height/2) : CGPointMake(kBounds.size.height/2,kBounds.size.width/2);
	//animateView(0,orient);
	[test addSubview:vcView];
	vC.view = test;

	wind.rootViewController = vC;
	if (customSD) AudioServicesPlaySystemSound(soundPicked);
}

void QRCModifyBulletinRequest(BBBulletinRequest *request)
{

	NSString *sectionID = request.sectionID;
	if ([sectionID isEqualToString:@"com.apple.Preferences"])
	{

		[request.supplementaryActionsByLayout.allKeys enumerateObjectsUsingBlock:^(NSNumber *layout, NSUInteger index, BOOL *stop) {
			[request setSupplementaryActions:nil forLayout:layout.integerValue];
		}];

		BBAction *action = [BBAction actionWithIdentifier:@"action"];
		action.actionType = 7;
		action.appearance = [BBAppearance appearanceWithTitle:@"Reply"];
		action.remoteServiceBundleIdentifier = @"com.apple.mobilesms.notification";
		action.remoteViewControllerClassName = @"ZealBannerViewController";
		action.authenticationRequired = NO;
		action.activationMode = 1;
		[request setSupplementaryActions:@[action]];

		BBButton *reply = [BBButton buttonWithTitle:@"Reply" action:action identifier:@"action"];
		request.buttons = @[reply];
	}
}

static inline void PresentComposer() {
	getTitles();

	bulletinBannerController = (SBBulletinBannerController *)[NSClassFromString(@"SBBulletinBannerController") sharedInstance];
	bannerController = (SBBannerController *)[NSClassFromString(@"SBBannerController") sharedInstance];

	BBBulletinRequest *bulletin = [[BBBulletinRequest alloc] init];
	bulletin.sectionID = @"com.apple.Preferences";
	bulletin.title = titleB;
	bulletin.message = messageB;

	BBAction *action = [BBAction actionWithIdentifier:@"ZealActionIdentifier"];
	action.actionType = 7;
	action.appearance = [BBAppearance appearanceWithTitle:@"Zeal"];
	action.remoteServiceBundleIdentifier = @"com.apple.mobilesms.notification";
	action.remoteViewControllerClassName = @"ZealBannerViewController";
	action.authenticationRequired = NO;
	action.activationMode = 1;
	[bulletin setSupplementaryActions:@[action]];

	[bulletinBannerController observer:nil addBulletin:bulletin forFeed:2 playLightsAndSirens:YES withReply:nil];

	if (customSD)	AudioServicesPlaySystemSound(soundPicked);
}

void QRCDispatchAfter(CGFloat delay, void (^block)(void)) {
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^(void) {
		block();
	});
}

%hook SBDefaultBannerView
- (void)layoutSubviews {
	%orig();
	if ([self.bannerContext.item respondsToSelector:@selector(seedBulletin)]) {
		BBBulletin *bulletin = self.bannerContext.item.seedBulletin;
			UIImageView *iconImageView = MSHookIvar<UIImageView*>(self, "_iconImageView");
			/*UIImage *imageK = [[UIImage alloc] initWithContentsOfFile:@"/Library/PreferencesBundles/Keek.bundle/Keek.png"];
			iconImageView.image = imageK;*/
	}
}
%end

void showBanner(){
	SBBannerController *bannerController = [NSClassFromString(@"SBBannerController") sharedInstance];
	if (bannerController._bannerContext && [bannerController._bannerContext.item respondsToSelector:@selector(seedBulletin)]) {
		dispatch_async(dispatch_get_main_queue(), ^{
			[bannerController dismissBannerWithAnimation:YES reason:1];
		});
	} else {
		if (bannerController.isShowingBanner || bannerController.isShowingModalBanner) {
			dispatch_async(dispatch_get_main_queue(), ^{
				[bannerController dismissBannerWithAnimation:YES reason:1];
			});
			QRCDispatchAfter(0.3, ^{ PresentComposer(); });
		} else {
			if (bannerController._bannerContext == nil) PresentComposer();
		}
	}

}

void MBA(){
	if(shouldShowBanner){
		if(bannerMode == 0){
			showAlert();
		}else if(bannerMode == 1){
			showBanner();
		}else if(bannerMode == 2){
			return;
		}else{
			return;
		}
		shouldShowBanner = NO;
	}
}

static BKSDisplayBrightnessTransactionRef _transaction;

static void changeBrightness(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	CGFloat brightLevel = [((__bridge NSDictionary*)userInfo)[@"brightness"] floatValue];
	if(brightLevel >= 1.0) return;
	if([[[UIDevice currentDevice] systemVersion] floatValue] > 8.0){
		if (_transaction == NULL) {
			_transaction = BKSDisplayBrightnessTransactionCreate(kCFAllocatorDefault);
		}
		BKSDisplayBrightnessSet(brightLevel, 1);
	}else{
		[[UIScreen mainScreen] setBrightness:brightLevel];
	}
}

void powerSavingMde(void){
	[powerSaver setMode:![powerSaver getPowerMode]];
}

%hook SpringBoard

%new
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

- (void)batteryStatusDidChange:(id)batteryStatus{
	currentCapacity 		= [[batteryStatus objectForKey:@"AppleRawCurrentCapacity"] intValue];
	maxCapacity 			= [[batteryStatus objectForKey:@"AppleRawMaxCapacity"] intValue];
	instantAmperage			= [[batteryStatus objectForKey:@"InstantAmperage"] intValue];
	designCapacity		 	= [[batteryStatus objectForKey:@"DesignCapacity"] intValue];
	temperature 			= [[batteryStatus objectForKey:@"Temperature"] intValue];
	cycleCount 				= [[batteryStatus objectForKey:@"CycleCount"] intValue];
	externalChargeCapable 	= [[batteryStatus objectForKey:@"ExternalChargeCapable"] boolValue];
	externalConnected 		= [[batteryStatus objectForKey:@"ExternalConnected"] boolValue];
	fullyCharged			= [[batteryStatus objectForKey:@"FullyCharged"] boolValue];
	isCharging 				= [[batteryStatus objectForKey:@"IsCharging"]	boolValue];
	%orig;
}

%new
- (void)removeWindow{
	[vcView removeFromSuperview];
	[wind resignKeyWindow];

	vcView = nil;
	wind = nil;
}

%new
- (void)powerSavingMode{
	[powerSaver setMode:![powerSaver getPowerMode]];
	[powerSavingButton setTitle:([powerSaver getPowerMode] == 1) ? @"Deactivate battery saving mode" : @"Activate battery saving mode" forState:UIControlStateNormal];
}

%end

/*

this needs to be in a diffrent tweak hooking com.apple.UIKit 

%group UIKitHooks
%hook UIViewController

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
	%orig;
	if (![disabledViewControllers() containsObject:NSStringFromClass(self.class)]) {
		notify_set_state(willrotate,toInterfaceOrientation);
		notify_post("com.sharedroutine.appheads.willrotate");
	}
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	%orig;
	if (![disabledViewControllers() containsObject:NSStringFromClass(self.class)]) {
		notify_set_state(didrotate,fromInterfaceOrientation);
		notify_post("com.sharedroutine.appheads.didrotate");
	}
}

%end
%end*/

%hook SBWallpaperController
-(void)activeInterfaceOrientationDidChangeToOrientation:(NSInteger)activeInterfaceOrientation willAnimateWithDuration:(CGFloat)duration fromOrientation:(NSInteger)orientation {
	%orig;
	int angle;

	if(((orientation == 1||orientation == 2) && (activeInterfaceOrientation == 3||activeInterfaceOrientation == 4))||((orientation == 3||orientation == 4) && (activeInterfaceOrientation == 1||activeInterfaceOrientation == 2))) angle = 90;
	else angle = 180;

	NSArray *numbers = [NSArray arrayWithObjects: @"13", @"12", @"32", @"34", @"24", @"21", @"41", nil];
	NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
	formatter.numberStyle = NSNumberFormatterDecimalStyle;
	NSNumber *value = [formatter numberFromString:[NSString stringWithFormat:@"%d%d",orientation,activeInterfaceOrientation]];

	BOOL positive = CFArrayContainsValue ( (__bridge CFArrayRef)numbers,	CFRangeMake(0, numbers.count),	(CFNumberRef)value );

	//animateView(duration,activeInterfaceOrientation);
	animateView(duration,angle,positive);

	/*if(orientation == 1){
		if(activeInterfaceOrientation == 2)	animateView(duration,180,YES);
		if(activeInterfaceOrientation == 3)	animateView(duration,90,YES);
		if(activeInterfaceOrientation == 4)	animateView(duration,90,NO);
	}else if(orientation == 2){
		if(activeInterfaceOrientation == 1)	animateView(duration,180,NO);
		if(activeInterfaceOrientation == 3)	animateView(duration,90,NO);
		if(activeInterfaceOrientation == 4)	animateView(duration,90,YES);
	}else if(orientation == 3){
		if(activeInterfaceOrientation == 1)	animateView(duration,90,NO);
		if(activeInterfaceOrientation == 2)	animateView(duration,90,NO);
		if(activeInterfaceOrientation == 4)	animateView(duration,180,YES);
	}else if(orientation == 4){
		if(activeInterfaceOrientation == 1)	animateView(duration,90,YES);
		if(activeInterfaceOrientation == 2)	animateView(duration,90,YES);
		if(activeInterfaceOrientation == 3)	animateView(duration,180,NO);
	}*/

	orient = activeInterfaceOrientation;
}
%end

/*Activator Listener*/

@interface ZealActivator : NSObject<LAListener>
@end

@implementation ZealActivator

-(void)activator:(LAActivator *)activator receiveEvent:(LAEvent *)event {
	shouldShowBanner = YES;
	MBA();
}

+(void)load {
	[[LAActivator sharedInstance] registerListener:[self new] forName:@"com.rabih96.ZealActivator"];
}
@end

//Hello Message (1st run)

%hook SBLockScreenViewController

- (void)finishUIUnlockFromSource:(int)arg1 {
	%orig;
	/*NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:kSettingsPath];
	if (!prefs) {
		SIAlertView *alertView = [[SIAlertView alloc] initWithTitle:@"Zeal" andMessage:@"Hi there, thank you for purchasing Zeal you can enable this tweak in Settings."];
		[alertView addButtonWithTitle:@"Settings"
		type:SIAlertViewButtonTypeDestructive
		handler:^(SIAlertView *alert) {
			if ([[NSFileManager defaultManager] fileExistsAtPath:@"/Library/MobileSubstrate/DynamicLibraries/PreferenceOrganizer.dylib"]) {
				[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"prefs:root=Cydia&path=Zeal"]];
			}else {
				[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"prefs:root=Zeal"]];
			}
		}];
		[alertView addButtonWithTitle:@"Dismiss"
		type:SIAlertViewButtonTypeCancel
		handler:^(SIAlertView *alert) {
		}];
		alertView.transitionStyle = SIAlertViewTransitionStyleBounce;
		[alertView show];
	}*/
}

%end

/*Alert Items Controller*/

%hook SBAlertItemsController

- (void)activateAlertItem:(id)item{
	if ([item isKindOfClass:%c(SBLowPowerAlertItem)]) {
		shouldShowBanner = YES;
		MBA();
	}else %orig;
}

%end

/*Baterry Level Changing (where the magic happens)*/

%hook SBStatusBarStateAggregator

- (void)_updateBatteryItems
{

	%orig;

	/*SBLockScreenManager *lockscreenManager = (SBLockScreenManager *)[objc_getClass("SBLockScreenManager") sharedInstance];

	[self loadSettings];

	if(enabled){

		if([[[UIDevice currentDevice] systemVersion] floatValue] < 8.3)
			batteryLevel = (int)[[objc_getClass("SBUIController") sharedInstance] batteryCapacityAsPercentage];
		else	if([[[UIDevice currentDevice] systemVersion] floatValue] < 8.0)
			batteryLevel = (int)[[objc_getClass("SBUIController") sharedInstance] curvedBatteryCapacityAsPercentage];
		else
			batteryLevel = (int)[[objc_getClass("SBUIController") sharedInstance] batteryCapacityAsPercentage];

		if(!lockscreenManager.isUILocked && ([[objc_getClass("SBUIController") sharedInstance] isOnAC] == FALSE)){
			if((batteryLevel > anotherBatteryLevel) && (anotherBatteryLevel == customLevel)) shouldShowBanner = YES;
			MBA();
		}
	}

	if([[[UIDevice currentDevice] systemVersion] floatValue] < 8.0)
		batteryLevel = (int)[[objc_getClass("SBUIController") sharedInstance] curvedBatteryCapacityAsPercentage];
	else
		batteryLevel = (int)[[objc_getClass("SBUIController") sharedInstance] batteryCapacityAsPercentage];*/

}

%end

%hook SBLowPowerAlertItem

- (BOOL)shouldShowInLockScreen{
	return NO;
}

- (void)willPresentAlertView:(id)arg1{
	shouldShowBanner = YES;
	MBA();
}

%end

%hook SBCCBrightnessSectionController

- (BOOL)_shouldDarkenBackground{
	if(self.view.tag == 01305435) return NO;
	else return %orig;
}

%end

%ctor{
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)loadSettings, CFSTR(PreferencesChangedNotification), NULL, CFNotificationSuspensionBehaviorCoalesce);
	loadSettings();
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)dissmissBanner, CFSTR(kRemoveBanner), NULL, 0);
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)powerSavingMde, CFSTR(kPowerSaverMde), NULL, 0);
	CFNotificationCenterAddObserver(CFNotificationCenterGetDistributedCenter(),	NULL,	changeBrightness,	CFSTR(kChangeBrightness),	NULL,	CFNotificationSuspensionBehaviorDeliverImmediately);
}
