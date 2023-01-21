#import <UIKit/UIWindow.h>

@interface UIApplicationRotationFollowingWindow : UIWindow

+ (BOOL)_isSystemWindow;
- (id)init;
- (void)dealloc;
- (id)__autorotationSanityCheckObjectFromSource:(id)arg1 selector:(SEL)arg2;
- (void)applicationWindowRotated:(id)arg1 ;
- (void)_commonApplicationRotationFollowingWindowInit;
- (id)_initWithFrame:(CGRect)arg1 attached:(BOOL)arg2;
- (BOOL)_shouldControlAutorotation;
- (BOOL)_shouldAutorotateToInterfaceOrientation:(long long)arg1;
- (BOOL)isInterfaceAutorotationDisabled;
- (void)_handleStatusBarOrientationChange:(id)arg1;

@end
