//
//	Zeal
//	By Rabih Mteyrek (@rabih96)
//
//	Successor of MyBatteryAlerts
//	
//	TODO:
//	-fix titles
//	-complete settings
//	-clean code
//
//

#import "ZealAlert.h"
#import "Zeal.h"
#import "UILabel+Bold.h"
#import "UIAlertView+Blocks.h"
#import "zealbannerui/FrontBoard.h"
#import "JBBulletinManager.h"

static NSMutableDictionary 				  *extensions;
static NSUserDefaults					  *preferences;
static SBBulletinBannerController 		  *bulletinBannerController;
static SBBannerController 				  *bannerController;
static ZealAlert 						  *zealAlert;

static int 				darkMode, switchesPerPage, currentCapacity,	maxCapacity,	instantAmperage, designCapacity,	cycleCount,	temperature, orient;
static BOOL 			notifyWhenFull, calculatedBattery, pullDown, active, isCharging, externalConnected,	externalChargeCapable, fullyCharged, enabled, estimateTimeLeft, customTMB,	customSD, shouldShowBanner = NO;
static NSInteger	 	batteryLevel = 100, customLevel, bannerMode, bannerTapAction, soundPicked;
static NSString			*titleA, *messageA, *titleB, *messageB, *customTitleA, *customTitleB, *customMessageA, *customMessageB;
static dispatch_once_t  onceToken;

#define BETWEEN(value, min, max) (value <= max && value >= min)

%group shared

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

		float fromDateInt = [[dateFormatter stringFromDate:fromDate] floatValue];
		float nowDateInt = [[dateFormatter stringFromDate:nowDate] floatValue];
		float tillDateInt = [[dateFormatter stringFromDate:tillDate] floatValue];

		//[[[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"%.2f %.2f %.2f", fromDateInt, nowDateInt, tillDateInt] message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];

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

static NSString *formatTimeFromSeconds(int numberOfSeconds){

    int seconds = numberOfSeconds % 60;
    int minutes = (numberOfSeconds / 60) % 60;
    int hours = numberOfSeconds / 3600;

    if (hours) return [NSString stringWithFormat:@"%dh %02dmin", hours, minutes];
    if (minutes) return [NSString stringWithFormat:@"%dmin %02dsec", minutes, seconds];
    return [NSString stringWithFormat:@"%dsec", seconds];

}

static void getTitles(){

	isCharging = [[objc_getClass("SBUIController") sharedInstance] isOnAC];

	if([[[UIDevice currentDevice] systemVersion] floatValue] < 8.0){
		batteryLevel = (int)[[objc_getClass("SBUIController") sharedInstance] curvedBatteryCapacityAsPercentage];
	} else {
		batteryLevel = (int)[[objc_getClass("SBUIController") sharedInstance] batteryCapacityAsPercentage];
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
		messageA = [NSString stringWithFormat:@"Time left to charge ≅ %@", formatTimeFromSeconds((int)roundf( (float)(maxCapacity - currentCapacity) / abs(instantAmperage) * 2520.0 ))];
	}else{
		messageA = [NSString stringWithFormat:@"Usage time left ≅ %@", formatTimeFromSeconds((int)roundf( (float)currentCapacity / abs(instantAmperage) * 2520.0 ))];
	}

	if(calculatedBattery){
		messageB = [NSString stringWithFormat:@"%d%% of battery remaining", (int)roundf( ((float) currentCapacity / maxCapacity) * 100 )];
		messageA = estimateTimeLeft ? messageA : messageB;
		titleA = estimateTimeLeft ? ([NSString stringWithFormat:@"%@ %.0f%%", titleB, ((float) currentCapacity / maxCapacity) * 100]) : (titleB);
	}else{
		messageB = [NSString stringWithFormat:@"%ld%% of battery remaining", (long)batteryLevel];
		messageA = estimateTimeLeft ? messageA : messageB;
		titleA = estimateTimeLeft ? ([NSString stringWithFormat:@"%@ %ld%%", titleB, (long)batteryLevel]) : (titleB);
	}

	if(fullyCharged && isCharging) (messageA = messageB) = @"Unplug device from charger";

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

	externalChargeCapable 	= [getValue_forKey(@"ExternalChargeCapable") boolValue];
	externalConnected 		= [getValue_forKey(@"ExternalConnected") boolValue];
	fullyCharged			= [getValue_forKey(@"FullyCharged") boolValue];
	currentCapacity 		= [getValue_forKey(@"AppleRawCurrentCapacity") intValue];
	maxCapacity 			= [getValue_forKey(@"AppleRawMaxCapacity") intValue];
	instantAmperage			= [getValue_forKey(@"InstantAmperage") intValue];
	designCapacity		 	= [getValue_forKey(@"DesignCapacity") intValue];
	temperature 			= [getValue_forKey(@"Temperature") intValue];
	cycleCount 				= [getValue_forKey(@"CycleCount") intValue];

	getTitles();

	if (!active && !isLocked()) {

		UIInterfaceOrientation orientation = [(SpringBoard *)[UIApplication sharedApplication] activeInterfaceOrientation];

		zealAlert = [[ZealAlert alloc] init];
		active = true;

		NSDictionary *data = @{
			@"alertTitle" : titleA,
			@"alertMessage" : messageA,
			@"isCharging" : [NSNumber numberWithBool:isCharging],
			@"currentCapacity" : [NSString stringWithFormat:@"Current Capacity: %.0f mAh", (float) currentCapacity],
			@"maxCapacity" : [NSString stringWithFormat:@"Max Capacity: %.0f mAh",(float) maxCapacity],
			@"designCapacity" : [NSString stringWithFormat:@"Design Capacity: %.0f mAh",(float) designCapacity],
			@"temprature" : [NSString stringWithFormat:@"Temperature: %.1f°C", (float) temperature / 100],
			@"cycleCount" : [NSString stringWithFormat:@"Cycles: %.0f", (float) cycleCount],
			@"wearLevel" : [NSString stringWithFormat:@"Wear Level: %.0f%%", (1.0 - ((float) maxCapacity / designCapacity)) * 100],
			@"darkMode" : [NSNumber numberWithBool:darkModeAlert()],
			@"appsPerRow" : [NSNumber numberWithInt:switchesPerPage],
		};

		zealAlert.completion = ^{
			zealAlert = nil;
			active = false;
		};

		[zealAlert loadAlertWithData:data orientation:orientation];
		
		if (customSD) AudioServicesPlaySystemSound(soundPicked);	
	}

	//[[NSClassFromString(@"UNUserNotificationServiceConnection") sharedInstance] addNotificationRequest:[NSClassFromString(@"UNNotificationRequest") requestWithIdentifier:@"test" content:[[NSClassFromString(@"UNMutableNotificationContent") alloc] init] trigger:[NSClassFromString(@"UNTimeIntervalNotificationTrigger") triggerWithTimeInterval:0.f repeats:NO]] forBundleIdentifier:@"com.apple.Preferences" withCompletionHandler:nil];

}

static inline void presentController() {

	bulletinBannerController = (SBBulletinBannerController *)[NSClassFromString(@"SBBulletinBannerController") sharedInstance];

	BBBulletinRequest *bulletin = [[BBBulletinRequest alloc] init];
	bulletin.sectionID = @"com.apple.Preferences";
	bulletin.title = titleB;
	bulletin.message = messageB;

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

	[bulletinBannerController observer:nil addBulletin:bulletin forFeed:2 playLightsAndSirens:YES withReply:nil];

	if (customSD) AudioServicesPlaySystemSound(soundPicked);

}

static void dissmissBanner(){

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
		dissmissBanner();
	} else {
		if (bannerController.isShowingBanner || bannerController.isShowingModalBanner) {
			dissmissBanner();
			dispatchAfter(0.3, ^{ presentController(); });
		} else {
			if (bannerController._bannerContext == nil) presentController();
		}
	}

}

static void ZealAction(){

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

static BOOL isInScreenOffMode() {
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
}

static void loadSettings(){

	NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:kSettingsPath];

	SETBOOL(enabled, "enabled", 0);
	SETINT(darkMode, "darkMode", 3);
	SETBOOL(calculatedBattery, "calculatedBattery", 0);
	SETBOOL(pullDown, "pullDown", 1);
	SETBOOL(notifyWhenFull, "notifyWhenFull", 1);
	SETINT(bannerMode, "bannerMode", 0);
	SETINT(switchesPerPage, "switchesPerPage", 5);
	SETBOOL(estimateTimeLeft, "estimateTimeLeft", 0);
	SETBOOL(customTMB, "customTMB", 0);

	NSNumber *bannerTapActionKey = prefs[@"bannerTapAction"];
	bannerTapAction = bannerTapActionKey ? [bannerTapActionKey intValue] : 1;

	SETINT(soundPicked, "soundPicked", 4095);

	NSNumber *customLevelKey = prefs[@"customLevel"];
	customLevel = [customLevelKey intValue];

	NSNumber *customSDKey = prefs[@"customSD"];
	customSD = customSDKey ? [customSDKey boolValue] : 0;

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

//Hello Message (1st run)
%hook SBLockScreenViewController

- (void)finishUIUnlockFromSource:(int)arg1 {
	%orig;

	NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:kSettingsPath];
	if (!prefs) {
		[UIAlertView showWithTitle:@"Zeal" message:@"Hi there,\n Thank you for purchasing Zeal, it took me a lot of time and work so i hope you'll like it." cancelButtonTitle:@"Cancel" otherButtonTitles:@[@"Settings"] tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
			if (buttonIndex == [alertView cancelButtonIndex]) {
				//Cancel
			} else if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Settings"]) {
				if ([[NSFileManager defaultManager] fileExistsAtPath:@"/Library/MobileSubstrate/DynamicLibraries/PreferenceOrganizer.dylib"]) {
					[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"prefs:root=Cydia&path=Zeal"]];
				}else {
					[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"prefs:root=Zeal"]];
				}
			}
		}];
	}

	if (shouldShowBanner) CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR(kShowAlert), NULL, NULL, YES);
}

%end

%hook BBBulletinRequest

-(UIImage *)sectionIconImageWithFormat:(int)aformat{
	
	if ([[self 	sectionID] isEqualToString:@"com.apple.Preferences"] && [[self 	title] isEqualToString:titleB]){
	
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

%end

%group Zeal

%hook SpringBoard

/*-(BOOL)isPoweringDown{
	if(%orig == YES){
		ZealAction();
	}
}*/

%new(v@:);
-(void)orientationChange:(NSNotification *)notification {
	if(zealAlert != nil) {
		[zealAlert adjustViewForOrientation:[[UIApplication sharedApplication] statusBarOrientation] animated:YES];
	}
}

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

- (void)_batterySaverModeChanged:(int)arg1{

	%orig;

	//Update the info on the alert if visible
	if (zealAlert != nil){
		getTitles();

		[zealAlert updateData:@{
			@"alertTitle" : titleA,
			@"alertMessage" : messageA,
			@"isCharging" : [NSNumber numberWithBool:isCharging],
			@"currentCapacity" : [NSString stringWithFormat:@"Current Capacity: %.0f mAh", (float) currentCapacity],
			@"maxCapacity" : [NSString stringWithFormat:@"Max Capacity: %.0f mAh",(float) maxCapacity],
			@"designCapacity" : [NSString stringWithFormat:@"Design Capacity: %.0f mAh",(float) designCapacity],
			@"temprature" : [NSString stringWithFormat:@"Temperature: %.1f°C", (float) temperature / 100],
			@"cycleCount" : [NSString stringWithFormat:@"Cycles: %.0f", (float) cycleCount],
			@"wearLevel" : [NSString stringWithFormat:@"Wear Level: %.0f", (1.0 - ((float) maxCapacity / designCapacity)) * 100],
			@"darkMode" : [NSNumber numberWithBool:darkModeAlert()],
			@"appsPerRow" : [NSNumber numberWithInt:switchesPerPage],

		}];
	}
}

- (void)batteryStatusDidChange:(id)batteryStatus{

	//iOS 9
	if(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"9.0.0") && SYSTEM_VERSION_LESS_THAN(@"10.0.0")){
		externalChargeCapable 	= [[batteryStatus objectForKey:@"ExternalChargeCapable"] boolValue];
		externalConnected 		= [[batteryStatus objectForKey:@"ExternalConnected"] boolValue];
		fullyCharged			= [[batteryStatus objectForKey:@"FullyCharged"] boolValue];
		isCharging				= [[objc_getClass("SBUIController") sharedInstance] isOnAC];
		currentCapacity 		= [[batteryStatus objectForKey:@"AppleRawCurrentCapacity"] intValue];
		maxCapacity 			= [[batteryStatus objectForKey:@"AppleRawMaxCapacity"] intValue];
		instantAmperage			= [[batteryStatus objectForKey:@"InstantAmperage"] intValue];
		designCapacity		 	= [[batteryStatus objectForKey:@"DesignCapacity"] intValue];
		temperature 			= [[batteryStatus objectForKey:@"Temperature"] intValue];
		cycleCount 				= [[batteryStatus objectForKey:@"CycleCount"] intValue];
	}

	/*//iOS 10
	if(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"10.0.0")){
	    
	    HBLogDebug(@"CycleCount: %@", getValue_forKey(@"CycleCount"));
	    HBLogDebug(@"InstantAmperage: %@", getValue_forKey(@"InstantAmperage"));
	    HBLogDebug(@"DesignCapacity: %@", getValue_forKey(@"DesignCapacity"));

		externalChargeCapable 	= [[batteryStatus objectForKey:@"ExternalChargeCapable"] boolValue];
		externalConnected 		= [[batteryStatus objectForKey:@"ExternalConnected"] boolValue];
		fullyCharged			= [[batteryStatus objectForKey:@"FullyCharged"] boolValue];
		isCharging				= [[objc_getClass("SBUIController") sharedInstance] isOnAC];
		currentCapacity 		= [[batteryStatus objectForKey:@"AppleRawCurrentCapacity"] intValue];
		maxCapacity 			= [[batteryStatus objectForKey:@"AppleRawMaxCapacity"] intValue];
		instantAmperage			= [[batteryStatus objectForKey:@"InstantAmperage"] intValue];
		designCapacity		 	= [[batteryStatus objectForKey:@"DesignCapacity"] intValue];
		temperature 			= [[batteryStatus objectForKey:@"Temperature"] intValue];
		cycleCount 				= [[batteryStatus objectForKey:@"CycleCount"] intValue];
	}*/

	%orig;

	//Update the info on the alert if visible
	if (zealAlert != nil){
		getTitles();
		[zealAlert updateData:@{
			@"alertTitle" : titleA,
			@"alertMessage" : messageA,
			@"isCharging" : [NSNumber numberWithBool:isCharging],
			@"currentCapacity" : [NSString stringWithFormat:@"Current Capacity: %.0f mAh", (float) currentCapacity],
			@"maxCapacity" : [NSString stringWithFormat:@"Max Capacity: %.0f mAh",(float) maxCapacity],
			@"designCapacity" : [NSString stringWithFormat:@"Design Capacity: %.0f mAh",(float) designCapacity],
			@"temprature" : [NSString stringWithFormat:@"Temperature: %.1f°C", (float) temperature / 100],
			@"cycleCount" : [NSString stringWithFormat:@"Cycles: %.0f", (float) cycleCount],
			@"wearLevel" : [NSString stringWithFormat:@"Wear Level: %.0f", (1.0 - ((float) maxCapacity / designCapacity)) * 100],
			@"darkMode" : [NSNumber numberWithBool:darkModeAlert()],
			@"appsPerRow" : [NSNumber numberWithInt:switchesPerPage],

		}];
	}

	if (fullyCharged && notifyWhenFull) {
	    dispatch_once (&onceToken, ^{
	    	getTitles();
			[[objc_getClass("JBBulletinManager") sharedInstance] showBulletinWithTitle:@"Full Battery" message:@"Unplug device from charger" overrideBundleImage:[UIImage imageWithContentsOfFile:@"/Library/Application Support/Zeal/batteryBanner.png"] soundPath:[[NSBundle bundleWithIdentifier:@"com.apple.UIKit"] pathForResource:@"Tock" ofType:@"aiff"]];
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
	%init(shared);

	loadSettings();

	if(enabled){

		%init(Zeal);
		
		CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)loadSettings, CFSTR(PreferencesChangedNotification), NULL, CFNotificationSuspensionBehaviorCoalesce);
		CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)dissmissBanner, CFSTR(kRemoveBanner), NULL, 0);
		CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)ZealAction, CFSTR(kShowAlert), NULL, 0);
		CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)powerSavingModeSwitch, CFSTR(kPowerSaverMde), NULL, 0);
		CFNotificationCenterAddObserver(CFNotificationCenterGetDistributedCenter(),	NULL, changeBrightness,	CFSTR(kChangeBrightness), NULL,	CFNotificationSuspensionBehaviorDeliverImmediately);
		CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)removeAlert, CFSTR("com.apple.springboard.screenchanged"), NULL, 0);

	}

}
