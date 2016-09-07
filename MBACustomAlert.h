#import <UIKit/UIKit.h>
#import <CoreGraphics/CoreGraphics.h>

#define kBounds [[UIScreen mainScreen] bounds]

@interface SBChevronView : UIView
@property(retain, nonatomic) UIColor *color;
- (id)initWithColor:(id)arg1;
- (void)setState:(int)state animated:(BOOL)animated;
@end

@interface SBControlCenterGrabberView : UIView
- (SBChevronView *)chevronView;
@end

@interface MBACustomAlert : UIView{
 UIView *alert;
 UIView *swiper;
 CGRect alertFrame;
}
@property (nonatomic, retain) UIView *grabber;
@property (nonatomic, retain) UIView *dropDownView;
- (id)initWithFrame:(CGRect)frame title:(NSString *)title message:(NSString *)message customView:(UIView *)customView dropDownView:(UIView *)dropDownView nightMode:(BOOL)nightMode iconImage:(UIImage *)iconImage isCharging:(BOOL)isCharging;
@end
