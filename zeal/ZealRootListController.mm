#include "ZealRootListController.h"
#include "../UIAlertView+Blocks.h"

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

/*- (void)followMe:(id)specifier {
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
}*/

- (void)shareTapped {
	NSString *text = @"I love #Zeal by @rabih96 and @StijnDV";

	if ([UIActivityViewController alloc]) {
		UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[text] applicationActivities:nil];
		[(UINavigationController *)[super navigationController] presentViewController:activityViewController animated:YES completion:NULL];
	}
}

- (void)pickThaTime {
	NSDictionary *tweakSettings = [NSDictionary dictionaryWithContentsOfFile:kSettingsPath];

	UIAlertController *timeAlertController = [UIAlertController alertControllerWithTitle:nil message:@"From - Till" preferredStyle:UIAlertControllerStyleAlert];

	UIViewController *datesViewController = [[UIViewController alloc] init];
	//UIView *controllerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 270, 130)];

	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateFormat:@"HH.mm"];

	NSDate *fromTime = (NSDate *)[tweakSettings objectForKey:@"fromDate"];
	if (fromTime == nil) fromTime = [dateFormatter dateFromString:@"20.00"];

	NSDate *tillTime = (NSDate *)[tweakSettings objectForKey:@"tillDate"];
	if (tillTime == nil) tillTime = [dateFormatter dateFromString:@"4.00"];

	UIView *topLineView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 270, 0.5)];
	topLineView.backgroundColor = [UIColor blackColor];
	topLineView.alpha = 0.2;

	UIDatePicker *fromPicker = [[UIDatePicker alloc] initWithFrame:CGRectMake(-5, -20, 140, 140)];
	fromPicker.datePickerMode = UIDatePickerModeTime;
	fromPicker.minuteInterval = 5;
	fromPicker.date = fromTime;

	UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(135, -10, 0.5, 160)];
	lineView.backgroundColor = [UIColor blackColor];
	lineView.alpha = 0.2;

	UIDatePicker *toPicker = [[UIDatePicker alloc] initWithFrame:CGRectMake(130, -20, 140, 140)];
	toPicker.datePickerMode = UIDatePickerModeTime;
	toPicker.minuteInterval = 5;
	toPicker.date = tillTime;

	[datesViewController.view addSubview:topLineView];
	[datesViewController.view addSubview:fromPicker];
	[datesViewController.view addSubview:lineView];
	[datesViewController.view addSubview:toPicker];

	[timeAlertController setValue:datesViewController forKey:@"contentViewController"];

	UIAlertAction *save = [UIAlertAction actionWithTitle:@"Save" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
		NSDictionary *tweakSettings = [NSDictionary dictionaryWithContentsOfFile:kSettingsPath];
		NSMutableDictionary *defaults = [NSMutableDictionary dictionary];
		[defaults addEntriesFromDictionary:tweakSettings];
		[defaults setObject:[fromPicker date] forKey:@"fromDate"];
		[defaults setObject:[toPicker date] forKey:@"tillDate"];
		[defaults writeToFile:kSettingsPath atomically:YES];
		CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), (CFStringRef)PreferencesChangedNotification, NULL, NULL, YES);
	}];
	
	UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDestructive handler:nil];
	
	[timeAlertController addAction:cancel];
	[timeAlertController addAction:save];

	[self presentViewController:timeAlertController animated:YES completion:NULL];
}

@end

/*@implementation CustomPercentageList

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section != 0)
		return NO;
	else
   		return [super tableView:tableView canEditRowAtIndexPath:indexPath];
}

- (void)viewDidLoad {
	NSMutableArray *regexes = [[NSMutableArray alloc] initWithContentsOfFile:kSettingsPath];
	if (regexes == nil)
		regexes = [[NSMutableArray alloc] init];
	if ([regexes count] == 0 || ([regexes[0] count] != 2))
		[regexes insertObject:@[@NO, @""] atIndex:0];
	[regexes writeToFile:kSettingsPath atomically:YES];

	[super viewDidLoad];
}

-(void)viewWillDisappear:(BOOL)arg1 {
	[super viewWillDisappear:arg1];
}

-(id)specifiers {
	if (!_specifiers) {
		NSMutableArray *specs = [NSMutableArray array];

		PSSpecifier *group = [PSSpecifier preferenceSpecifierNamed:@"Regexes"
			target:self
			set:NULL
			get:NULL
			detail:Nil
			cell:PSGroupCell
			edit:Nil];
		[specs addObject:group];

		NSArray *regexes = [[NSArray alloc] initWithContentsOfFile:kSettingsPath];

		for (int i = 1; i < [regexes count]; i++) {
			PSSpecifier *tempSpec = [PSSpecifier preferenceSpecifierNamed:regexes[i][2]
												  target:self
													 set:NULL
													 get:NULL
												  detail:NULL
													cell:PSLinkCell
													edit:Nil];
			[tempSpec setProperty:@(i) forKey:@"arrayIndex"];
			[tempSpec setProperty:NSStringFromSelector(@selector(deleteRegex:)) forKey:@"deletionAction"];
			[specs addObject:tempSpec];
		}

		//initialize add button
		PSSpecifier *button = [PSSpecifier preferenceSpecifierNamed:@""
			target:self
			set:NULL
			get:NULL
			detail:Nil
			cell:PSButtonCell
			edit:Nil];
		[button setButtonAction:@selector(addRegex)];
		[button setProperty:[AddCell class] forKey:@"cellClass"];
		[specs addObject:button];

		_specifiers = [[NSArray arrayWithArray:specs] retain];
	}

	return _specifiers;
}

- (void)deleteRegex:(PSSpecifier *)specifier {
	NSMutableArray *regexes = [[NSMutableArray alloc] initWithContentsOfFile:kSettingsPath];
	[regexes removeObjectAtIndex:([_specifiers indexOfObject:specifier])];
	[regexes writeToFile:kSettingsPath atomically:YES];
}

- (void)addRegex {
	NSMutableArray *regexes = [[NSMutableArray alloc] initWithContentsOfFile:kSettingsPath];
	regexes = (regexes != nil) ? regexes : [[NSMutableArray alloc] init];
	[regexes addObject:@[@YES, @YES, @""]];
	[regexes writeToFile:kSettingsPath atomically:YES];

	[self reloadSpecifiers];
}

-(id)readPreferenceValue:(PSSpecifier*)specifier {
	NSArray *regexes = [[NSArray alloc] initWithContentsOfFile:kSettingsPath];
	return regexes[0][1];
}

-(void)setPreferenceValue:(id)value specifier:(PSSpecifier*)specifier {
	NSMutableArray *regexes = [[NSMutableArray alloc] initWithContentsOfFile:kSettingsPath];
	regexes[0][1] = value;
	[regexes writeToFile:kSettingsPath atomically:YES];
}

-(void)viewWillAppear:(BOOL)arg1 {
	[self reloadSpecifiers];
	[super viewWillAppear:arg1];
}

@end

@implementation AddCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)identifier specifier:(PSSpecifier *)specifier {

 	id s = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell" specifier:specifier];

 	UIImage *image = [UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/Zeal.bundle/add.png"];
	UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
	imageView.frame = CGRectMake(6,self.frame.size.height*(1.0/8.0),self.frame.size.height*(3.0/4.0),self.frame.size.height*(3.0/4.0));

	[s addSubview:imageView];

	UILabel *label = [[UILabel alloc] init];
	label.text = @"Add Custom Percentage";
	label.font=[UIFont preferredFontForTextStyle:UIFontTextStyleBody];
	label.textColor = [UIColor colorWithRed:0.0f green:116.0f/255.0f blue:1.0f alpha:1.0f];
	[label sizeToFit];
	label.frame = CGRectMake(45,(self.frame.size.height - label.frame.size.height)/2,label.frame.size.width,label.frame.size.height);

	[s addSubview:label];

 	return s;
 }
@end*/