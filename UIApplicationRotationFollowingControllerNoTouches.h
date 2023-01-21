#import "UIApplicationRotationFollowingController.h"

@interface UIApplicationRotationFollowingControllerNoTouches : UIApplicationRotationFollowingController
- (void)loadView;
- (void)_prepareForRotationToOrientation:(UIInterfaceOrientation)arg1 duration:(NSTimeInterval)arg2;
- (void)_rotateToOrientation:(UIInterfaceOrientation)arg1 duration:(NSTimeInterval)arg2;
- (void)_finishRotationFromInterfaceOrientation:(UIInterfaceOrientation)arg1;
@end
