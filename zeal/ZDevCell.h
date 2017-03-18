#import <Preferences/PSTableCell.h>
#import <Foundation/Foundation.h>
#import <Preferences/PSSpecifier.h>
#import <UIKit/UIKit.h>

@interface ZDevCell : PSTableCell {
	NSString *name;
	NSString *twitterName;
	NSString *jobTitle;

	UIView *imageStorage;
	UIImageView *_devImageView;
	UILabel *_devNameLabel;
	UILabel *_jobLabel;
	UILabel *_twitterLabel;
}

@end
