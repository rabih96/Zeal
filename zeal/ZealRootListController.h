#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import <Preferences/PSTableCell.h>
#import <Preferences/PSEditableListController.h>
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

#define kSettingsPath 					[NSHomeDirectory() stringByAppendingPathComponent:@"/Library/Preferences/com.rabih96.ZealPrefs.plist"]
#define PreferencesChangedNotification	@"com.rabih96.ZealPrefs.Changed"

@interface UIImage (Private)
+ (UIImage*)imageNamed:(NSString *)imageName inBundle:(NSBundle*)bundle;
@end

@interface ZealRootListController : PSListController
@end

@interface CustomPercentageList: PSEditableListController
@end

@interface AddCell : PSTableCell
@end