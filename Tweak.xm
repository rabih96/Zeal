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

static NSMutableDictionary *extensions;
static NSUserDefaults *preferences;
static SBBulletinBannerController *bulletinBannerController;
static SBBannerController *bannerController;
static ZealAlert *zealAlert = nil;

static int 			 currentCapacity,	maxCapacity,	instantAmperage, designCapacity,	cycleCount,	temperature, orient;
static BOOL 		 locked = YES, darkMode, active, isCharging, externalConnected,	externalChargeCapable, fullyCharged, enabled, customTMA, customTMB,	customSD, shouldShowBanner = NO;
static NSInteger 	 batteryLevel = 100, customLevel, bannerMode, bannerTapAction, soundPicked;
static NSString 	 *titleA, *messageA, *titleB, *messageB, *customTitleA, *customTitleB, *customMessageA, *customMessageB;
static UIScrollView  *scrollView;

@interface UIApplication(ActivateSuspended)
-(BOOL)launchApplicationWithIdentifier:(id)identifier suspended:(BOOL)s;
@end

void loadSettings(){
	NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:kSettingsPath];

	SETBOOL(enabled, "enabled", 0);
	SETBOOL(darkMode, "darkMode", 0);
	SETINT(bannerMode, "bannerMode", 1);
	SETBOOL(customTMA, "customTMA", 0);
	SETBOOL(customTMB, "customTMB", 0);
	SETTEXT(customTitleA, "customTitleA");
	SETTEXT(customTitleB, "customTitleB");
	SETTEXT(customMessageA, "customMessageA");
	SETTEXT(customMessageB, "customMessageB");

	NSNumber *bannerTapActionKey = prefs[@"bannerTapAction"];
	bannerTapAction = bannerTapActionKey ? [bannerTapActionKey intValue] : 1;

	SETINT(soundPicked, "soundPicked", 4095);

	NSNumber *customLevelKey = prefs[@"customLevel"];
	customLevel = [customLevelKey intValue];

	NSNumber *customSDKey = prefs[@"customSD"];
	customSD = customSDKey ? [customSDKey boolValue] : 0;

}

////////////////////////Future updates////////////////////////
/*static BOOL darkMode(){
	NSDate *date = [NSDate date];
	NSDateFormatter *dateFormatter;
	dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setTimeZone:[NSTimeZone localTimeZone]];
	[dateFormatter setDateFormat:@"HH"];

	NSString *dateString = [dateFormatter stringFromDate:date];
	int timeInt = [dateString intValue];
	if((timeInt >= 20) || (timeInt <= 3)) return YES;
	else return NO;
}*/
//////////////////////////////////////////////////////////////

NSString *formatTimeFromSeconds(int numberOfSeconds){

    int seconds = numberOfSeconds % 60;
    int minutes = (numberOfSeconds / 60) % 60;
    int hours = numberOfSeconds / 3600;

    if (hours) return [NSString stringWithFormat:@"%dh %02dmin", hours, minutes];
    if (minutes) return [NSString stringWithFormat:@"%dmin %02dsec", minutes, seconds];
    return [NSString stringWithFormat:@"%dsec", seconds];
}

void getTitles(){
	if([[[UIDevice currentDevice] systemVersion] floatValue] < 8.0)
		batteryLevel = (int)[[objc_getClass("SBUIController") sharedInstance] curvedBatteryCapacityAsPercentage];
	else
		batteryLevel = (int)[[objc_getClass("SBUIController") sharedInstance] batteryCapacityAsPercentage];

	NSString *batteryTitle = nil;

	if (fullyCharged){
		batteryTitle = @"Full Battery";		
	}else if (batteryLevel<100 && batteryLevel>90){
		batteryTitle = @"Almost Full Battery";
	}else if (batteryLevel<=90 && batteryLevel>65){
		batteryTitle = @"Partially Full Battery";
	}else if (batteryLevel<=65 && batteryLevel>45){
		batteryTitle = @"Half Full Battery";
	}else if (batteryLevel<=45 && batteryLevel>20){
		batteryTitle = @"Partially Low Battery";
	}else if (batteryLevel<=20){
		batteryTitle = @"Low Battery";
	}

	NSString *batteryMessage = nil;

	if (isCharging){
		batteryMessage = [NSString stringWithFormat:@"Time left to fully charge ≅ %@", formatTimeFromSeconds((int)((maxCapacity - currentCapacity) / abs(instantAmperage) * 0.7))];
	}else{
		batteryMessage = [NSString stringWithFormat:@"Usage time left ≅ %@", formatTimeFromSeconds((int)roundf( (float)currentCapacity / abs(instantAmperage) * 2520.0 ))];
	}

	titleA = customTMA ? customTitleA : batteryTitle;
	messageA = customTMA ? customMessageA : batteryMessage;

	if(customTMB){
		titleB = customTitleB;
		messageB = customMessageB;
	}else{
		titleB = batteryTitle;
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

CGFloat calculateXPositionForAppNumber(int appNumber, int width){
	float spacing = (width - (AppIconSize*AppsPerRow) - (AppSpacing*2))/(AppsPerRow-1);
	int pageNumber = floor((appNumber-1)/AppsPerRow);
	int pageWidth = pageNumber*width;
	if((appNumber-1) % AppsPerRow == 0)	return pageWidth + AppSpacing;
	else	return pageWidth + AppSpacing + ((appNumber-(pageNumber*AppsPerRow))-1)*(AppIconSize+spacing);
}

void showAlert(void){
	getTitles();

	if (!active && !locked) {

		NSString *appIdentifier = [(SpringBoard *)[UIApplication sharedApplication] _accessibilityFrontMostApplication].bundleIdentifier;
		UIInterfaceOrientation startOrientation;

		[[NSNotificationCenter defaultCenter] addObserver:springBoard selector:@selector(orientationChange:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];

		if(appIdentifier) {
			NSDictionary *reply = [OBJCIPC sendMessageToAppWithIdentifier:appIdentifier messageName:kOBJCIPCServer1 dictionary:nil];
			startOrientation = [reply[@"currentOrientation"] longLongValue];
		} else {
			startOrientation = [[UIApplication sharedApplication] statusBarOrientation];
		}

		zealAlert = [[ZealAlert alloc] init];
		active = true;

		NSDictionary *data = @{
			@"alertTitle" : [NSString stringWithFormat:@"%@ %.0f%%", titleA,((float) currentCapacity / maxCapacity) * 100],
			@"alertMessage" : messageA,
			@"isCharging" : [NSNumber numberWithBool:isCharging],
			@"currentCapacity" : [NSString stringWithFormat:@"Current Capacity: %.0f mAh", (float) currentCapacity],
			@"maxCapacity" : [NSString stringWithFormat:@"Max Capacity: %.0f mAh",(float) maxCapacity],
			@"designCapacity" : [NSString stringWithFormat:@"Design Capacity: %.0f mAh",(float) designCapacity],
			@"temprature" : [NSString stringWithFormat:@"Temperature: %.1f°C", (float) temperature / 100],
			@"cycleCount" : [NSString stringWithFormat:@"Cycles: %.0f", (float) cycleCount],
			@"wearLevel" : [NSString stringWithFormat:@"Wear Level: %.0f%%", (1.0 - ((float) maxCapacity / designCapacity)) * 100],
			@"darkMode" : [NSNumber numberWithBool:darkMode],
		};

		zealAlert.completion = ^{
			zealAlert = nil;
			[[NSNotificationCenter defaultCenter] removeObserver:springBoard name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
			active = false;
		};

		[zealAlert loadAlertWithData:data orientation:startOrientation];
		
		if (customSD) AudioServicesPlaySystemSound(soundPicked);	
	}
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

static inline void presentController() {
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

void dispatchAfter(CGFloat delay, void (^block)(void)) {
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^(void) {
		block();
	});
}

void showBanner(){
	SBBannerController *bannerController = [NSClassFromString(@"SBBannerController") sharedInstance];
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

void ZealAction(){
	if(shouldShowBanner && !locked){
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

	//Update the info on the alert if visible
	if (zealAlert != nil){
		getTitles();
		[zealAlert updateData:@{
			@"alertTitle" : [NSString stringWithFormat:@"%@ %.0f%%", titleA,((float) currentCapacity / maxCapacity) * 100],
			@"alertMessage" : messageA,
			@"isCharging" : [NSNumber numberWithBool:isCharging],
			@"currentCapacity" : [NSString stringWithFormat:@"Current Capacity: %.0f mAh", (float) currentCapacity],
			@"maxCapacity" : [NSString stringWithFormat:@"Max Capacity: %.0f mAh",(float) maxCapacity],
			@"designCapacity" : [NSString stringWithFormat:@"Design Capacity: %.0f mAh",(float) designCapacity],
			@"temprature" : [NSString stringWithFormat:@"Temperature: %.1f°C", (float) temperature / 100],
			@"cycleCount" : [NSString stringWithFormat:@"Cycles: %.0f", (float) cycleCount],
			@"wearLevel" : [NSString stringWithFormat:@"Wear Level: %.0f", (1.0 - ((float) maxCapacity / designCapacity)) * 100],
			@"darkMode" : [NSNumber numberWithBool:darkMode],
		}];
	}

	if (fullyCharged) {
		//do smthg.
	}
}

%new
- (void)powerSavingMode{
	[powerSaver setMode:![powerSaver getPowerMode]];
}

-(void)_handleMenuButtonEvent {
	if(zealAlert != nil) [zealAlert _hideAlert];
	else %orig;
}

-(void)_menuButtonWasHeld {
	if(zealAlert != nil) [zealAlert _hideAlert];
	%orig;
}

-(void)handleMenuDoubleTap {
	if(zealAlert != nil) [zealAlert _hideAlert];
	%orig;
}

-(void)_lockButtonDown:(id)arg1 fromSource:(int)arg2{
	if(zealAlert != nil) [zealAlert _hideAlert];
	%orig;
}

-(void)_lockButtonUp:(id)arg1 fromSource:(int)arg2{
	%orig;
	//[UIAlertView showWithTitle:@"Zeal" message:@"Locked" cancelButtonTitle:@"Cancel" otherButtonTitles:@[] tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {}];
	locked = YES;
}

%end

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

	locked = NO;

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

/*Alert Items Controller*/

%hook SBAlertItemsController

- (void)activateAlertItem:(id)item{
	if ([item isKindOfClass:%c(SBLowPowerAlertItem)]) {
		shouldShowBanner = YES;
		ZealAction();
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
			ZealAction();
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
	ZealAction();
}

%end

/*%hook SBControlCenterController 
-(id)init {
	if(zealAlert != nil) return nil;
	return %orig;
}
%end

%hook SBNotificationCenterController 
-(id)init {
	if(zealAlert != nil) return nil;
	return %orig;
}
%end*/

%ctor{
	[OBJCIPC registerIncomingMessageFromAppHandlerForMessageName:kOBJCIPCServer2 handler:^NSDictionary *(NSDictionary *message) {
		if(active && zealAlert != nil) {
			[zealAlert adjustViewForOrientation:[message[@"orientation"] longLongValue] animated:YES];
		}
		return nil;
	}];

	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)loadSettings, CFSTR(PreferencesChangedNotification), NULL, CFNotificationSuspensionBehaviorCoalesce);
	loadSettings();
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)dissmissBanner, CFSTR(kRemoveBanner), NULL, 0);
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)ZealAction, CFSTR(kShowAlert), NULL, 0);
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)powerSavingMde, CFSTR(kPowerSaverMde), NULL, 0);
	CFNotificationCenterAddObserver(CFNotificationCenterGetDistributedCenter(),	NULL, changeBrightness,	CFSTR(kChangeBrightness), NULL,	CFNotificationSuspensionBehaviorDeliverImmediately);
}
