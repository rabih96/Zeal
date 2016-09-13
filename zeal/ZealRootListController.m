#include "ZealRootListController.h"

#define kSettingsPath 	[NSHomeDirectory() stringByAppendingPathComponent:@"/Library/Preferences/com.rabih96.ZealPrefs.plist"]

@implementation ZealRootListController

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"Root" target:self] retain];
	}

	return _specifiers;
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

- (void)shareTapped {
	NSString *text = @"I love #Zeal by @rabih96.";

	if ([UIActivityViewController alloc]) {
		UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[text] applicationActivities:nil];
		[(UINavigationController *)[super navigationController] presentViewController:activityViewController animated:YES completion:NULL];
	}else {
		//too lazy for this
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