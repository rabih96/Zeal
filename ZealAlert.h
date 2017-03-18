#import <UIKit/UIKit.h>
#import <CoreGraphics/CoreGraphics.h>
#import <UIKit/_UIBackdropView.h>
#import <UIKit/_UIBackdropViewSettings.h>
#include <tgmath.h>
#import "UILabel+Bold.h"

typedef void(^CompletionBlock)(void);

@interface ZealAlert : NSObject {
	UIWindow *zealWindow;

	UIView *backgroundView;
	UIView *alertView;
	UIView *swiper;
	UIView *grabber;
	UIView *lineView;
	UIView *lineView2;
	UIView *lineView3;
	UIView *lineView4;

	UIImageView *alertIcon;
	UIImageView *bolt;
	UIImageView *lowBright;	
	UIImageView *highBright;

	UILabel *titleLabel;
	UILabel *messageLabel;
	UILabel *currentAmps;
	UILabel *maxAmps;
	UILabel *temprature;
	UILabel *cycles;
	UILabel *designAmps;
	UILabel *wearLevel;

	CGFloat screenWidth;
	CGFloat screenHeight;
	CGFloat alertWidth;
	CGFloat alertX;
	CGFloat alertHeight;
	CGFloat alertY;

	NSDictionary *dict;
	CGRect alertFrame;
	UISlider *brightnessSlider;
	UIButton *powerSavingButton;
	UIScrollView *flipSwitchScrollView;
	BOOL darkMode;
	int appsPerRow;
	int kAlertWidth;
	int kAlertFontSize; //10-12
	int kAlertTextSpacing; //170-180
}

@property (nonatomic) BOOL animate;
@property (nonatomic) BOOL userInteraction;
@property (nonatomic, strong) CompletionBlock completion;

+(id)sharedManager;
-(id)initWithData:(NSDictionary *)data andOrientation:(UIInterfaceOrientation)orientation;
-(void)adjustViewForOrientation:(UIInterfaceOrientation)orientation animated:(BOOL)animateOrient;
-(void)_calculateRender;
-(void)_createAlert;
-(void)_showAlert;
-(void)_hideAlert;
-(void)updateData:(NSDictionary *)data;
-(void)loadAlertWithData:(NSDictionary *)dict orientation:(UIInterfaceOrientation)orientation;

@end