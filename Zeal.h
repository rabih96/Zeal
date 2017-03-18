#import <AudioToolbox/AudioToolbox.h>
#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>
#import <libactivator/LAListener.h>
#import <CaptainHook/CaptainHook.h>
#import <Flipswitch/Flipswitch.h>
#import <substrate.h>
#import <dlfcn.h>
#import <BackBoardServices/BKSDisplayBrightness.h>
#import <SpringBoard/SpringBoard.h>
#import <SpringBoard/SBApplication.h>
#import "objc/runtime.h"
#import "notify.h"
#import "UNUserNotificationCenter.h"

#define SETBOOL(NAME,KEY,BOOL) (NAME) 				= ([prefs objectForKey:@(KEY)] ? [[prefs objectForKey:@(KEY)] boolValue] : (BOOL))
#define SETINT(NAME,KEY,INT) (NAME) 				= ([prefs objectForKey:@(KEY)] ? [[prefs objectForKey:@(KEY)] integerValue] : (INT))
#define SETTEXT(NAME,KEY) (NAME) 					= ([prefs objectForKey:@(KEY)] ? [prefs objectForKey:@(KEY)] : (NAME))

#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)

#define IS_IPHONE 									(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
#define IS_RETINA 									([[UIScreen mainScreen] scale] >= 2.0)

#define SCREEN_WIDTH 								([[UIScreen mainScreen] bounds].size.width)
#define SCREEN_HEIGHT 								([[UIScreen mainScreen] bounds].size.height)
#define SCREEN_MAX_LENGTH							(MAX(SCREEN_WIDTH, SCREEN_HEIGHT))
#define SCREEN_MIN_LENGTH 							(MIN(SCREEN_WIDTH, SCREEN_HEIGHT))
#define IS_ZOOMED 									(IS_IPHONE && SCREEN_MAX_LENGTH == 736.0)

#define IS_IPHONE_4_OR_LESS 						(IS_IPHONE && SCREEN_MAX_LENGTH < 568.0)
#define IS_IPHONE_5 								(IS_IPHONE && SCREEN_MAX_LENGTH == 568.0)
#define IS_IPHONE_6 								(IS_IPHONE && SCREEN_MAX_LENGTH == 667.0)
#define IS_IPHONE_6P								(IS_IPHONE && SCREEN_MAX_LENGTH == 736.0)

#define springBoard 								[NSClassFromString(@"SpringBoard") sharedApplication]
#define powerSaver 									[NSClassFromString(@"_CDBatterySaver") batterySaver]
#define kBounds 									[[UIScreen mainScreen] bounds]
#define kSettingsPath 								[NSHomeDirectory() stringByAppendingPathComponent:@"/Library/Preferences/com.rabih96.ZealPrefs.plist"]
#define PreferencesChangedNotification				"com.rabih96.ZealPrefs.Changed"
#define kRemoveBanner								"com.rabih96.ZealPrefs.Dismiss"
#define kPowerSaverMde								"com.rabih96.ZealPrefs.PSM"
#define kChangeBrightness							"com.rabih96.ZealPrefs.Brightness"
#define kShowAlert									"com.rabih96.ZealPrefs.showAlert"

#define AppIconSize 								45
#define AppSpacing 									15
#define AppsPerRow 									5
#define kBannerViewWidth  							!IS_IPHONE_5 ? 300 : 340

#define kOBJCIPCServer1 							@"com.rabih96.Zeal.orientation1"
#define kOBJCIPCServer2 							@"com.rabih96.Zeal.orientation2"

#define RGBA(R,G,B,A) 								[UIColor colorWithRed:R/255.0f green:G/255.0f blue:B/255.0f alpha:A]
#define BETWEEN(value, min, max) 					(value <= max && value >= min)

static BKSDisplayBrightnessTransactionRef _transaction;

#if defined(__cplusplus)
extern "C" {
#endif

CFNotificationCenterRef CFNotificationCenterGetDistributedCenter(void);

#if defined(__cplusplus)
}
#endif

static CGFloat calculateXPositionForAppNumber(int appNumber, int width, int appPerRow){
	float spacing = (width - (AppIconSize*appPerRow) - (AppSpacing*2))/(appPerRow-1);
	int pageNumber = floor((appNumber-1)/appPerRow);
	int pageWidth = pageNumber*width;
	if((appNumber-1) % appPerRow == 0)	return pageWidth + AppSpacing;
	else	return pageWidth + AppSpacing + ((appNumber-(pageNumber*appPerRow))-1)*(AppIconSize+spacing);
}

@interface PLBatteryPropertiesEntry : NSObject
+ (id)batteryPropertiesEntry;
@property(readonly, nonatomic) BOOL draining;
@property(readonly, nonatomic) BOOL isPluggedIn;
@property(readonly, nonatomic) NSString *chargingState;
@property(readonly, nonatomic) int batteryTemp;
@property(readonly, nonatomic) NSNumber *connectedStatus;
@property(readonly, nonatomic) NSNumber *adapterInfo;
@property(readonly, nonatomic) int chargingCurrent;
@property(readonly, nonatomic) BOOL fullyCharged;
@property(readonly, nonatomic) BOOL isCharging;
@property(readonly, nonatomic) int cycleCount;
@property(readonly, nonatomic) int designCapacity;
@property(readonly, nonatomic) double rawMaxCapacity;
@property(readonly, nonatomic) double maxCapacity;
@property(readonly, nonatomic) double rawCurrentCapacity;
@property(readonly, nonatomic) double currentCapacity;
@property(readonly, nonatomic) int current;
@property(readonly, nonatomic) int voltage;
@property(readonly, nonatomic) BOOL isCritical;
@property(readonly, nonatomic) double rawCapacity;
@property(readonly, nonatomic) double capacity;
@end

@interface SBWallpaperController : NSObject
+ (id)sharedInstance;
-(long long)activeOrientationSource;
@end

@interface SBCCBrightnessSectionController : UIViewController
@end

@interface UIImage (BBBulletin)
+(id)imageNamed:(id)named inBundle:(id)bundle;
-(id)imageScaledToSize:(CGSize)size cornerRadius:(CGFloat)corenrasd;
-(id)_imageScaledToProportion:(CGFloat)proportion interpolationQuality:(int)quality;
-(id)imageResizedTo:(CGSize)size preserveAspectRatio:(BOOL)preserve;
@end

@interface UIApplication(ActivateSuspended)
-(BOOL)launchApplicationWithIdentifier:(id)identifier suspended:(BOOL)s;
@end

@interface _CDBatterySaver : NSObject
+ (id)batterySaver;
- (int)getPowerMode;
- (int)setMode:(int)arg1;
- (BOOL)setPowerMode:(int)arg1 error:(id*)arg2;
@end

@interface SBUserAgent : NSObject
+ (SBUserAgent *)sharedUserAgent;
-(BOOL)deviceIsPasscodeLocked;
-(BOOL)deviceIsLocked;
- (void)undimScreen;
@end

@interface SBChevronView : UIView
@property(retain, nonatomic) UIColor *color;
- (id)initWithColor:(id)arg1;
- (void)setState:(int)state animated:(BOOL)animated;
@end

@interface SBControlCenterGrabberView : UIView
- (SBChevronView *)chevronView;
@end

@interface SBStatusBarStateAggregator
+ (id)sharedInstance;
- (void)_updateBatteryItems;
- (void)showThaAlert;
- (void)loadSettings;
@end

@class LAEvent;
@protocol LAListener, LAEventDataSource;

@interface LAActivator : NSObject
+ (LAActivator *)sharedInstance;
- (void)registerListener:(id<LAListener>)listener forName:(NSString *)name;
- (void)_updateBatteryItems;
- (BOOL)isOnAC;
- (int)batteryCapacityAsPercentage;
- (int)displayBatteryCapacityAsPercentage;
- (int)curvedBatteryCapacityAsPercentage;
@end


@interface NSObject ()
@property (assign,nonatomic) UIEdgeInsets clippingInsets;
@property (copy, nonatomic) NSString *message;
@property (copy, nonatomic) NSString *subtitle;
@property (copy, nonatomic) NSString *title;
@property (copy, nonatomic) NSString *sectionID;
@property (copy, nonatomic) id defaultAction;
+ (id)action;
+ (id)sharedInstance;
- (void)observer:(id)arg1 addBulletin:(id)arg2 forFeed:(NSInteger)arg3;
- (void)observer:(id)arg1 addBulletin:(id)arg2 forFeed:(NSInteger)arg3 playLightsAndSirens:(BOOL)arg4 withReply:(id)arg5;
- (void)_replaceIntervalElapsed;
- (void)_dismissIntervalElapsed;
- (BOOL)containsAttachments;
- (void)setSecondaryText:(id)arg1 italicized:(BOOL)arg2;
- (int)_ui_resolvedTextAlignment;

- (UILabel *)tb_titleLabel;
- (void)tb_setTitleLabel:(UILabel *)label;
- (void)tb_setSecondaryLabel:(UILabel *)label;

@end

@interface UIStatusBarItemView : UIView
@end

@interface UIStatusBarTimeItemView : UIStatusBarItemView{
	NSString *_timeString;
}
-(int)textStyle;
-(BOOL)cachesImage;
-(id)contentsImage;
-(BOOL)updateForNewData:(id)arg1 actions:(int)arg2;
@end

@interface SBAwayController : NSObject
+ (id)sharedAwayController;
- (BOOL)isLocked;
- (BOOL)isDimmed;
- (void)attemptUnlockFromSource:(int)source;
@end

@interface SBUIController : NSObject
+ (id)sharedInstance;
- (BOOL)isBatteryCharging;
- (BOOL)isOnAC;
- (void)ACPowerChanged;
- (int)batteryCapacityAsPercentage;
- (float)batteryCapacity;
- (int)displayBatteryCapacityAsPercentage;
- (int)curvedBatteryCapacityAsPercentage;
@end

@interface SBLockScreenViewController : NSObject
- (BOOL)isInScreenOffMode;
@end

@interface SBLockScreenManager : NSObject // iOS 7
+ (id)sharedInstanceIfExists;
+ (id)sharedInstance;
- (BOOL)isUILocked;
- (SBLockScreenViewController *)lockScreenViewController;
- (void)unlockUIFromSource:(NSInteger)source withOptions:(id)options;
- (void)_finishUIUnlockFromSource:(NSInteger)source withOptions:(id)options;
@end

@class BBDataProvider, BBBulletinRequest;

extern dispatch_queue_t __BBServerQueue;

extern void _BBDataProviderAddBulletinForDestinations(BBDataProvider *dataProvider, BBBulletinRequest *bulletin, NSUInteger destinations, BOOL addToLockScreen);
extern void BBDataProviderAddBulletinForDestinations(BBDataProvider *dataProvider, BBBulletinRequest *bulletin, NSUInteger destinations); // _BBDataProviderAddBulletinForDestinations: addToLockScreen = NO
extern void BBDataProviderAddBulletin(BBDataProvider *dataProvider, BBBulletinRequest *bulletin, BOOL allDestinations); // _BBDataProviderAddBulletinForDestinations: destinations = allDestinations ? 0xe : 0x2, addToLockScreen = NO
extern void BBDataProviderAddBulletinToLockScreen(BBDataProvider *dataProvider, BBBulletinRequest *bulletin); // _BBDataProviderAddBulletinForDestinations: destinations = 0x4, addToLockScreen = YES
extern void BBDataProviderModifyBulletin(BBDataProvider *dataProvider, BBBulletinRequest *bulletin); // _BBDataProviderAddBulletinForDestinations: destinations = 0x0, addToLockScreen = NO
extern void BBDataProviderWithdrawBulletinWithPublisherBulletinID(BBDataProvider *dataProvider, NSString *publisherBulletinID);
extern void BBDataProviderWithdrawBulletinsWithRecordID(BBDataProvider *dataProvider, NSString *recordID);
extern void BBDataProviderInvalidateBulletinsForDestinations(BBDataProvider *dataProvider, NSUInteger destinations);
extern void BBDataProviderInvalidateBulletins(BBDataProvider *dataProvider); // BBDataProviderInvalidateBulletinsForDestinations: destinations = 0x32
extern void BBDataProviderReloadDefaultSectionInfo(BBDataProvider *dataProvider);
extern void BBDataProviderSetApplicationBadge(BBDataProvider *dataProvider, NSInteger value);
extern void BBDataProviderSetApplicationBadgeString(BBDataProvider *dataProvider, NSString *value);

@interface BBDataProvider : NSObject
@end

@interface BBAppearance : NSObject
@property (copy, nonatomic) NSString *title;
+ (instancetype)appearanceWithTitle:(NSString *)title;
-(NSString *)viewClassName;
-(void)setViewClassName:(NSString *)arg1 ;
@end

@interface BBAction : NSObject
@property (copy, nonatomic) NSString *identifier;
@property (assign, nonatomic) NSInteger actionType;
@property (copy, nonatomic) BBAppearance *appearance;
@property (copy, nonatomic) NSString *launchBundleID;
@property (copy, nonatomic) NSURL *launchURL;
@property (copy, nonatomic) NSString *remoteServiceBundleIdentifier;
@property (copy, nonatomic) NSString *remoteViewControllerClassName;
@property (assign, nonatomic) BOOL canBypassPinLock;
@property (assign, nonatomic) BOOL launchCanBypassPinLock;
@property (assign, nonatomic) NSUInteger activationMode;
@property (assign ,nonatomic, getter=isAuthenticationRequired) BOOL authenticationRequired;
+ (instancetype)action;
+ (instancetype)actionWithIdentifier:(NSString *)identifier;
+ (instancetype)actionWithLaunchBundleID:(NSString *)bundleID;
@end

@interface BBBulletin : NSObject
- (NSArray *)_allActions;
- (NSArray *)_allSupplementaryActions;
- (NSArray *)supplementaryActions;
- (NSString *)section;
- (NSArray *)supplementaryActionsForLayout:(NSInteger)layout;
@end

@interface BBBulletinRequest : BBBulletin
@property (nonatomic,retain) NSString *bulletinID; 
@property (nonatomic,retain) NSString *title; 
@property (nonatomic,retain) NSString *subtitle; 
@property (nonatomic,retain) NSString *message; 
@property (nonatomic,retain) NSString *sectionID;
@property (nonatomic,retain) NSString *section; 
@property (nonatomic,retain) NSDictionary *context; 
@property (nonatomic,retain) id unlockActionLabel;
@property (nonatomic,retain) NSDate *date; 
@property (nonatomic,retain) NSDate *lastInterruptDate; 
@property (nonatomic,retain) NSDate *recencyDate; 
@property (nonatomic,retain) NSDate *endDate; 
@property (nonatomic,retain) NSDate *publicationDate; 
@property (nonatomic,assign) BOOL hasEventDate; 
@property (nonatomic,assign) BOOL clearable; 
@property (nonatomic,assign) int dateFormatStyle;
@property (nonatomic,assign) int messageNumberOfLines;
@property (nonatomic,assign) int sectionSubtype;
@property (nonatomic,assign) BOOL showsMessagePreview; 
@property (nonatomic,assign) BOOL suppressesMessageForPrivacy; 
@property (nonatomic,retain) NSString *unlockActionLabelOverride; 
@property (nonatomic,retain) NSString *bulletinVersionID; 
@property (nonatomic,retain) NSTimeZone *timeZone;
@property (assign,nonatomic) BOOL dateIsAllDay;
@property (nonatomic,retain) NSString *recordID;
@property (nonatomic,retain) NSString *publisherBulletinID;
- (void)setContextValue:(id)value forKey:(NSString *)key;
- (void)setSupplementaryActions:(NSArray *)actions;
- (void)setSupplementaryActions:(NSArray *)actions forLayout:(NSInteger)layout;
- (void)generateNewBulletinID;
@end

@interface BBObserver: NSObject
-(void)_setAttachmentImage:(id)image forKey:(id)akwy forBulletinID:(id)bullid;
-(void)_setAttachmentSize:(CGSize)size forKey:(id)akwy forBulletinID:(id)bullid;
@end

@interface BBServer : NSObject
- (BBDataProvider *)dataProviderForSectionID:(NSString *)sectionID;
- (NSSet *)allBulletinIDsForSectionID:(NSString *)sectionID;
- (NSSet *)bulletinIDsForSectionID:(NSString *)sectionID inFeed:(NSUInteger)feed;
- (NSSet *)bulletinsRequestsForBulletinIDs:(NSSet *)bulletinIDs;
- (NSSet *)bulletinsForPublisherBulletinIDs:(NSSet *)publisherBulletinIDs sectionID:(NSString *)sectionID;
- (void)_publishBulletinRequest:(BBBulletinRequest *)bulletinRequest forSectionID:(NSString *)sectionID forDestinations:(NSUInteger)destinations alwaysToLockScreen:(BOOL)alwaysToLockScreen;
- (void)publishBulletinRequest:(BBBulletinRequest *)bulletinRequest destinations:(NSUInteger)destinations alwaysToLockScreen:(BOOL)alwaysToLockScreen;
@end

@interface BBButton : NSObject
@property(copy) BBAction * action;
@property(copy) NSString * identifier;
@property(copy) NSString * title;
+ (id)buttonWithTitle:(id)arg1 action:(id)arg2;
+ (id)buttonWithTitle:(id)arg1 action:(id)arg2 identifier:(id)arg3;
+ (id)buttonWithTitle:(id)arg1 glyphData:(id)arg2 action:(id)arg3 identifier:(id)arg4;
+ (id)buttonWithTitle:(id)arg1 image:(id)arg2 action:(id)arg3 identifier:(id)arg4;
- (id)action;
- (id)identifier;
- (id)image;
- (id)title;
- (id)uniqueIdentifier;
@end

@interface BBServer (zeal)
+ (instancetype)sharedInstance;
@end

@protocol BBObserverDelegate <NSObject>
-(void)observer:(id)arg1 addBulletin:(id)arg2 forFeed:(NSInteger)arg3 playLightsAndSirens:(BOOL)arg4 withReply:(/*^block*/id)arg5;
-(void)observer:(id)arg1 addBulletin:(id)arg2 forFeed:(NSUInteger)arg3;
-(void)observer:(id)arg1 modifyBulletin:(id)arg2 forFeed:(NSUInteger)arg3;
-(void)observer:(id)arg1 modifyBulletin:(id)arg2;
-(void)observer:(id)arg1 removeBulletin:(id)arg2 forFeed:(NSUInteger)arg3;
-(void)observer:(id)arg1 removeBulletin:(id)arg2;
@end

@interface SBLockScreenNotificationListController : NSObject  <BBObserverDelegate>
@end

@interface SBBulletinBannerController : NSObject
+ (instancetype)sharedInstance;
- (void)modallyPresentBannerForBulletin:(BBBulletin *)bulletin action:(BBAction *)action;
@end

@interface SBUIBannerItem : NSObject
@end

@interface SBBulletinBannerItem : SBUIBannerItem
- (BBBulletin *)seedBulletin;
@end

@interface SBUIBannerContext : NSObject
@property (retain, nonatomic, readonly) SBBulletinBannerItem *item;
@end

@interface SBDefaultBannerTextView : UIView
@property (copy, nonatomic) NSString *primaryText;
@property (copy, nonatomic) NSString *secondaryText;
@property (nonatomic, readonly) UILabel *relevanceDateLabel;
- (void)layoutSubviews;
- (id)initWithFrame:(struct CGRect)arg1;
- (void)setRelevanceDate:(NSDate *)relevanceDate;
@end

@interface NCBulletinNotificationSource : NSObject
-(BBObserver*)observer;
@end

@interface SBNCNotificationDispatcher : NSObject
-(NCBulletinNotificationSource*)notificationSource;
@end

@interface UIApplication ()
- (id)_mainScene;
- (id)_keyWindowForScreen:(id)arg1;
- (SBApplication*) _accessibilityFrontMostApplication;
- (SBNCNotificationDispatcher*)notificationDispatcher;
@end

@interface SBDefaultBannerView : UIView {
	SBUIBannerContext *_context;
	SBDefaultBannerTextView *_textView;
	UIImageView *_attachmentImageView;
	UIImageView *_iconImageView;
}
- (id)initWithFrame:(CGRect)arg1;
- (id)initWithContext:(id)arg1;
- (CGRect)_contentFrame;
- (CGFloat)_secondaryContentInsetY;
- (CGFloat)_textInsetX;
- (CGFloat)_iconInsetY;
- (void)layoutSubviews;
- (SBUIBannerContext *)bannerContext;
@end

@interface SBBannerContextView : UIView {
	SBDefaultBannerView *_contentView;
	UIView *_separatorView;
	UIView *_contentContainerView;
	UIView *_accessoryView;
	UIView *_pullDownView;
	UIView *_pullDownContainerView;
	UIView *_secondaryContentView;
}
@property(nonatomic) BOOL grabberVisible;
@property(nonatomic) BOOL separatorVisible;
- (SBUIBannerContext *)bannerContext;
- (void)_layoutContentView;
- (void)_layoutContentContainerView;
- (void)_layoutSeparatorView;
- (void)_updateContentAlpha;
@end

@interface SBBannerController : NSObject {
	NSInteger _activeGestureType;
}
+ (instancetype)sharedInstance;
- (SBUIBannerContext *)_bannerContext;
- (SBBannerContextView *)_bannerView;
- (void)dismissBannerWithAnimation:(BOOL)animated reason:(NSInteger)reason;
- (void)_handleGestureState:(NSInteger)state location:(CGPoint)location displacement:(CGFloat)displacement velocity:(CGFloat)velocity;
- (BOOL)isShowingModalBanner;
- (BOOL)isShowingBanner;
@end

@interface SBBannerContainerView : UIView
@property(nonatomic) UIView *inlayContainerView;
@property(nonatomic) UIView *inlayView;
@property(nonatomic) UIView *backgroundView;
@end

@interface SBBannerContainerViewController : UIViewController {
	SBBannerContainerView *_containerView;
	CGFloat _maximumBannerHeight;
	CGRect _keyboardFrame;
}
@property(nonatomic) UIView *backgroundView;
@property(readonly, nonatomic) SBBannerContextView *bannerContextView;
@property(readonly, nonatomic) BOOL canPullDown;
- (BBBulletinRequest *)_bulletin;
- (CGFloat)_maximumPullDownViewHeight;
- (CGFloat)_bannerContentHeight;
- (CGFloat)_miniumBannerContentHeight;
- (CGFloat)preferredMaximumHeight;
- (CGFloat)_pullDownViewHeight;
- (CGFloat)_preferredPullDownViewHeight;
@end

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
@property (copy, nonatomic) NSDictionary *context;
@property (assign, nonatomic) CGFloat maximumHeight;
- (CGFloat)preferredContentHeight;
- (void)requestPreferredContentHeight:(CGFloat)height;
- (void)requestProximityMonitoringEnabled:(BOOL)enabled;
@end

@interface CPDistributedMessagingCenter : NSObject
+ (instancetype)centerNamed:(NSString *)name;
- (void)runServerOnCurrentThread;
- (void)stopServer;
- (void)registerForMessageName:(NSString *)message target:(id)target selector:(SEL)selector;
- (BOOL)sendNonBlockingMessageName:(NSString *)message userInfo:(NSDictionary *)userInfo;
- (NSDictionary *)sendMessageAndReceiveReplyName:(NSString *)message userInfo:(NSDictionary *)userInfo error:(NSError * __autoreleasing *)errpt;
@end

@interface FlipSwitchViewController : UIViewController
@property (retain, nonatomic) UIScrollView *scrollView;
-(CGFloat)calculateXPositionForAppNumber:(int)appNumber forWidth:(int)width;
@end

@interface CKInlineReplyViewController : NCInteractiveNotificationViewController
//@property (retain, nonatomic) CKMessageEntryView *entryView;
//@property (retain, nonatomic) CKScheduledUpdater *typingUpdater;
- (UITextView *)viewForTyping;
- (void)setupConversation;
- (void)setupView;
- (void)interactiveNotificationDidAppear;
- (void)updateSendButton;
- (void)updateTyping;
- (void)adjustBrightness;
@end

@interface CKInlineReplyViewController (zeal)
//@property (retain, nonatomic, readonly) CPDistributedMessagingCenter *messagingCenter;
@property (retain, nonatomic) FlipSwitchViewController *flipSwitchViewController;
/*@property (retain, nonatomic) CouriaContactsViewController *contactsViewController;
@property (retain, nonatomic) CouriaPhotosViewController *photosViewController;
- (void)photoButtonTapped:(UIButton *)button;*/
@end

@interface MyBatteryAlertsBannerViewController : CKInlineReplyViewController
@end

@interface SBNotificationSeparatorView : UIView {

	double _height;

}
+(long long)separatorViewModeForCurrentState;
+(id)separatorForCurrentState;
+(id)separatorWithScreenScale:(double)arg1 mode:(long long)arg2 ;
+(long long)blendMode;
+(id)color;
-(void)updateForCurrentState;
-(void)setFrame:(CGRect)arg1 ;
-(void)setBounds:(CGRect)arg1 ;
-(id)initWithFrame:(CGRect)arg1 mode:(long long)arg2 ;
@end

__attribute__((weak_import)) @interface BBSectionIconVariant: NSObject
+ (id)variantWithFormat:(int)format imageName:(NSString *)name inBundle:(NSBundle *)bundle;
@end

__attribute__((weak_import)) @interface BBSectionIcon: NSObject
- (void)addVariant:(BBSectionIconVariant *)variant;
@end


@interface NSTask : NSObject

// Create an NSTask which can be run at a later time
// An NSTask can only be run once. Subsequent attempts to
// run an NSTask will raise.
// Upon task death a notification will be sent
//   { Name = NSTaskDidTerminateNotification; object = task; }
//

- (id)init;

// set parameters
// these methods can only be done before a launch
- (void)setLaunchPath:(NSString *)path;
- (void)setArguments:(NSArray *)arguments;
- (void)setEnvironment:(NSDictionary *)dict;
	// if not set, use current
- (void)setCurrentDirectoryPath:(NSString *)path;
	// if not set, use current

// set standard I/O channels; may be either an NSFileHandle or an NSPipe
- (void)setStandardInput:(id)input;
- (void)setStandardOutput:(id)output;
- (void)setStandardError:(id)error;

// get parameters
- (NSString *)launchPath;
- (NSArray *)arguments;
- (NSDictionary *)environment;
- (NSString *)currentDirectoryPath;

// get standard I/O channels; could be either an NSFileHandle or an NSPipe
- (id)standardInput;
- (id)standardOutput;
- (id)standardError;

// actions
- (void)launch;

- (void)interrupt; // Not always possible. Sends SIGINT.
- (void)terminate; // Not always possible. Sends SIGTERM.

- (BOOL)suspend;
- (BOOL)resume;

// status
- (int)processIdentifier; 
- (BOOL)isRunning;

- (int)terminationStatus;

@end

@interface SBUIChevronView : UIView

- (void)setAnimationDuration:(double)arg1;
- (void)setBackgroundView:(id)arg1;
- (void)setColor:(id)arg1;
- (void)setState:(long long)arg1;
- (void)setState:(long long)arg1 animated:(bool)arg2;
- (void)setVibrantSettings:(id)arg1;
- (long long)state;

@end

@interface NCNotificationRequest : NSObject
@property (nonatomic,copy,readonly) NSString* sectionIdentifier;
@property (nonatomic,readonly) BBBulletin* bulletin;
@end

@interface SBDashBoardModalView : UIView
-(void)setSecondaryActionButtonText:(NSString *)arg1;
@end

@interface UIInterfaceAction : NSObject
+(id)actionWithTitle:(id)arg1 type:(long long)arg2 handler:(/*^block*/id)arg3 ;
-(id)handler;
-(void)setHandler:(id)arg1;
-(void)setType:(long long)arg1;
-(UIView *)customContentView;
+ (id)actionWithCustomContentViewController:(id)arg1;
+ (id)actionWithCustomContentView:(id)arg1;
-(void)_setIsFocused:(BOOL)arg1 ;
-(void)_setIsPreferred:(BOOL)arg1 ;
-(void)setEnabled:(BOOL)arg1 ;
@end

@interface _NCNotificationViewControllerView : UIView
-(id)contentView;
@end

@interface NCNotificationLongLookView : UIView
-(void)setInterfaceActions:(NSArray *)arg1;
-(NSArray *)interfaceActions;
-(UIView *)customContentView;
-(void)setCustomContentSize:(CGSize)arg1;
@end

@interface NCNotificationLongLookViewController : UIViewController
@property (nonatomic,retain) NCNotificationRequest * notificationRequest;
-(void)_handleCloseButton:(id)arg1 ;
@end

@interface SBDashBoardFullscreenNotificationViewController : UIViewController
@property (nonatomic,readonly) NCNotificationRequest* notificationRequest;
-(void)handlePrimaryActionForView:(id)arg1;
@end

@interface NCNotificationContentView : UIView
-(id)initWithStyle:(long long)arg1 ;
-(void)setAdjustsFontForContentSizeCategory:(BOOL)arg1 ;
-(BOOL)adjustsFontForContentSizeCategory;
-(UIView *)accessoryView;
-(void)setAccessoryView:(UIView *)arg1 ;
-(UIImage *)thumbnail;
-(void)setThumbnail:(UIImage *)arg1 ;
-(NSString *)secondaryText;
-(void)setPrimaryText:(NSString *)arg1 ;
-(void)setSecondaryText:(NSString *)arg1 ;
-(void)setHintText:(NSString *)arg1 ;
-(void)setMessageNumberOfLines:(unsigned long long)arg1 ;
-(BOOL)adjustForContentSizeCategoryChange;
-(void)setPreferredContentSizeCategory:(NSString *)arg1 ;
-(NSString *)primarySubtitleText;
-(void)setPrimarySubtitleText:(NSString *)arg1 ;
-(void)setThumbnailViewContentMode:(long long)arg1 ;
-(long long)thumbnailViewContentMode;
-(NSString *)hintText;
-(BOOL)showAdditionalMessageLines;
-(void)setShowAdditionalMessageLines:(BOOL)arg1 ;
@end