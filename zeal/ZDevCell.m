#import "ZDevCell.h"

#define URL_ENCODE(string) 				[(NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)(string), NULL, CFSTR(":/=,!$& '()*+;[]@#?"), kCFStringEncodingUTF8) autorelease]
#define kBounds 						[[UIScreen mainScreen] bounds]
#define kBundlePath 					"/Library/PreferenceBundles/Zeal.bundle/"
#define kSettingsPath 					[NSHomeDirectory() stringByAppendingPathComponent:@"/Library/Preferences/com.rabih96.ZealPrefs.plist"]
#define PreferencesChangedNotification	@"com.rabih96.ZealPrefs.Changed"


#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations" 

@implementation ZDevCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier specifier:(PSSpecifier *)specifier{
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier specifier:specifier];

	if (self)
	{
		twitterName = [specifier.properties[@"twitterName"] copy];
		name = [specifier.properties[@"name"] copy];
		jobTitle = [specifier.properties[@"jobTitle"] copy];

		_devNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(85, 5, [[UIScreen mainScreen] bounds].size.width-80, 20)];
		_devNameLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		[_devNameLabel setText:[NSString stringWithFormat:@"%@", name]];
		[_devNameLabel setBackgroundColor:[UIColor clearColor]];
		[_devNameLabel setTextColor:[UIColor blackColor]];
		[_devNameLabel setFont:[UIFont fontWithName:@"Helvetica Light" size:18]];
		[self.contentView addSubview:_devNameLabel];

		_twitterLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.frame.size.width-85, 12.5, 80, 20)];
		_twitterLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		[_twitterLabel setText:jobTitle];
		[_twitterLabel setBackgroundColor:[UIColor clearColor]];
		[_twitterLabel setTextColor:[UIColor darkGrayColor]];
		[_twitterLabel setFont:[UIFont fontWithName:@"Helvetica Light" size:15]];
		_twitterLabel.textAlignment = UITextAlignmentRight;
		_twitterLabel.adjustsFontSizeToFitWidth = YES;
		_twitterLabel.minimumFontSize = 0;
		[self.contentView addSubview:_twitterLabel];

		_jobLabel = [[UILabel alloc] initWithFrame:CGRectMake(85, 25, [[UIScreen mainScreen] bounds].size.width-(_jobLabel.frame.origin.x-5), 20)];
		_jobLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		[_jobLabel setText:[NSString stringWithFormat:@"@%@", twitterName]];
		[_jobLabel setTextColor:[UIColor grayColor]];
		[_jobLabel setBackgroundColor:[UIColor clearColor]];
		[_jobLabel setFont:[UIFont fontWithName:@"Helvetica Light" size:15]];
		[self.contentView addSubview:_jobLabel];

		imageStorage = [[UIView alloc] initWithFrame:CGRectMake(27.5, 10, 40, 40)];
		imageStorage.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
		imageStorage.center = CGPointMake(imageStorage.center.x, self.contentView.frame.size.height / 2);
		imageStorage.userInteractionEnabled = NO;
		imageStorage.clipsToBounds = YES;
		imageStorage.layer.cornerRadius = 20;
		[self.contentView addSubview:imageStorage];

		_devImageView = [[UIImageView alloc] initWithFrame:imageStorage.bounds];
		_devImageView.image = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"/Library/PreferenceBundles/Zeal.bundle/%@.png", twitterName]];
		_devImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		_devImageView.userInteractionEnabled = NO;
		[self loadImages];
		[imageStorage addSubview:_devImageView];
	}

	return self;
}

- (void)loadImages {

	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		NSError *error = nil;
		NSData *data = [NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://twitter.com/%@/profile_image?size=bigger", URL_ENCODE(twitterName)]]] returningResponse:nil error:&error];

		if (error) return;

		dispatch_async(dispatch_get_main_queue(), ^{
			_devImageView.image = [UIImage imageWithData:data];
			[UIImagePNGRepresentation(_devImageView.image) writeToFile:[NSString stringWithFormat:@"/Library/PreferenceBundles/Zeal.bundle/%@.png", twitterName] atomically:YES];
			[UIView animateWithDuration:0.1 animations:^{
				_devImageView.alpha = 1;
			}];
		});
	});
}

- (void)follow:(NSString *)user
{
	if(user) {
		NSURL *twitterLink = nil;

		if([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tweetbot://"]]) {
			twitterLink = [NSURL URLWithString:[@"tweetbot:///user_profile/" stringByAppendingString:user]];
		} else if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitterrific://"]]) {
		twitterLink = [NSURL URLWithString:[@"twitterrific:///profile?screen_name=" stringByAppendingString:user]];
		} else if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitter://"]]) {
			twitterLink = [NSURL URLWithString:[@"twitter://user?screen_name=" stringByAppendingString:user]];
		} else {
			twitterLink = [NSURL URLWithString:[@"https://mobile.twitter.com/" stringByAppendingString:user]];
		}

		[[UIApplication sharedApplication] openURL:twitterLink];
	}
}

- (void)setSelected:(BOOL)pressed animated:(BOOL)anim
{
	if(!pressed)
	{
		[super setSelected:pressed animated:anim];
		return;
	}

	[self follow:twitterName];
}
@end

#pragma clang diagnostic pop
