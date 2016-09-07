#import "MBACustomAlert.h"
#import "MBA.h"

#define DEBUG         0
#define RGBA(R,G,B,A) [UIColor colorWithRed:R/255.0f green:G/255.0f blue:B/255.0f alpha:A]

@interface _UIBackdropViewSettings : NSObject
+(id)settingsForPrivateStyle:(int)style;
@end

@interface _UIBackdropView : UIView
-(id)initWithFrame:(CGRect)frame autosizesToFitSuperview:(BOOL)resizes settings:(_UIBackdropViewSettings*)settings;
@end

@implementation MBACustomAlert

- (id)initWithFrame:(CGRect)frame title:(NSString *)title message:(NSString *)message customView:(UIView *)customView dropDownView:(UIView *)dropDownView nightMode:(BOOL)nightMode iconImage:(UIImage *)iconImage isCharging:(BOOL)isCharging
{
 self = [super initWithFrame:frame];
 if (self) {
  UIView *bg = [[UIView alloc] initWithFrame:self.frame];
  bg.center = self.center;
  bg.alpha = 0.3;
  bg.backgroundColor = [UIColor blackColor];
  [bg addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doneButtonClicked:)]];
  [self addSubview:bg];

  UIImageView *icon = [[UIImageView alloc] initWithFrame:CGRectMake(15,15,30,30)];
  icon.image = iconImage;

  UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(55, 15, 200, 15)];
  titleLabel.text = title;
  titleLabel.font = [UIFont boldSystemFontOfSize:14];
  titleLabel.numberOfLines = 1;
  titleLabel.backgroundColor = [UIColor clearColor];

  UILabel *messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(55, 30, 200, 15)];
  messageLabel.font = [UIFont systemFontOfSize:12];
  messageLabel.numberOfLines = 1;
  messageLabel.text = message;

  UIImageView *bolt = [[UIImageView alloc] initWithFrame:CGRectMake(270,20,20,20)];

  UIImage *image = [UIImage imageWithContentsOfFile:@"/Library/Application Support/Zeal/bolt.png"];
  bolt.image = image;
  bolt.image = [bolt.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
  [bolt setHidden:!isCharging];
  [bolt setTintColor:([powerSaver getPowerMode] == 1) ? [UIColor yellowColor] : [UIColor greenColor]];

  customView.frame = CGRectMake(0,65,310,customView.frame.size.height);

  swiper = [[UIView alloc] initWithFrame:CGRectMake(0,customView.frame.size.height+70,310,30)];

  _dropDownView = dropDownView;
  _dropDownView.frame = CGRectMake(0,customView.frame.size.height+65,310,dropDownView.frame.size.height);
  _dropDownView.alpha = 0.0;

  UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
  pan.maximumNumberOfTouches = pan.minimumNumberOfTouches = 1;
  [swiper addGestureRecognizer:pan];
  UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doneButtonClicked:)];
  [swiper addGestureRecognizer:tap];

  _grabber = [[NSClassFromString(@"SBControlCenterGrabberView") alloc] initWithFrame:CGRectMake(130, 6, 50, 22)];
  _grabber.transform = CGAffineTransformMakeRotation(M_PI);
  [[(SBControlCenterGrabberView *)_grabber chevronView] setState:0 animated:NO];
  [_grabber setUserInteractionEnabled:NO];
  [swiper addSubview:_grabber];

  alert = [[UIView alloc] initWithFrame:CGRectMake(0,0,310,customView.frame.size.height+100)];
  alert.center = self.center;
  alertFrame = alert.frame;
  if(nightMode){
   messageLabel.textColor = [UIColor whiteColor];
   titleLabel.textColor = [UIColor whiteColor];
   alert.backgroundColor = RGBA(40,40,40,1);//[UIColor blackColor];
   [(SBControlCenterGrabberView *)_grabber chevronView].color = [UIColor whiteColor];
   alert.alpha = 0.9;
  }else{
   messageLabel.textColor = [UIColor blackColor];
   titleLabel.textColor = [UIColor blackColor];
   alert.backgroundColor = RGBA(245,245,245,1);//[UIColor whiteColor];
   [(SBControlCenterGrabberView *)_grabber chevronView].color = [UIColor blackColor];
   alert.alpha = 0.975;
  }
  [[alert layer] setCornerRadius:20.0f];
  [[alert layer] setMasksToBounds:YES];
  [alert addSubview:titleLabel];
  [alert addSubview:messageLabel];
  [alert addSubview:customView];
  [alert addSubview:icon];
  [alert addSubview:bolt];
  [alert addSubview:swiper];
  [alert addSubview:_dropDownView];
  [self addSubview:alert];

  self.transform = CGAffineTransformMakeScale(1.1, 1.1);
  self.alpha = .6;
  [UIView animateWithDuration:.2 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
   self.transform = CGAffineTransformIdentity;
   self.alpha = 1;
  } completion:nil];

  if(DEBUG){
   titleLabel.backgroundColor = [UIColor redColor];
   messageLabel.backgroundColor = [UIColor redColor];
   customView.backgroundColor = [UIColor redColor];
   swiper.backgroundColor = [UIColor redColor];
  }
 }
 return self;
}

- (void)pan:(UIPanGestureRecognizer *)aPan {
 CGPoint currentPoint = [aPan locationInView:alert];
 [[(SBControlCenterGrabberView *)_grabber chevronView] setState:0 animated:YES];

 if ([aPan state] == UIGestureRecognizerStateChanged) {
  if((currentPoint.y >= alertFrame.size.height) && (currentPoint.y < alertFrame.size.height+75)){
   _dropDownView.alpha = (currentPoint.y-alertFrame.size.height)/50;
   [UIView animateWithDuration:0.01f animations:^{
    alert.frame = CGRectMake(alertFrame.origin.x, alertFrame.origin.y, alertFrame.size.width, currentPoint.y);
    //alert.center = self.center;
    swiper.frame = CGRectMake(0, alert.frame.size.height-30, 310, 30);
   }];
  }
 } else if ([aPan state] == UIGestureRecognizerStateEnded) {
  if (currentPoint.y > alertFrame.size.height+50) {
   [UIView animateWithDuration:0.25 animations:^{
    alert.frame = CGRectMake(alertFrame.origin.x, alertFrame.origin.y, alertFrame.size.width, alertFrame.size.height+50);
    //alert.center = self.center;
    swiper.frame = CGRectMake(0, alert.frame.size.height-30, 310, 30);
    _dropDownView.alpha = 1.0;
   }];
   [[(SBControlCenterGrabberView *)_grabber chevronView] setState:1 animated:YES];
  } else {
   [UIView animateWithDuration:0.25f animations:^{
    alert.frame = alertFrame;
    //alert.center = self.center;
    swiper.frame = CGRectMake(0, alert.frame.size.height-30, 310, 30);
    _dropDownView.alpha = 0.0;
   }];
  }
 }

}

- (void)buttonTouchesBegan:(id)sender{
 UIButton *btn = (UIButton*)sender;
 btn.backgroundColor = RGBA(173,216,230,0.25);
}

- (void)buttonTouchesCanceled:(id)sender{
 UIButton *btn = (UIButton*)sender;
 btn.backgroundColor = RGBA(0,0,0,0);
}

- (void)doneButtonClicked:(id)sender{
 self.transform = CGAffineTransformIdentity;
 [UIView animateWithDuration:.2 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
  self.alpha = .0;
 } completion:^(BOOL finished){
  [(SpringBoard *)[NSClassFromString(@"SpringBoard") sharedApplication] removeWindow];
 }];
}

@end
