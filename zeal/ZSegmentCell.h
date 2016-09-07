#import <Preferences/PSTableCell.h>
#import <Foundation/Foundation.h>
#import <Preferences/PSSpecifier.h>
#import <UIKit/UIKit.h>

@interface ZSegmentCell : PSTableCell {
    UISegmentedControl *_segmentedControl;

    //NSArray *titleArray; may be added in future updates
    NSArray *imagesArray;
}

@end