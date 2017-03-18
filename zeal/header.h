#import <UIKit/UIView.h>

@class UIImageView, UILabel;

@interface AlertStyleView : UIView {

	UIImageView* _selectionImage;
	UILabel* _alertName;
	BOOL _isSelected;
	UIImageView* _alertStyleImageContentView;

}

@property (nonatomic,retain) UIImageView * alertStyleImageContentView;              //@synthesize alertStyleImageContentView=_alertStyleImageContentView - In the implementation block
@property (nonatomic,retain) UIImageView * selectionImage;                          //@synthesize selectionImage=_selectionImage - In the implementation block
@property (nonatomic,retain) UILabel * alertName;                                   //@synthesize alertName=_alertName - In the implementation block
@property (assign,nonatomic) BOOL isSelected;                                       //@synthesize isSelected=_isSelected - In the implementation block
+(id)selectionImageForView:(id)arg1 ;
-(UIImageView *)alertStyleImageContentView;
-(void)setAlertStyleImageContentView:(UIImageView *)arg1 ;
-(void)setSelectionImage:(UIImageView *)arg1 ;
-(void)setAlertName:(UILabel *)arg1 ;
-(UILabel *)alertName;
-(UIImageView *)selectionImage;
-(void)layoutSubviews;
-(id)initWithType:(id)arg1 ;
-(void)sizeToFit;
-(BOOL)isSelected;
-(void)setIsSelected:(BOOL)arg1 ;
@end

@class AlertStyleView;

@interface AlertStyleSelectionView : UIView {

	AlertStyleView* _noneAlertType;
	AlertStyleView* _topAlertType;
	AlertStyleView* _frontAlertType;
	unsigned long long _selectedStyle;

}

@property (assign,nonatomic) unsigned long long selectedStyle;              //@synthesize selectedStyle=_selectedStyle - In the implementation block
-(void)setSelectedStyle:(unsigned long long)arg1 ;
-(void)layoutAlertType:(id)arg1 withXPos:(float)arg2 ;
-(unsigned long long)selectedStyle;
-(id)initWithFrame:(CGRect)arg1 ;
-(void)layoutSubviews;
@end

#import <Preferences/PSTableCell.h>

@class UITapGestureRecognizer, AlertStyleSelectionView;

@interface AlertStylePreviewCell : PSTableCell {

	UITapGestureRecognizer* _tapRecognizer;
	AlertStyleSelectionView* _alertView;

}
-(void)dealloc;
-(void)layoutSubviews;
-(id)initWithStyle:(long long)arg1 reuseIdentifier:(id)arg2 ;
@end