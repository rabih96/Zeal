#import "ZStepperCell.h"
#import <Preferences/PSSpecifier.h>
#import <version.h>

#define kBounds 						[[UIScreen mainScreen] bounds]
#define kBundlePath 					"/Library/PreferenceBundles/Zeal.bundle/"
#define kSettingsPath 					[NSHomeDirectory() stringByAppendingPathComponent:@"/Library/Preferences/com.rabih96.ZealPrefs.plist"]
#define PreferencesChangedNotification	@"com.rabih96.ZealPrefs.Changed"

extern NSString *const PSControlMinimumKey;
extern NSString *const PSControlMaximumKey;

@implementation ZStepperCell

@dynamic control;

#pragma mark - PSTableCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier specifier:(PSSpecifier *)specifier {
	self = [super initWithStyle:style reuseIdentifier:reuseIdentifier specifier:specifier];

	if (self) {
		self.accessoryView = self.control;
	}

	return self;
}

- (void)refreshCellContentsWithSpecifier:(PSSpecifier *)specifier {
	[super refreshCellContentsWithSpecifier:specifier];

	self.control.minimumValue = ((NSNumber *)specifier.properties[PSControlMinimumKey]).integerValue;
	self.control.maximumValue = ((NSNumber *)specifier.properties[PSControlMaximumKey]).integerValue;
	[self _updateLabel];
}

#pragma mark - PSControlTableCell

- (UIStepper *)newControl {
	UIStepper *stepper = [[UIStepper alloc] initWithFrame:CGRectMake(0,0,0,0)];
	stepper.continuous = NO;
	return stepper;
}

- (NSNumber *)controlValue {
	return @(self.control.value);
}

- (void)setValue:(NSNumber *)value {
	[super setValue:value];
	self.control.value = value.doubleValue;
}

- (void)controlChanged:(UIStepper *)stepper {
	[super controlChanged:stepper];
	[self _updateLabel];
}

- (void)_updateLabel {
	if (!self.control) {
		return;
	}

	self.textLabel.text = [NSString stringWithFormat:self.specifier.name, (int)self.control.value];
	[self setNeedsLayout];
}

#pragma mark - UITableViewCell

- (void)prepareForReuse {
	[super prepareForReuse];

	self.control.value = 0;
	self.control.minimumValue = 0;
	self.control.maximumValue = 100;
}

/*
-(void)segmentedControlValueDidChange:(UISegmentedControl *)segment {
    NSDictionary *tweakSettings = [NSDictionary dictionaryWithContentsOfFile:kSettingsPath];
	NSMutableDictionary *defaults = [NSMutableDictionary dictionary];
	[defaults addEntriesFromDictionary:tweakSettings];
	[defaults setObject:[NSNumber numberWithInteger:[segment selectedSegmentIndex]] forKey:@"bannerMode"];
	[defaults writeToFile:kSettingsPath atomically:YES];
	CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), (CFStringRef)PreferencesChangedNotification, NULL, NULL, YES);
}*/

@end