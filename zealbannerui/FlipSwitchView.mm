#import "../MBA.h"

#define AppIconSize 50
#define AppSpacing 25
#define AppsPerRow 5

@implementation FlipSwitchViewController

- (void)viewDidLoad
{
 [super viewDidLoad];
 //self.view.backgroundColor = [UIColor redColor];

 CGSize size = self.view.bounds.size;

 self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, size.width, 60)];
 self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
 self.scrollView.pagingEnabled = YES;
 self.scrollView.scrollsToTop = NO;
 self.scrollView.showsHorizontalScrollIndicator=NO;
 self.scrollView.showsVerticalScrollIndicator=NO;

 NSBundle *templateBundle = [NSBundle bundleWithPath:@"/Library/Application Support/FlipControlCenter/TopShelf.bundle"];
 FSSwitchPanel *fsp = [FSSwitchPanel sharedPanel];
 NSArray *array = [[NSDictionary dictionaryWithContentsOfFile:kSettingsPath] objectForKey:@"EnabledIdentifiers"];//[NSArray arrayWithObjects:@"com.a3tweaks.switch.airplane-mode", @"com.a3tweaks.switch.wifi", @"com.a3tweaks.switch.rotation", @"com.a3tweaks.switch.respring", @"com.a3tweaks.switch.flashlight", nil];

 int i = 1;
 for (NSString *identifier in array) {
  UIButton *button = [fsp buttonForSwitchIdentifier:identifier usingTemplate:templateBundle];
  button.frame = CGRectMake([self calculateXPositionForAppNumber:i forWidth:size.width],	(self.scrollView.frame.size.height-AppIconSize)/2, AppIconSize, AppIconSize);
  [self.scrollView addSubview:button];
  i++;
 }
 self.scrollView.contentSize = CGSizeMake( ceil(array.count/(AppsPerRow*1.0))*size.width, self.scrollView.frame.size.height);

 [self.view addSubview:self.scrollView];
}

-(CGFloat)calculateXPositionForAppNumber:(int)appNumber forWidth:(int)width{
 float spacing = (width - (AppIconSize*AppsPerRow) - (AppSpacing*2))/(AppsPerRow-1);
 int pageNumber = floor((appNumber-1)/AppsPerRow);
 int pageWidth = pageNumber*width;
 if((appNumber-1) % AppsPerRow == 0)	return pageWidth + AppSpacing;
 else	return pageWidth + AppSpacing + ((appNumber-(pageNumber*AppsPerRow))-1)*(AppIconSize+spacing);
}

@end
