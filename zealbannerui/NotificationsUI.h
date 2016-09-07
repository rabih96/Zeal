#import "Headers.h"
/*
@protocol NCInteractiveNotificationHostDelegate <NSObject>
@optional
-(void)hostViewControllerDidChangePreferredContentSize:(id)arg1;
-(void)hostViewController:(id)arg1 didRequestDismissalWithContext:(SBUIBannerContext *)ctx;
@end

@interface NCInteractiveNotificationViewController : UIViewController
@property (nonatomic,copy) NSDictionary * context;
-(void)handleActionAtIndex:(unsigned long long)arg1 ;
-(void)dismissWithContext:(id)arg1 ;
-(void)setActionEnabled:(BOOL)arg1 atIndex:(unsigned long long)arg2 ;
-(void)handleActionIdentifier:(id)arg1 ;
-(void)requestPreferredContentHeight:(double)arg1;
@end

@interface NCViewServiceDescriptor : NSObject
@property (nonatomic,copy,readonly) NSString * viewControllerClassName;
@property (nonatomic,copy,readonly) NSString * bundleIdentifier;
+(id)descriptorWithViewControllerClassName:(id)arg1 bundleIdentifier:(id)arg2 ;
@end

@interface NCContentViewController : UIViewController
@property (nonatomic,copy) NSDictionary * context;
@end*/

/////////////////////////////

@protocol NCInteractiveNotificationHostInterface
@required
- (void)_dismissWithContext:(NSDictionary *)context;
- (void)_requestPreferredContentHeight:(CGFloat)height;
- (void)_setActionEnabled:(BOOL)enabled atIndex:(NSUInteger)index;
- (void)_requestProximityMonitoringEnabled:(BOOL)enabled;
@end

@interface NCInteractiveNotificationHostViewController : UIViewController <NCInteractiveNotificationHostInterface>
@end

@protocol NCInteractiveNotificationServiceInterface
@required
- (void)_setContext:(NSDictionary *)context;
- (void)_getInitialStateWithCompletion:(id)completion;
- (void)_setMaximumHeight:(CGFloat)maximumHeight;
- (void)_setModal:(BOOL)modal;
- (void)_interactiveNotificationDidAppear;
- (void)_proximityStateDidChange:(BOOL)state;
- (void)_didChangeRevealPercent:(CGFloat)percent;
- (void)_willPresentFromActionIdentifier:(NSString *)identifier;
- (void)_getActionContextWithCompletion:(id)completion;
- (void)_getActionTitlesWithCompletion:(id)completion;
- (void)_handleActionAtIndex:(NSUInteger)index;
- (void)_handleActionIdentifier:(NSString *)identifier;
@end

@interface NCInteractiveNotificationViewController : UIViewController <NCInteractiveNotificationServiceInterface>
{
 BOOL _modal;
 NSDictionary *_context;
 float _maximumHeight;
}

+ (id)_exportedInterface;
+ (id)_remoteViewControllerInterface;
@property(nonatomic) float maximumHeight; // @synthesize maximumHeight=_maximumHeight;
@property(nonatomic, getter=isModal) BOOL modal; // @synthesize modal=_modal;
@property(copy, nonatomic) NSDictionary *context; // @synthesize context=_context;
- (void)viewDidLoad;
- (void)_willPresentFromActionIdentifier:(id)arg1;
- (void)_handleActionIdentifier:(id)arg1;
- (void)_proximityStateDidChange:(BOOL)arg1;
- (void)_handleActionAtIndex:(unsigned int)arg1;
- (void)_didChangeRevealPercent:(float)arg1;
- (void)_interactiveNotificationDidAppear;
- (void)_setMaximumHeight:(float)arg1;
- (void)_setModal:(BOOL)arg1;
- (void)_setContext:(id)arg1;
- (id)accessoryViewService;
- (id)inlayViewService;
- (void)handleActionIdentifier:(id)arg1;
- (void)proximityStateDidChange:(BOOL)arg1;
- (void)requestProximityMonitoringEnabled:(BOOL)arg1;
- (void)setActionEnabled:(BOOL)arg1 atIndex:(unsigned int)arg2;
- (void)handleActionAtIndex:(unsigned int)arg1;
- (id)actionTitles;
- (id)actionContext;
- (float)bottomOverhangHeight;
- (void)willPresentFromActionIdentifier:(id)arg1;
- (void)didChangeRevealPercent:(float)arg1;
- (void)interactiveNotificationDidAppear;
- (BOOL)showsKeyboard;
- (float)preferredContentHeight;
- (void)requestPreferredContentHeight:(float)arg1;
- (void)dismissWithContext:(id)arg1;
- (void)dealloc;

@end
