#import "ZSegmentCell.h"

#define kBounds 						[[UIScreen mainScreen] bounds]
#define kBundlePath 					"/Library/PreferenceBundles/Zeal.bundle/"
#define kSettingsPath 					[NSHomeDirectory() stringByAppendingPathComponent:@"/Library/Preferences/com.rabih96.ZealPrefs.plist"]
#define PreferencesChangedNotification	@"com.rabih96.ZealPrefs.Changed"

@implementation ZSegmentCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier specifier:(PSSpecifier *)specifier{
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier specifier:specifier];

	if (self)
	{
		self.backgroundColor = [UIColor whiteColor];
		//titleArray = [specifier.properties[@"titleArray"] copy];
		imagesArray = [specifier.properties[@"imagesArray"] copy];

		NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:kSettingsPath];
		NSNumber *bannerModeKey = prefs[@"bannerMode"];

		NSMutableArray *itemArray = [[NSMutableArray alloc] init];
		for (NSString *imgName in imagesArray){
			[itemArray addObject:[UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/%@", @kBundlePath, imgName]]];
		}

		_segmentedControl = [[UISegmentedControl alloc] initWithItems:itemArray];
		_segmentedControl.frame = CGRectMake((kBounds.size.width - 320) * 0.5, 7.5, 320, 140);
		_segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
		[_segmentedControl addTarget:self action:@selector(segmentedControlValueDidChange:) forControlEvents: UIControlEventValueChanged];
		_segmentedControl.selectedSegmentIndex = bannerModeKey ? [bannerModeKey intValue] : 0;
		[_segmentedControl setDividerImage:[UIImage alloc] forLeftSegmentState:UIControlStateNormal rightSegmentState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
		_segmentedControl.layer.borderWidth = 0;
		_segmentedControl.tintColor = [UIColor colorWithRed:0.45 green:0.99 blue:0.69 alpha:1.0];
		[self.contentView addSubview:_segmentedControl];        
		[_segmentedControl release]; 
	}

	return self;
}

-(void)segmentedControlValueDidChange:(UISegmentedControl *)segment {
	NSUserDefaults *prefs = [[NSUserDefaults alloc] initWithSuiteName:@"com.rabih96.ZealPrefs"];
    [prefs setInteger:(int)segment.selectedSegmentIndex forKey:@"bannerMode"];
    [prefs synchronize];
	CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), (CFStringRef)PreferencesChangedNotification, NULL, NULL, YES);
}

@end
