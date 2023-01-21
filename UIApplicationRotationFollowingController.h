#import <UIKit/UIViewController.h>

@interface UIApplicationRotationFollowingController : UIViewController {
	bool _sizesWindowToScene;
}

@property (assign,nonatomic) bool sizesWindowToScene;

- (unsigned long long)supportedInterfaceOrientations;
- (bool)shouldAutorotate;
- (id)__autorotationSanityCheckObjectFromSource:(id)arg1 selector:(SEL)arg2;
- (id)initWithNibName:(id)arg1 bundle:(id)arg2;
- (long long)_preferredInterfaceOrientationGivenCurrentOrientation:(long long)arg1;
- (void)window:(id)arg1 setupWithInterfaceOrientation:(long long)arg2;
- (bool)sizesWindowToScene;
- (bool)shouldAutorotateToInterfaceOrientation:(long long)arg1;
- (void)setSizesWindowToScene:(bool)arg1;

@end
