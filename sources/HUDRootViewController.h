#import "UIApplicationRotationFollowingControllerNoTouches.h"

#if NO_TROLL
@interface HUDRootViewController: UIViewController
#else
@interface HUDRootViewController: UIApplicationRotationFollowingControllerNoTouches
#endif
+ (BOOL)passthroughMode;
- (void)resetLoopTimer;
- (void)stopLoopTimer;
@end
