#import "NotificationsUI.h"
#import "ChatKit.h"
#import <Flipswitch/Flipswitch.h>
#import <BackBoardServices/BKSDisplayBrightness.h>
#include <notify.h>
#include <substrate.h>

@interface SpringBoard : UIApplication
-(void)adjustBrightness:(CGFloat)brightness isTracking:(BOOL)isTracking;
@end

@interface _CDBatterySaver : NSObject
+ (id)batterySaver;
- (int)getPowerMode;
- (int)setMode:(int)arg1;
- (BOOL)setPowerMode:(int)arg1 error:(id*)arg2;
@end

#define powerSaver [NSClassFromString(@"_CDBatterySaver") batterySaver]

extern "C" CFNotificationCenterRef CFNotificationCenterGetDistributedCenter(void);

static inline NSString* NSStringFromCGFloat(CGFloat value){
	return [NSString stringWithFormat:@"%f", value];
}

#define kBounds 						[[UIScreen mainScreen] bounds]
#define kSettingsPath 					@"/User/Library/Preferences/com.rabih96.ZealPrefs.plist"	//[NSHomeDirectory() stringByAppendingPathComponent:@"/Library/Preferences/com.rabih96.ZealPrefs.plist"]
#define PreferencesChangedNotification	"com.rabih96.ZealPrefs.Changed"
#define kRemoveBanner					"com.rabih96.ZealPrefs.Dismiss"
#define kPowerSaverMde					"com.rabih96.ZealPrefs.PSM"
#define kChangeBrightness				"com.rabih96.ZealPrefs.Brightness"

#define AppIconSize 45
#define AppSpacing 20
#define AppsPerRow 5
#define Alert(TITLE,MSG) 		[[[UIAlertView alloc] initWithTitle:(TITLE) message:(MSG) delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show]
	
UIButton *closeButton 		= nil;
UIButton *powerSavingButton = nil;
UIView 	 *lineView			= nil;
UIView 	 *lineView2			= nil;
UIImageView  *lowBright     = nil;
UIImageView  *highBright    = nil;

static UISlider *brightnessSlider = nil;

@interface CKInlineReplyViewController : NCInteractiveNotificationViewController
@end

@interface ZealBannerViewController : CKInlineReplyViewController
@property (nonatomic,retain) CKMessageEntryView *entryView;
- (CGFloat)calculateXPositionForAppNumber:(int)appNumber forWidth:(int)width;
- (void)exit;
- (void)changeBrightness;
- (void)powerSavingMode;
@end

%group NotificationHook

%subclass ZealBannerViewController : CKInlineReplyViewController

- (id)init{
	self = %orig;
	if(self){
			self.view.backgroundColor = [UIColor colorWithWhite:0.15f alpha:0.4f];
	}
	return self;
}

- (void)viewDidLoad{
	%orig;

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
	closeButton.frame = CGRectMake(0, size.height-30, size.width, 20);
	brightnessSlider.frame = CGRectMake(30, closeButton.frame.origin.y-70-60, size.width-60, 50.0);
	powerSavingButton.frame = CGRectMake(20, brightnessSlider.frame.origin.y-40, size.width-40, 30);
	lineView.frame = CGRectMake(0, brightnessSlider.frame.origin.y, size.width, 0.5);
	lineView2.frame = CGRectMake(0, brightnessSlider.frame.origin.y+brightnessSlider.frame.size.height, size.width, 0.5);
	lowBright.frame = CGRectMake(5,brightnessSlider.frame.origin.y+15,20,20);
	highBright.frame = CGRectMake(size.width-25,brightnessSlider.frame.origin.y+15,20,20);

	powerSavingButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[powerSavingButton setTitle:([powerSaver getPowerMode] == 1) ? @"Deactivate battery saving mode" : @"Activate battery saving mode" forState:UIControlStateNormal];
	[powerSavingButton addTarget:self action:@selector(powerSavingMde) forControlEvents:UIControlEventTouchUpInside];
	powerSavingButton.backgroundColor = [UIColor colorWithRed:196.0/255 green:196.0/255 blue:201.0/255 alpha:0.5];
	powerSavingButton.layer.cornerRadius = 5.0;
	[powerSavingButton setClipsToBounds:YES];
	[self.view addSubview:powerSavingButton];

	dlopen("/Library/MobileSubstrate/DynamicLibraries/Flipswitch.dylib", RTLD_NOW);

	NSArray	*array = [[[NSDictionary dictionaryWithContentsOfFile:kSettingsPath] objectForKey:@"EnabledIdentifiers"] subarrayWithRange:NSMakeRange(0, 5)];
	FSSwitchPanel 	*fsp			= [FSSwitchPanel sharedPanel];
	NSBundle 		*templateBundle = [NSBundle bundleWithPath:@"/Library/Application Support/FlipControlCenter/TopShelf8.bundle"];

	for(NSString *identifier in array) {
		__weak UIButton *button	= [fsp buttonForSwitchIdentifier:identifier usingTemplate:templateBundle];
		button.frame = CGRectMake([self calculateXPositionForAppNumber:[array indexOfObject:identifier]+1 forWidth:size.width],	size.height-100+(AppIconSize/2), AppIconSize, AppIconSize);
		[self.view addSubview:button];
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
	closeButton.frame = CGRectMake(0, size.height-30, size.width, 20);
	brightnessSlider.frame = CGRectMake(30, closeButton.frame.origin.y-70-60, size.width-60, 50.0);
	powerSavingButton.frame = CGRectMake(20, brightnessSlider.frame.origin.y-40, size.width-40, 30);
	lineView.frame = CGRectMake(0, brightnessSlider.frame.origin.y, size.width, 0.5);
	lineView2.frame = CGRectMake(0, brightnessSlider.frame.origin.y+brightnessSlider.frame.size.height, size.width, 0.5);
	lowBright.frame = CGRectMake(5,brightnessSlider.frame.origin.y+15,20,20);
	highBright.frame = CGRectMake(size.width-25,brightnessSlider.frame.origin.y+15,20,20);

	//[subview1 setNeedsLayout];

	/*dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		for(UIView *switches in scrollView.subviews){
			[switches removeFromSuperview];
		}

		dispatch_async(dispatch_get_main_queue(), ^{
			UIButton *button = nil;
			if(button != nil)	[button removeFromSuperview];

			int i = 1;

			NSArray	*array = [[NSDictionary dictionaryWithContentsOfFile:kSettingsPath] objectForKey:@"EnabledIdentifiers"];

			FSSwitchPanel 	*fsp	= [FSSwitchPanel sharedPanel];
			NSBundle 						*templateBundle 			= [NSBundle bundleWithPath:@"/Library/Application Support/FlipControlCenter/TopShelf8.bundle"];

			for(NSString *identifier in array) {
				button = [fsp buttonForSwitchIdentifier:identifier usingTemplate:templateBundle];
				button.frame = CGRectMake([self calculateXPositionForAppNumber:i forWidth:size.width],	(scrollView.frame.size.height-AppIconSize)/2, AppIconSize, AppIconSize);
				[scrollView addSubview:button];
				i++;
			}

			scrollView.contentSize = CGSizeMake( ceil(array.count/(AppsPerRow*1.0))*size.width, scrollView.frame.size.height);

		});
	});*/
}

- (CGFloat)preferredContentHeight{
	return 210.0;
}

%new
-(CGFloat)calculateXPositionForAppNumber:(int)appNumber forWidth:(int)width{
	float spacing = (width - (AppIconSize*AppsPerRow) - (AppSpacing*2))/(AppsPerRow-1);
	int pageNumber = floor((appNumber-1)/AppsPerRow);
	int pageWidth = pageNumber*width;
	if((appNumber-1) % AppsPerRow == 0)	return pageWidth + AppSpacing;
	else	return pageWidth + AppSpacing + ((appNumber-(pageNumber*AppsPerRow))-1)*(AppIconSize+spacing);
}

%new
-(void)exit{
	[self dismissWithContext:nil];
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
	else [self dismissWithContext:nil];
}

%end
%end

%ctor {
	NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
	if ([bundleID isEqualToString:@"com.apple.mobilesms.notification"]) {
		%init(NotificationHook);
	}
}
