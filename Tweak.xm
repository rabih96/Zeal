//
//  Zeal
//  Developed by Rabih Mteyrek (@rabih96)
//	Desinged by Stijn (@StijnDV)
//
//  Successor of MyBatteryAlerts for iOS 9-10
//

#import "ZealAlert.h"
#import "Zeal.h"
#import "UILabel+Bold.h"
#import "zealbannerui/FrontBoard.h"
#import "JBBulletinManager.h"

static NSMutableDictionary			*extensions;
static NSUserDefaults				*preferences;
static SBBulletinBannerController	*bulletinBannerController;
static SBBannerController			*bannerController;
static ZealAlert					*zealAlert;

static BOOL				notifyWhenFull, calculatedBattery, pullDown, active, isCharging, externalConnected, externalChargeCapable, fullyCharged, enabled, estimateTimeLeft, customTMB, customSD, shouldShowBanner = NO;
static NSInteger		batteryLevel = 100, bannerMode, soundPicked, darkMode, switchesPerPage, currentCapacity,  maxCapacity, instantAmperage, designCapacity, cycleCount, temperature, switchesPerPageNC;
static NSString			*titleA, *messageA, *titleB, *messageB, *customTitleA, *customTitleB, *customMessageA, *customMessageB;
static dispatch_once_t	onceToken;

static void dispatchAfter(CGFloat delay, void (^block)(void)) {
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^(void) {
		block();
	});
}

static void powerSavingModeSwitch(){
	[powerSaver setMode:![powerSaver getPowerMode]];
}

static BOOL isLocked(){
	return (objc_getClass("SBAwayController") != nil) ? [[objc_getClass("SBAwayController") sharedAwayController] isLocked] : [[objc_getClass("SBLockScreenManager") sharedInstanceIfExists] isUILocked];
}

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

static BOOL darkModeAlert(){
	if(darkMode == 1){
		return YES;
	}else if(darkMode == 3){
		return NO;
	}else if(darkMode == 2){
		NSDate *fromDate = (NSDate *)[[NSDictionary dictionaryWithContentsOfFile:kSettingsPath] objectForKey:@"fromDate"];
		NSDate *nowDate = [NSDate date];
		NSDate *tillDate = (NSDate *)[[NSDictionary dictionaryWithContentsOfFile:kSettingsPath] objectForKey:@"tillDate"];

		NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setTimeZone:[NSTimeZone localTimeZone]];
		[dateFormatter setDateFormat:@"HH.mm"];

		CGFloat fromDateInt = [[dateFormatter stringFromDate:fromDate] floatValue];
		CGFloat nowDateInt = [[dateFormatter stringFromDate:nowDate] floatValue];
		CGFloat tillDateInt = [[dateFormatter stringFromDate:tillDate] floatValue];

		if(fromDateInt > tillDateInt){
			if(nowDateInt < fromDateInt && nowDateInt > tillDateInt) return NO;
			return YES;
		}else{
			if(BETWEEN(nowDateInt, fromDateInt, tillDateInt)) return YES;
			return NO;
		}
	}
	return NO;
}

static NSString *formatTimeFromSeconds(NSInteger numberOfSeconds){
	long seconds = numberOfSeconds % 60;
	long minutes = (numberOfSeconds / 60) % 60;
	long hours = numberOfSeconds / 3600;

	if (hours) return [NSString stringWithFormat:@"%ldh %02ldmin", hours, minutes];
	if (minutes) return [NSString stringWithFormat:@"%ldmin %02ldsec", minutes, seconds];
	return [NSString stringWithFormat:@"%ldsec", seconds];
}

static void getTitles(){
	isCharging = [[objc_getClass("SBUIController") sharedInstance] isOnAC];

	if([[[UIDevice currentDevice] systemVersion] floatValue] < 8.0){
		batteryLevel = (NSInteger)[[objc_getClass("SBUIController") sharedInstance] curvedBatteryCapacityAsPercentage];
	} else {
		batteryLevel = (NSInteger)[[objc_getClass("SBUIController") sharedInstance] batteryCapacityAsPercentage];
	}

	if (batteryLevel == 100){
		titleB = @"Full Battery";       
	}else if (batteryLevel >= 90){
		titleB = @"Almost Full Battery";
	}else if (batteryLevel >= 65){
		titleB = @"Partially Full Battery";
	}else if (batteryLevel >= 45){
		titleB = @"Half Full Battery";
	}else if (batteryLevel >= 25){
		titleB = @"Partially Low Battery";
	}else{
		titleB = @"Low Battery";
	}

	if (isCharging){
		messageB = messageA = [NSString stringWithFormat:@"Time left to charge ≅ %@", formatTimeFromSeconds((NSInteger)roundf( (CGFloat)(maxCapacity - currentCapacity) / labs(instantAmperage) * 2520.0 ))];
		if(fullyCharged) {
			messageB = messageA = @"Unplug device from charger";
		}
	}else{
		messageA = [NSString stringWithFormat:@"Usage time left ≅ %@", formatTimeFromSeconds((NSInteger)roundf( (CGFloat)currentCapacity / labs(instantAmperage) * 2520.0 ))];
		messageB = isCharging ? messageB : [NSString stringWithFormat:@"%ld%% of battery remaining", (long)batteryLevel];
		messageA = isCharging ? messageA : messageB;
		titleA = isCharging ? ([NSString stringWithFormat:@"%@ %ld%%", titleB, (long)batteryLevel]) : (titleB);
	}

	/*if (isCharging){
		messageB = messageA = [NSString stringWithFormat:@"Time left to charge ≅ %@", formatTimeFromSeconds((NSInteger)roundf( (CGFloat)(maxCapacity - currentCapacity) / labs(instantAmperage) * 2520.0 ))];
		messageB = [NSString stringWithFormat:@"Time left to charge ≅ %@", formatTimeFromSeconds((NSInteger)roundf( (CGFloat)(maxCapacity - currentCapacity) / labs(instantAmperage) * 2520.0 ))];
		if(fullyCharged || (NSInteger)roundf( (CGFloat)currentCapacity / abs(instantAmperage) * 2520.0 ) <= 60 ){
			messageB = messageA = @"Unplug device from charger";
			messageB = @"Unplug device from charger";
		}
	}else{
		messageA = [NSString stringWithFormat:@"Usage time left ≅ %@", formatTimeFromSeconds((NSInteger)roundf( (CGFloat)currentCapacity / labs(instantAmperage) * 2520.0 ))];
	}

	if(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"10.0.0")){
			messageB = isCharging ? messageB : [NSString stringWithFormat:@"%ld%% of battery remaining", (long)batteryLevel];
			messageA = isCharging ? messageA : messageB;
			titleA = isCharging ? ([NSString stringWithFormat:@"%@ %ld%%", titleB, (long)batteryLevel]) : (titleB);
	}else{
		if(calculatedBattery){
			messageB = [NSString stringWithFormat:@"%d%% of battery remaining", (NSInteger)roundf( ((CGFloat) currentCapacity / maxCapacity) * 100 )];
			messageA = estimateTimeLeft ? messageA : messageB;
			titleA = estimateTimeLeft ? ([NSString stringWithFormat:@"%@ %.0f%%", titleB, ((CGFloat) currentCapacity / maxCapacity) * 100]) : (titleB);
		}else{
			messageB = [NSString stringWithFormat:@"%ld%% of battery remaining", (long)batteryLevel];
			messageA = estimateTimeLeft ? messageA : messageB;
			titleA = estimateTimeLeft ? ([NSString stringWithFormat:@"%@ %ld%%", titleB, (long)batteryLevel]) : (titleB);
		}
	}*/
}

static NSString *getValue_forKey(NSString *key){
	NSArray * args = @[@"-rd1", @"-c", @"AppleARMPMUCharger"];
	NSTask * task = [NSTask new];
	[task setLaunchPath:@"/usr/sbin/ioreg"];
	[task setArguments:args];

	NSPipe * pipe = [NSPipe new];
	[task setStandardOutput:pipe];
	[task launch];
		
	NSArray * args2 = @[@"-o", [NSString stringWithFormat:@"\"%@\" = [^ ]*", key]];
	NSTask * task2 = [NSTask new];
	[task2 setLaunchPath:@"/bin/grep"];
	[task2 setArguments:args2];

	NSPipe * pipe2 = [NSPipe new];
	[task2 setStandardInput:pipe];
	[task2 setStandardOutput:pipe2];
	[task2 launch];

	NSArray * args3 = @[@"-e", @"s/=//g", @"-e", @"s/\"//g", @"-e", @"s/ //g", @"-e", [NSString stringWithFormat:@"s/%@//", key]];
	NSTask * task3 = [NSTask new];
	[task3 setLaunchPath:@"/bin/sed"];
	[task3 setArguments:args3];

	NSPipe * pipe3 = [NSPipe new];
	[task3 setStandardInput:pipe2];
	[task3 setStandardOutput:pipe3];
	[task3 launch];

	return [[NSString alloc] initWithData:[[pipe3 fileHandleForReading] readDataToEndOfFile] encoding:NSUTF8StringEncoding];
}

static void removeAlert(){
	if(zealAlert != nil) [zealAlert _hideAlert];
}

static void showAlert(){
	getTitles();

	if (!active && !isLocked()) {

		UIInterfaceOrientation orientation = [(SpringBoard *)[UIApplication sharedApplication] activeInterfaceOrientation];

		NSDictionary *data = @{
			@"alertTitle" 		: titleA,
			@"alertMessage" 	: messageA,
			@"isCharging" 		: [NSNumber numberWithBool:isCharging],
			@"currentCapacity" 	: [NSString stringWithFormat:@"Current Capacity: %.0f mAh", (CGFloat) currentCapacity],
			@"maxCapacity" 		: [NSString stringWithFormat:@"Max Capacity: %.0f mAh",(CGFloat) maxCapacity],
			@"designCapacity" 	: [NSString stringWithFormat:@"Design Capacity: %.0f mAh",(CGFloat) designCapacity],
			@"temprature" 		: [NSString stringWithFormat:@"Temperature: %.1f°C", (CGFloat) temperature / 100],
			@"cycleCount" 		: [NSString stringWithFormat:@"Cycles: %.0f", (CGFloat) cycleCount],
			@"wearLevel" 		: [NSString stringWithFormat:@"Wear Level: %.0f%%", (1.0 - ((CGFloat) maxCapacity / designCapacity)) * 100],
			@"darkMode" 		: [NSNumber numberWithBool:darkModeAlert()],
			@"appsPerRow" 		: [NSNumber numberWithInt:switchesPerPage]
		};

		zealAlert = [[ZealAlert alloc] initWithData:data andOrientation:orientation];
		active = true;

		zealAlert.completion = ^{
			zealAlert = nil;
			active = false;
		};

		[zealAlert _showAlert];
	}
}

static inline id notificationController(){
	SBLockScreenNotificationListController *lockScreenNotificationListController=([[objc_getClass("UIApplication") sharedApplication] respondsToSelector:@selector(notificationDispatcher)] && [[[objc_getClass("UIApplication") sharedApplication] notificationDispatcher] respondsToSelector:@selector(notificationSource)]) ? [[[objc_getClass("UIApplication") sharedApplication] notificationDispatcher] notificationSource]  : [[[objc_getClass("SBLockScreenManager") sharedInstanceIfExists] lockScreenViewController] valueForKey:@"notificationController"];
	return lockScreenNotificationListController;
}

static inline NSString *getUUID(){
	CFUUIDRef uuidObject = CFUUIDCreate(kCFAllocatorDefault);
	NSString *uuidStr = (__bridge NSString *)CFUUIDCreateString(kCFAllocatorDefault, uuidObject);
	CFRelease(uuidObject);
	return uuidStr;
}

static inline void presentController() {
	bulletinBannerController = (SBBulletinBannerController *)[NSClassFromString(@"SBBulletinBannerController") sharedInstance];

	BBBulletinRequest *bulletin = [[BBBulletinRequest alloc] init];
	bulletin.sectionID = @"com.apple.Preferences";
	bulletin.title = titleB;
	bulletin.message = messageB;
	bulletin.bulletinID= getUUID();
	bulletin.bulletinVersionID= getUUID();
	bulletin.recordID= getUUID();
	[bulletin setClearable:YES];

	if([[[UIDevice currentDevice] systemVersion] floatValue] >= 10.0){
		SBLockScreenNotificationListController *listController = notificationController();
		[listController observer:[bulletinBannerController valueForKey:@"observer"] addBulletin:bulletin forFeed:2 playLightsAndSirens:YES withReply:nil];
	}else{
		if(pullDown){
			BBAction *action = [BBAction actionWithIdentifier:@"ZealActionIdentifier"];
			action.actionType = 7;
			action.appearance = [BBAppearance appearanceWithTitle:@"Zeal"];
			action.remoteServiceBundleIdentifier = @"com.apple.mobilesms.notification";
			action.remoteViewControllerClassName = @"ZealBannerViewController";
			action.authenticationRequired = NO;
			action.activationMode = 1;
			[bulletin setSupplementaryActions:@[action]];
		}
		[bulletinBannerController observer:[bulletinBannerController valueForKey:@"observer"] addBulletin:bulletin forFeed:2 playLightsAndSirens:YES withReply:nil];
	}

	if (customSD) AudioServicesPlaySystemSound(soundPicked);
}

static void dismissBanner(){
	if (bannerController._bannerContext != nil) {
		dispatch_async(dispatch_get_main_queue(), ^{
			[bannerController dismissBannerWithAnimation:YES reason:9999];
		});
	}
}

static void showBanner(){
	getTitles();

	bannerController = (SBBannerController *)[NSClassFromString(@"SBBannerController") sharedInstance];

	if (bannerController._bannerContext && [bannerController._bannerContext.item respondsToSelector:@selector(seedBulletin)]) {
		dismissBanner();
	} else {
		if (bannerController.isShowingBanner || bannerController.isShowingModalBanner) {
			dismissBanner();
			dispatchAfter(0.3, ^{ presentController(); });
		} else {
			if (bannerController._bannerContext == nil) presentController();
		}
	}
}

static void ZealAction(){
	if([[[UIDevice currentDevice] systemVersion] floatValue] >= 10.0){
		@try {
			externalChargeCapable	= [getValue_forKey(@"ExternalChargeCapable") boolValue];
			externalConnected		= [getValue_forKey(@"ExternalConnected") boolValue];
			fullyCharged			= [getValue_forKey(@"FullyCharged") boolValue];
			currentCapacity			= [getValue_forKey(@"AppleRawCurrentCapacity") intValue];
			maxCapacity				= [getValue_forKey(@"AppleRawMaxCapacity") intValue];
			instantAmperage			= [getValue_forKey(@"InstantAmperage") intValue];
			designCapacity			= [getValue_forKey(@"DesignCapacity") intValue];
			temperature				= [getValue_forKey(@"Temperature") intValue];
			cycleCount				= [getValue_forKey(@"CycleCount") intValue];
		
			if(shouldShowBanner){
				if(bannerMode == 0 && !isLocked()){
					showAlert();
				}else if(bannerMode == 1){
					showBanner();
				}else if(bannerMode == 2){
					return;
				}
				shouldShowBanner = NO;
				if(bannerMode == 0 && isLocked()) shouldShowBanner = YES;
			}
		} @catch (NSException *exception) { }
	}else{
		if(shouldShowBanner){
			if(bannerMode == 0 && !isLocked()){
				showAlert();
			}else if(bannerMode == 1){
				showBanner();
			}else if(bannerMode == 2){
				return;
			}
			shouldShowBanner = NO;
			if(bannerMode == 0 && isLocked()) shouldShowBanner = YES;
		}
	}
}

/*static BOOL isInScreenOffMode() {
	BOOL _screenOff = NO;
	if (%c(SBLockScreenManager)) {
		SBLockScreenManager *manager = (SBLockScreenManager *)[%c(SBLockScreenManager) sharedInstance];
		SBLockScreenViewController *lock = [manager lockScreenViewController];
		_screenOff = [lock isInScreenOffMode];
	}
	else if (%c(SBAwayController)) {
		SBAwayController *cont = (SBAwayController *)[%c(SBAwayController) sharedAwayController];
		_screenOff = [cont isDimmed];
	}
	return _screenOff;
}

static void turnOnScreenIfNeeded() {
	if (isInScreenOffMode() && isLocked()) {
		if (%c(SBLockScreenManager)) {
			SBLockScreenManager *manager = (SBLockScreenManager *)[%c(SBLockScreenManager) sharedInstance];
			NSDictionary *options = @{ @"SBUIUnlockOptionsTurnOnScreenFirstKey" : [NSNumber numberWithBool:YES] };
			[manager unlockUIFromSource:6 withOptions:options];
		} else {
			SBUserAgent *agent = (SBUserAgent *)[%c(SBUserAgent) sharedUserAgent];
			[agent undimScreen];
		}
	}
}*/

static void loadSettings(){
	NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:kSettingsPath];

	SETBOOL(enabled, "enabled", 1);
	SETBOOL(pullDown, "pullDown", 1);
	SETBOOL(customTMB, "customTMB", 0);
	SETBOOL(notifyWhenFull, "notifyWhenFull", 0);
	SETBOOL(estimateTimeLeft, "estimateTimeLeft", 0);
	SETBOOL(calculatedBattery, "calculatedBattery", 0);

	SETINT(darkMode, "darkMode", 3);
	SETINT(bannerMode, "bannerMode", 0);
	SETINT(switchesPerPage, "switchesPerPage", 5);
	SETINT(switchesPerPageNC, "switchesPerPageNC", 5);
}

/*Activator Listener*/
@interface ZealActivator : NSObject<LAListener>
@end

@implementation ZealActivator

-(void)activator:(LAActivator *)activator receiveEvent:(LAEvent *)event {
	shouldShowBanner = YES;
	ZealAction();
}

+(void)load {
	[[LAActivator sharedInstance] registerListener:[self new] forName:@"com.rabih96.ZealActivator"];
}

@end

%group HelloMessage

%hook SpringBoard

- (void)applicationDidFinishLaunching:(UIApplication *)application {
	%orig;

	if (![[NSFileManager defaultManager] fileExistsAtPath:kSettingsPath]) {
		UIViewController *view = [UIApplication sharedApplication].keyWindow.rootViewController;
		while (view.presentedViewController != nil && !view.presentedViewController.isBeingDismissed) {
			view = view.presentedViewController;
		}

		UIAlertController *alerView = [UIAlertController alertControllerWithTitle:@"Zeal" message:@"Hi there,\n Thank you for purchasing Zeal, it took me a lot of time and work to bring this tweak to you!\n Hope you'll like it." preferredStyle:UIAlertControllerStyleAlert];
		
		UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:nil];
		
		/*UIAlertAction *settingsAction = [UIAlertAction actionWithTitle:@"Settings" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
			if ([[NSFileManager defaultManager] fileExistsAtPath:@"/Library/MobileSubstrate/DynamicLibraries/PreferenceOrganizer.dylib"]) {
				[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"prefs:root=Cydia&path=Zeal"]];
			}else {
				[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"prefs:root=Zeal"]];
			}
		}];*/

		[alerView addAction:cancelAction];
		//[alerView addAction:settingsAction];
		[view presentViewController:alerView animated:YES completion:nil];
	}

	if (shouldShowBanner) CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR(kShowAlert), NULL, NULL, YES);
}
%end

%end

%group Zeal10

%hook NCNotificationLongLookViewController
%new
-(void)adjustBrightness:(id)sender{
	CGFloat brightness = [(UISlider *)sender value];
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

-(void)viewWillLayoutSubviews {
	%orig;

	if ([[[[self view] class] description] isEqualToString:@"_NCNotificationViewControllerView"]) {
		NCNotificationLongLookView *view = [(_NCNotificationViewControllerView *)[self view] contentView];

		if ([[[[self notificationRequest] bulletin] section] isEqualToString:@"com.apple.Preferences"] && [[view interfaceActions] count] == 0 && pullDown) {

			UIInterfaceAction *powerSavingModeAction = [%c(UIInterfaceAction) actionWithTitle:([powerSaver getPowerMode] == 1) ? @"Deactivate battery saving mode" : @"Activate battery saving mode" type:0 handler:^{
				[self _handleCloseButton:nil];
				powerSavingModeSwitch();
			}];

			UIView *test = [[UIView alloc] initWithFrame:CGRectMake(0,0, powerSavingModeAction.customContentView.bounds.size.width, powerSavingModeAction.customContentView.bounds.size.height)];

			UISlider *brightnessSlider = [[UISlider alloc] initWithFrame:CGRectMake(0, 0, 250, 40)];
			brightnessSlider.value = [UIScreen mainScreen].brightness;
			brightnessSlider.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
			brightnessSlider.minimumValue = 0.0;
			brightnessSlider.maximumValue = 0.9999;

			[brightnessSlider setThumbTintColor:[UIColor whiteColor]];
			[brightnessSlider setMaximumTrackTintColor:[UIColor whiteColor]];
			[brightnessSlider setMinimumTrackTintColor:[UIColor blackColor]];

			[brightnessSlider addTarget:self action:@selector(adjustBrightness:) forControlEvents:UIControlEventValueChanged];
			[test addSubview:brightnessSlider];

			UIImageView *lowBright = [[UIImageView alloc] initWithFrame:CGRectMake(-40,10,20,20)];
			lowBright.image = [[UIImage imageWithContentsOfFile:@"/Library/Application Support/Zeal/lowBright.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
			[lowBright setTintColor:[UIColor blackColor]];
			[brightnessSlider addSubview:lowBright];

			UIImageView *highBright = [[UIImageView alloc] initWithFrame:CGRectMake(270,10,20,20)];
			highBright.image = [[UIImage imageWithContentsOfFile:@"/Library/Application Support/Zeal/highBright.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
			[highBright setTintColor:[UIColor blackColor]];
			[brightnessSlider addSubview:highBright];

			UIView *flipSwitchHolder = [[UIView alloc] initWithFrame:CGRectMake(0, 40, kBannerViewWidth, 50)];
			NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:kSettingsPath];
			NSBundle *templateBundle = [NSBundle bundleWithPath:@"/Library/Application Support/Zeal/ZealFSNC10.bundle"];
			NSArray *enabledSwitchesArray = [prefs objectForKey:@"EnabledIdentifiers"];
			FSSwitchPanel *flipSwitchPanel = [FSSwitchPanel sharedPanel];

			if (enabledSwitchesArray == nil || [enabledSwitchesArray count] == 0) {
				enabledSwitchesArray = [NSArray arrayWithObjects:@"com.a3tweaks.switch.airplane-mode", @"com.a3tweaks.switch.wifi", @"com.a3tweaks.switch.bluetooth", @"com.a3tweaks.switch.do-not-disturb", @"com.a3tweaks.switch.rotation-lock", nil];
			}else{
				dispatch_async(dispatch_get_main_queue(), ^{
					NSInteger i = 1;
					for(NSString *identifier in enabledSwitchesArray) {
						UIButton *flipSwitchButton = [flipSwitchPanel buttonForSwitchIdentifier:identifier usingTemplate:templateBundle];
						flipSwitchButton.frame = CGRectMake(calculateXPositionForAppNumber(i,kBannerViewWidth,switchesPerPageNC), 5, 45, 45);
						[flipSwitchHolder addSubview:flipSwitchButton];
						if(i == switchesPerPageNC) break;
						i++;
					}
				});
			}

			flipSwitchHolder.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
			[test addSubview:flipSwitchHolder];

			UIInterfaceAction *customViewTest = [%c(UIInterfaceAction) actionWithCustomContentView:test];
			[customViewTest setHandler:^{}];
			[customViewTest _setIsFocused:NO];
			[customViewTest _setIsPreferred:NO];
			[customViewTest setEnabled:NO];

			NSMutableArray *actions = [[NSMutableArray alloc] init];
			[actions addObject:powerSavingModeAction];
			[actions addObject:customViewTest];
			//[actions addObject:showAlertAction];
			[view setInterfaceActions:[actions copy]];
		}
	}
}
%end
%end

%group Zeal

%hook BBBulletinRequest
-(UIImage *)sectionIconImageWithFormat:(int)aformat{
	if ([[self  sectionID] isEqualToString:@"com.apple.Preferences"] && [[self  title] isEqualToString:titleB]){
	
		UIImage *customImage = [UIImage imageWithContentsOfFile:@"/Library/Application Support/Zeal/batteryBanner.png"];

		if (customImage){
			if (objc_getClass("SBAwayController")!=nil){
				CGFloat height=customImage.size.height;
				CGFloat width=customImage.size.width;
				if (width>20 || height>20){
					CGFloat maxValue=MAX(width,height);
					CGFloat proportion=20/maxValue;
					customImage=[customImage _imageScaledToProportion:proportion interpolationQuality:5];
				}
			}
			return customImage;
		}
	}
	
	return %orig;
}
%end

%hook SBWallpaperController
-(void)activeInterfaceOrientationDidChangeToOrientation:(NSInteger)activeInterfaceOrientation willAnimateWithDuration:(CGFloat)duration fromOrientation:(NSInteger)orientation {
	%orig;
	if(active && zealAlert != nil) dispatchAfter(0, ^{ [zealAlert adjustViewForOrientation:activeInterfaceOrientation animated:YES]; });
}
%end

%hook SpringBoard
/*-(BOOL)isPoweringDown{
	if(%orig == YES){
		ZealAction();
	}
}*/

%new
-(void)orientationChange:(NSNotification *)notification {
	if(zealAlert != nil) {
		[zealAlert adjustViewForOrientation:[[UIApplication sharedApplication] statusBarOrientation] animated:YES];
	}
}

%new
-(void)adjustBrightness:(id)sender{
	CGFloat brightness = [(UISlider *)sender value];
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

- (void)_batterySaverModeChanged:(int)arg1{

	%orig;

	//Update the info on the alert if visible
	if (zealAlert != nil){
		getTitles();

		[zealAlert updateData:@{
			@"alertTitle" 		: titleA,
			@"alertMessage" 	: messageA,
			@"isCharging" 		: [NSNumber numberWithBool:isCharging],
			@"currentCapacity" 	: [NSString stringWithFormat:@"Current Capacity: %.0f mAh", (CGFloat) currentCapacity],
			@"maxCapacity" 		: [NSString stringWithFormat:@"Max Capacity: %.0f mAh",(CGFloat) maxCapacity],
			@"designCapacity" 	: [NSString stringWithFormat:@"Design Capacity: %.0f mAh",(CGFloat) designCapacity],
			@"temprature" 		: [NSString stringWithFormat:@"Temperature: %.1f°C", (CGFloat) temperature / 100],
			@"cycleCount" 		: [NSString stringWithFormat:@"Cycles: %.0f", (CGFloat) cycleCount],
			@"wearLevel" 		: [NSString stringWithFormat:@"Wear Level: %.0f", (1.0 - ((CGFloat) maxCapacity / designCapacity)) * 100],
			@"darkMode" 		: [NSNumber numberWithBool:darkModeAlert()],
			@"appsPerRow" 		: [NSNumber numberWithInt:switchesPerPage]
		}];
	}
}

- (void)batteryStatusDidChange:(id)batteryStatus{
	//iOS 9
	if([[[UIDevice currentDevice] systemVersion] floatValue] < 10.0){
		isCharging				= [[objc_getClass("SBUIController") sharedInstance] isOnAC];
		externalChargeCapable	= [[batteryStatus objectForKey:@"ExternalChargeCapable"] boolValue];
		externalConnected		= [[batteryStatus objectForKey:@"ExternalConnected"] boolValue];
		fullyCharged			= [[batteryStatus objectForKey:@"FullyCharged"] boolValue];
		currentCapacity			= [[batteryStatus objectForKey:@"AppleRawCurrentCapacity"] intValue];
		maxCapacity				= [[batteryStatus objectForKey:@"AppleRawMaxCapacity"] intValue];
		instantAmperage			= [[batteryStatus objectForKey:@"InstantAmperage"] intValue];
		designCapacity			= [[batteryStatus objectForKey:@"DesignCapacity"] intValue];
		temperature				= [[batteryStatus objectForKey:@"Temperature"] intValue];
		cycleCount				= [[batteryStatus objectForKey:@"CycleCount"] intValue];
	}

	%orig;

	//Update the info on the alert if visible
	if (zealAlert != nil){
		getTitles();
		[zealAlert updateData:@{
			@"alertTitle" : titleA,
			@"alertMessage" : messageA,
			@"isCharging" : [NSNumber numberWithBool:isCharging],
			@"currentCapacity" : [NSString stringWithFormat:@"Current Capacity: %.0f mAh", (CGFloat) currentCapacity],
			@"maxCapacity" : [NSString stringWithFormat:@"Max Capacity: %.0f mAh",(CGFloat) maxCapacity],
			@"designCapacity" : [NSString stringWithFormat:@"Design Capacity: %.0f mAh",(CGFloat) designCapacity],
			@"temprature" : [NSString stringWithFormat:@"Temperature: %.1f°C", (CGFloat) temperature / 100],
			@"cycleCount" : [NSString stringWithFormat:@"Cycles: %.0f", (CGFloat) cycleCount],
			@"wearLevel" : [NSString stringWithFormat:@"Wear Level: %.0f", (1.0 - ((CGFloat) maxCapacity / designCapacity)) * 100],
			@"darkMode" : [NSNumber numberWithBool:darkModeAlert()],
			@"appsPerRow" : [NSNumber numberWithInt:switchesPerPage]
		}];
	}

	if (fullyCharged && notifyWhenFull) {
		dispatch_once (&onceToken, ^{
			showBanner();
		});
	}
}

%new
- (void)powerSavingMode{
	[powerSaver setMode:![powerSaver getPowerMode]];
}

-(void)_handleMenuButtonEvent {
	if(zealAlert != nil) removeAlert();
	else %orig;
}

-(void)_menuButtonWasHeld {
	removeAlert();
	%orig;
}

-(void)handleMenuDoubleTap {
	removeAlert();
	%orig;
}

-(void)_simulateLockButtonPress{
	removeAlert();
	%orig;
}

-(void)_simulateHomeButtonPress{
	removeAlert();
	%orig;
}

%end

//Alert Items Controller
%hook SBAlertItemsController

- (void)activateAlertItem:(id)item{
	if ([item isKindOfClass:%c(SBLowPowerAlertItem)]) {
		shouldShowBanner = YES;
		ZealAction();
	}else %orig;
}

%end

%hook SBLowPowerAlertItem

- (BOOL)shouldShowInLockScreen{
	return YES;
}

- (void)willPresentAlertView:(id)arg1{
	shouldShowBanner = YES;
	ZealAction();
}

%end
%end

%ctor{
	loadSettings();

	if(enabled){

		%init(Zeal);
		%init(HelloMessage);
		
		if([[[UIDevice currentDevice] systemVersion] floatValue] >= 10.0){
			%init(Zeal10);
			HBLogDebug(@"iOS 10 configured !");
		}else{
			HBLogDebug(@"iOS 9 or 8 doesnt matter");
		}

		CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)loadSettings, CFSTR(PreferencesChangedNotification), NULL, CFNotificationSuspensionBehaviorCoalesce);
		CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)removeAlert, CFSTR("com.apple.springboard.screenchanged"), NULL, 0);
		CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)powerSavingModeSwitch, CFSTR(kPowerSaverMde), NULL, 0);
		CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)dismissBanner, CFSTR(kRemoveBanner), NULL, 0);
		CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)ZealAction, CFSTR(kShowAlert), NULL, 0);
		CFNotificationCenterAddObserver(CFNotificationCenterGetDistributedCenter(), NULL, changeBrightness, CFSTR(kChangeBrightness), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
	}

}
