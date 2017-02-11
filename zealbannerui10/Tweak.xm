#import <Flipswitch/Flipswitch.h>

#if defined(__cplusplus)
extern "C" {
#endif
	CFNotificationCenterRef CFNotificationCenterGetDistributedCenter(void);
#if defined(__cplusplus)
}
#endif

@interface NCNotificationViewController : UIViewController
-(void)dismissViewControllerWithTransition:(int)arg1 completion:(id)arg2 ;
@end

@interface SpringBoard : UIApplication
-(void)adjustBrightness:(CGFloat)brightness isTracking:(BOOL)isTracking;
@end

@interface SBCCBrightnessSectionController : UIViewController
@end

@interface _CDBatterySaver : NSObject
+ (id)batterySaver;
- (int)getPowerMode;
- (int)setMode:(int)arg1;
- (BOOL)setPowerMode:(int)arg1 error:(id*)arg2;
@end

#define springBoard 					[NSClassFromString(@"SpringBoard") sharedApplication]
#define powerSaver 						[NSClassFromString(@"_CDBatterySaver") batterySaver]
#define kBounds 						[[UIScreen mainScreen] bounds]
#define kSettingsPath 					[NSHomeDirectory() stringByAppendingPathComponent:@"/Library/Preferences/com.rabih96.ZealPrefs.plist"]
#define kColorBannerSettingsPath 		[NSHomeDirectory() stringByAppendingPathComponent:@"/Library/Preferences/com.golddavid.colorbanners.plist"]
#define PreferencesChangedNotification	"com.rabih96.ZealPrefs.Changed"
#define kRemoveBanner					"com.rabih96.ZealPrefs.Dismiss"
#define kPowerSaverMde					"com.rabih96.ZealPrefs.PSM"
#define kChangeBrightness				"com.rabih96.ZealPrefs.Brightness"

#define AppIconSize 45
#define AppSpacing 	15
#define SETINT(NAME,KEY,INT) (NAME) = ([prefs objectForKey:@(KEY)] ? [[prefs objectForKey:@(KEY)] integerValue] : (INT))

static inline NSString* NSStringFromCGFloat(CGFloat value){
	return [NSString stringWithFormat:@"%f", value];
}

%group NotificationHook

static CGFloat calculateXPositionForAppNumber(int appNumber, int width, int appPerRow){
	float spacing = (width - (AppIconSize*appPerRow) - (AppSpacing*2))/(appPerRow-1);
	int pageNumber = floor((appNumber-1)/appPerRow);
	int pageWidth = pageNumber*width;
	if((appNumber-1) % appPerRow == 0)	return pageWidth + AppSpacing;
	else	return pageWidth + AppSpacing + ((appNumber-(pageNumber*appPerRow))-1)*(AppIconSize+spacing);
}

#define Alert(TITLE,MSG) 		[[[UIAlertView alloc] initWithTitle:(TITLE) message:(MSG) delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show]
	
UIButton *closeButton 		= nil;
UIButton *powerSavingButton = nil;
UIView 	 *lineView			= nil;
UIView 	 *lineView2			= nil;
UIImageView  *lowBright     = nil;
UIImageView  *highBright    = nil;


static int appsPerRow = 5;
static UISlider *brightnessSlider = nil;
static UIScrollView *flipSwitchScrollView;

@interface ZealBannerViewController : NCNotificationViewController
- (void)exit;
- (void)changeBrightness;
- (void)powerSavingMode;
@end

%subclass ZealBannerViewController : NCNotificationViewController

- (id)init{
	self = %orig;
	if(self){
			//self.view.backgroundColor = [UIColor colorWithWhite:0.22f alpha:0.33f];
	}
	return self;
}

- (void)viewDidLoad{
	%orig;

	NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:kSettingsPath];
	SETINT(appsPerRow, "switchesPerPageNC", 5);

	lowBright = [[UIImageView alloc] init];
	lowBright.image = [[UIImage imageWithContentsOfFile:@"/Library/Application Support/Zeal/lowBright.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
	[lowBright setTintColor:[UIColor grayColor]];
	[self.view addSubview:lowBright];

	highBright = [[UIImageView alloc] init];
	highBright.image = [[UIImage imageWithContentsOfFile:@"/Library/Application Support/Zeal/highBright.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
	[highBright setTintColor:[UIColor grayColor]];
	[self.view addSubview:highBright];

	brightnessSlider = [[UISlider alloc] init];
	brightnessSlider.value = [UIScreen mainScreen].brightness;
	brightnessSlider.minimumValue=0.0;
	brightnessSlider.maximumValue=0.99;
	[brightnessSlider addTarget:self action:@selector(changeBrightness) forControlEvents:UIControlEventValueChanged];
	brightnessSlider.tintColor = [UIColor grayColor];
	[self.view addSubview:brightnessSlider];

	closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[closeButton setTitle:@"Close" forState:UIControlStateNormal];
	[closeButton addTarget:self action:@selector(exit) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview:closeButton];

	lineView2 = [[UIView alloc] init];
	lineView2.backgroundColor = [UIColor colorWithRed:196.0/255 green:196.0/255 blue:201.0/255 alpha:0.5];
	[self.view addSubview:lineView2];

	lineView = [[UIView alloc] init];
	lineView.backgroundColor = [UIColor colorWithRed:196.0/255 green:196.0/255 blue:201.0/255 alpha:0.5];
	[self.view addSubview:lineView];

	CGSize size = self.view.bounds.size;

	brightnessSlider.frame = CGRectMake(30, 50, size.width-60, 50.0);
	powerSavingButton.frame = CGRectMake(20, 10, size.width-40, 30);
	lineView.frame = CGRectMake(0, 50, size.width, 0.5);
	lineView2.frame = CGRectMake(0, 100, size.width, 0.5);
	lowBright.frame = CGRectMake(5, 65, 20, 20);
	highBright.frame = CGRectMake(size.width-25, 65, 20, 20);

	powerSavingButton = [UIButton buttonWithType:UIButtonTypeCustom];
	powerSavingButton.contentEdgeInsets  = UIEdgeInsetsMake(0.0f, -5.0f, 0.0f, 0.0f);
	[powerSavingButton setTitle:([powerSaver getPowerMode] == 1) ? @"Deactivate battery saving mode" : @"Activate battery saving mode" forState:UIControlStateNormal];
	[powerSavingButton addTarget:self action:@selector(powerSavingMde) forControlEvents:UIControlEventTouchUpInside];
	powerSavingButton.backgroundColor = [UIColor colorWithRed:196.0/255 green:196.0/255 blue:201.0/255 alpha:0.5];
	powerSavingButton.layer.cornerRadius = 5.0;
	[powerSavingButton setClipsToBounds:YES];
	[self.view addSubview:powerSavingButton];

	NSBundle *templateBundle = [NSBundle bundleWithPath:@"/Library/Application Support/Zeal/ZealFSNC.bundle"];
	NSArray *enabledSwitchesArray = [[NSDictionary dictionaryWithContentsOfFile:kSettingsPath] objectForKey:@"EnabledIdentifiers"];

	if (enabledSwitchesArray == nil || [enabledSwitchesArray count] == 0) {
		enabledSwitchesArray = [NSArray arrayWithObjects:@"com.a3tweaks.switch.airplane-mode", @"com.a3tweaks.switch.wifi", @"com.a3tweaks.switch.bluetooth", @"com.a3tweaks.switch.do-not-disturb", @"com.a3tweaks.switch.rotation-lock", nil];
	}
	
	FSSwitchPanel *flipSwitchPanel = [FSSwitchPanel sharedPanel];

	if ([enabledSwitchesArray count] > 0){
		int i = 1;
		for(NSString *identifier in enabledSwitchesArray) {
			UIButton *flipSwitchButton = [flipSwitchPanel buttonForSwitchIdentifier:identifier usingTemplate:templateBundle];
			flipSwitchButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
			flipSwitchButton.frame = CGRectMake(calculateXPositionForAppNumber(i,size.width,appsPerRow), 112.5, AppIconSize, AppIconSize);
			[self.view addSubview:flipSwitchButton];
			if(i == appsPerRow) break;
			i++;
		}
	}

	if (dlopen("/Library/MobileSubstrate/DynamicLibraries/ColorBanners.dylib", RTLD_LAZY) && ([[[NSDictionary dictionaryWithContentsOfFile:kColorBannerSettingsPath] objectForKey:@"BannersEnabled"] boolValue] || [NSDictionary dictionaryWithContentsOfFile:kColorBannerSettingsPath] == nil)){
		[lowBright setTintColor:[UIColor whiteColor]];
		[highBright setTintColor:[UIColor whiteColor]];
		brightnessSlider.tintColor = [UIColor whiteColor];
		lineView2.backgroundColor = [UIColor whiteColor];
		lineView.backgroundColor = [UIColor whiteColor];
		powerSavingButton.backgroundColor = [UIColor colorWithRed:230.0/255 green:230.0/255 blue:230.0/255 alpha:0.5];
	}
}

- (void)viewWillDisappear:(_Bool)arg1{
	%orig;
	[powerSavingButton removeFromSuperview];
	[lineView removeFromSuperview];
	[lineView2 removeFromSuperview];
	[closeButton removeFromSuperview];
	[brightnessSlider removeFromSuperview];
}

- (void)viewDidLayoutSubviews{
	%orig;
	CGSize size = self.view.bounds.size;

	brightnessSlider.frame = CGRectMake(30, 50, size.width-60, 50.0);
	powerSavingButton.frame = CGRectMake(20, 10, size.width-40, 30);
	lineView.frame = CGRectMake(0, 50, size.width, 0.5);
	lineView2.frame = CGRectMake(0, 100, size.width, 0.5);
	lowBright.frame = CGRectMake(5, 65, 20, 20);
	highBright.frame = CGRectMake(size.width-25, 65, 20, 20);
}

- (CGFloat)preferredContentHeight{
	return 170.0;
}

%new
-(void)exit{
	[self dismissViewControllerWithTransition:1 completion:nil];
}

%new
- (void)changeBrightness{
	CFNotificationCenterPostNotification(CFNotificationCenterGetDistributedCenter(), CFSTR(kChangeBrightness), NULL, (__bridge CFDictionaryRef)@{ @"brightness": NSStringFromCGFloat([brightnessSlider value]) }, true);
}

%new
- (void)powerSavingMde{
	CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR(kPowerSaverMde), NULL, NULL, YES);
	if([powerSavingButton.titleLabel.text isEqualToString:@"Activate battery saving mode"]) [powerSavingButton setTitle:@"Deactivate battery saving mode" forState:UIControlStateNormal];
	else if([powerSavingButton.titleLabel.text isEqualToString:@"Deactivate battery saving mode"]) [powerSavingButton setTitle:@"Activate battery saving mode" forState:UIControlStateNormal];
	else [self dismissViewControllerWithTransition:1 completion:nil];
}

%end
%end

%ctor {
	NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
	if ([bundleID isEqualToString:@"com.apple.mobilesms.notification"]) {
		%init(NotificationHook);
	}
}
