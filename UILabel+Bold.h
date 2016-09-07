#import <UIKit/UIKit.h>

@interface UILabel (CustomUILabel)

- (void) boldSubstring: (NSString*) substring;
- (void) boldRange: (NSRange) range;

@end
