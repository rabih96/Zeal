#include "ZealRootListController.h"
#include "../UIAlertView+Blocks.h"

#define kSettingsPath 	[NSHomeDirectory() stringByAppendingPathComponent:@"/Library/Preferences/com.rabih96.ZealPrefs.plist"]
#define PreferencesChangedNotification	@"com.rabih96.ZealPrefs.Changed"

@implementation ZealRootListController

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"Root" target:self] retain];
	}

	return _specifiers;
}

- (void)respring
{
	system("killall backboardd");
}

-(id) readPreferenceValue:(PSSpecifier*)specifier {
	NSDictionary *tweakSettings = [NSDictionary dictionaryWithContentsOfFile:kSettingsPath];
	if (!tweakSettings [specifier.properties[@"key"]]) {
		return specifier.properties[@"default"];
	}
	return tweakSettings [specifier.properties[@"key"]];
}

-(void) setPreferenceValue:(id)value specifier:(PSSpecifier*)specifier {
	NSDictionary *tweakSettings = [NSDictionary dictionaryWithContentsOfFile:kSettingsPath];
	NSMutableDictionary *defaults = [NSMutableDictionary dictionary];
	[defaults addEntriesFromDictionary:tweakSettings];
	[defaults setObject:value forKey:specifier.properties[@"key"]];
	[defaults writeToFile:kSettingsPath atomically:YES];
	CFStringRef toPost = (CFStringRef)specifier.properties[@"PostNotification"];
	if(toPost) CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), toPost, NULL, NULL, YES);
}


- (id)navigationItem {
	UIImageView *navIconView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"battery.png" inBundle:[NSBundle bundleForClass:self.class]]];
	navIconView.contentMode = UIViewContentModeScaleAspectFit;
	navIconView.frame = CGRectMake([[UIScreen mainScreen] bounds].size.width/2 - 15, 7, 30, 30);

	UINavigationItem *item = [super navigationItem];
	UIButton *buttonTwitter = [UIButton buttonWithType:UIButtonTypeCustom];
	[buttonTwitter setImage:[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/Zeal.bundle/heart.png"] forState:UIControlStateNormal];
	buttonTwitter.frame = CGRectMake(5,0,35,35);
	UIBarButtonItem *heart = [[[UIBarButtonItem alloc] initWithCustomView:buttonTwitter] autorelease];
	[buttonTwitter addTarget:self action:@selector(shareTapped) forControlEvents:UIControlEventTouchUpInside];
	item.rightBarButtonItem = heart;
	item.titleView = navIconView;
	return item;
}

- (void)followMe:(id)specifier {
	if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tweetbot:"]]) {
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"tweetbot:///user_profile/rabih96"]];
	}

	else if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitterrific:"]]) {
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"twitterrific:///profile?screen_name=rabih96"]];
	}

	else if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tweetings:"]]) {
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"tweetings:///user?screen_name=rabih96"]];
	}

	else if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitter:"]]) {
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"twitter://user?screen_name=rabih96"]];
	}

	else {
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://mobile.twitter.com/rabih96"]];
	}
}

- (void)followNotMe:(id)specifier {
	if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tweetbot:"]]) {
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"tweetbot:///user_profile/StijnDV"]];
	}

	else if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitterrific:"]]) {
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"twitterrific:///profile?screen_name=StijnDV"]];
	}

	else if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tweetings:"]]) {
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"tweetings:///user?screen_name=StijnDV"]];
	}

	else if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitter:"]]) {
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"twitter://user?screen_name=StijnDV"]];
	}

	else {
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://mobile.twitter.com/StijnDV"]];
	}
}

- (void)shareTapped {
	NSString *text = @"I love #Zeal by @rabih96 and @StijnDV";

	if ([UIActivityViewController alloc]) {
		UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[text] applicationActivities:nil];
		[(UINavigationController *)[super navigationController] presentViewController:activityViewController animated:YES completion:NULL];
	}
}

- (void)pickThaTime{

	NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:kSettingsPath];

	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"From - Till" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Save", nil];
	UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 270, 130)];

	UIView *topLineView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 270, 0.5)];
	topLineView.backgroundColor = [UIColor blackColor];
	topLineView.alpha = 0.2;

	fromPicker = [[UIDatePicker alloc] initWithFrame:CGRectMake(-5,0, 140, 130)];
	fromPicker.datePickerMode = UIDatePickerModeTime;
	fromPicker.minuteInterval = 5;
	fromPicker.date = (NSDate *)[[NSDictionary dictionaryWithContentsOfFile:kSettingsPath] objectForKey:@"fromDate"];
	//[fromPicker addTarget:self action:@selector(dateChanged:) forControlEvents:UIControlEventValueChanged];

	UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(135, 0, 0.5, 130)];
	lineView.backgroundColor = [UIColor blackColor];
	lineView.alpha = 0.2;

	toPicker = [[UIDatePicker alloc] initWithFrame:CGRectMake(130,0, 140, 130)];
	toPicker.datePickerMode = UIDatePickerModeTime;
	toPicker.minuteInterval = 5;
	toPicker.date = (NSDate *)[[NSDictionary dictionaryWithContentsOfFile:kSettingsPath] objectForKey:@"tillDate"];

	[view addSubview:topLineView];
	[view addSubview:fromPicker];
	[view addSubview:lineView];
	[view addSubview:toPicker];

	[alert setValue:view forKey:@"accessoryView"];
	[alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex != [alertView cancelButtonIndex]) {
		NSDictionary *tweakSettings = [NSDictionary dictionaryWithContentsOfFile:kSettingsPath];
		NSMutableDictionary *defaults = [NSMutableDictionary dictionary];
		[defaults addEntriesFromDictionary:tweakSettings];
		[defaults setObject:[fromPicker date] forKey:@"fromDate"];
		[defaults setObject:[toPicker date] forKey:@"tillDate"];
		[defaults writeToFile:kSettingsPath atomically:YES];
		CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), (CFStringRef)PreferencesChangedNotification, NULL, NULL, YES);
	} 
}

@end

/*#import "header.h"

@implementation AlertStylePreviewCell

-(void)dealloc{
	[super dealloc];
}

-(void)layoutSubviews{
	[super layoutSubviews];
	_alertView.frame = self.frame;
}

-(id)initWithStyle:(long long)arg1 reuseIdentifier:(id)arg2{
    self = [super initWithStyle:arg1 reuseIdentifier:@"testCell"];
    if (self)
    {
    	_alertView = [[AlertStyleSelectionView alloc] initWithFrame:self.frame];
    	[_alertView setSelectedStyle:UITableViewCellStyleDefault];
    	[self.contentView addSubview:_alertView];
    }
    return self;
}

- (CGFloat)preferredHeightForWidth:(double)arg1 inTableView:(id)arg2 {
    return 100.0;
}

@end*/