#import <Preferences/PSListController.h>
#import <Foundation/Foundation.h>
#import <Preferences/PSSpecifier.h>
#import <Preferences/PSViewController.h>
#import <UIKit/UIKit.h>

@interface UIImage (Private)
+ (UIImage*)imageNamed:(NSString *)imageName inBundle:(NSBundle*)bundle;
@end

@interface ZealRootListController : PSListController<UIAlertViewDelegate>{
	UIDatePicker *fromPicker;
	UIDatePicker *toPicker;
}

@end
