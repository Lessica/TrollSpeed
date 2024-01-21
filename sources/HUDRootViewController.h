#import "UIApplicationRotationFollowingControllerNoTouches.h"

#if !NO_TROLL
@interface HUDRootViewController: UIApplicationRotationFollowingControllerNoTouches
+ (BOOL)passthroughMode;
- (void)resetLoopTimer;
- (void)stopLoopTimer;
@end
#else
@interface HUDRootViewController: UIViewController
@end
#endif
