#import "ZealHeaderView.h"

@implementation ZealHeaderView

- (void)layoutSubviews {
	[super layoutSubviews];
	heading.frame = CGRectMake(0, 15, self.frame.size.width, 50);
	subtitle.frame = CGRectMake(0, 50, self.frame.size.width, 50);
	self.backgroundColor = [UIColor clearColor];
}

- (id)initWithSpecifier:(PSSpecifier *)specifier {
	self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"headerCell" specifier:specifier];
	if (self) {
		int width = super.frame.size.width; //[[UIScreen mainScreen] bounds].size.width;

		CGRect frame = CGRectMake(0, 15, width, 50);
		CGRect subFrame = CGRectMake(0, 50, width, 50);

		heading = [[UILabel alloc] initWithFrame:frame];
		[heading setNumberOfLines:1];
		heading.font = [UIFont fontWithName:@"HelveticaNeue-UltraLight" size:48];
		[heading setText:@"Zeal"];
		[heading setBackgroundColor:[UIColor clearColor]];
		heading.textColor = [UIColor darkGrayColor];
		heading.textAlignment = NSTextAlignmentCenter;
		heading.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;

		subtitle = [[UILabel alloc] initWithFrame:subFrame];
		[subtitle setNumberOfLines:2];
		subtitle.font = [UIFont fontWithName:@"HelveticaNeue-UltraLight" size:16];
		[subtitle setText:@"Control your battery alerts."];
		[subtitle setBackgroundColor:[UIColor clearColor]];
		subtitle.textColor = [UIColor blackColor];
		subtitle.textAlignment = NSTextAlignmentCenter;
		subtitle.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;

        [self.contentView setBackgroundColor:[UIColor clearColor]];

		[self.contentView addSubview:heading];
		[self.contentView addSubview:subtitle];
	}

	return self;
}

- (CGFloat)preferredHeightForWidth:(double)arg1 inTableView:(id)arg2 {
	return 75.0;
}

@end
