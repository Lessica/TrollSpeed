#import "UIApplicationRotationFollowingWindow.h"

@interface UIAutoRotatingWindow : UIApplicationRotationFollowingWindow {
    UIInterfaceOrientation _interfaceOrientation;
    BOOL _unknownOrientation;
}

+ (instancetype)sharedPopoverHostingWindow;
- (void)commonInit;
- (UIView *)hitTest:(CGPoint)arg1 withEvent:(UIEvent *)arg2;
- (void)_didRemoveSubview:(UIView *)arg1;
- (instancetype)_initWithFrame:(CGRect)arg1 attached:(BOOL)arg2;
- (void)updateForOrientation:(UIInterfaceOrientation)arg1;
- (instancetype)_initWithFrame:(CGRect)arg1 debugName:(NSString *)arg2 windowScene:(UIWindowScene *)arg3;

@end
