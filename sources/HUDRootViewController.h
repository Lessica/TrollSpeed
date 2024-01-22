#import <UIKit/UIKit.h>

@interface HUDRootViewController: UIViewController
+ (BOOL)passthroughMode;
- (void)resetLoopTimer;
- (void)stopLoopTimer;
@end
