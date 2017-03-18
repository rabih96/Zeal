#import "UILabel+Bold.h"

@implementation UILabel (CustomUILabel)

- (void) boldRange: (NSRange)range {
	if (![self respondsToSelector:@selector(setAttributedText:)]) {
		return;
	}
	
	NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:self.text];
	[attributedText setAttributes:@{NSFontAttributeName:[UIFont boldSystemFontOfSize:self.font.pointSize]} range:range];

	self.attributedText = attributedText;
}

- (void) boldSubstring: (NSString*)substring {
	NSRange range = [self.text rangeOfString:substring];
	[self boldRange:range];
}

@end
