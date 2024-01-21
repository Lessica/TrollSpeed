#import "TrollSpeed-Swift.h"

@interface RootViewController : UIViewController <TSSettingsControllerDelegate>
@property (nonatomic, strong) UIView *backgroundView;
+ (void)setShouldToggleHUDAfterLaunch:(BOOL)flag;
- (void)reloadMainButtonState;
@end
