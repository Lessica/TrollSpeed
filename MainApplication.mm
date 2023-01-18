#import <UIKit/UIKit.h>

OBJC_EXTERN BOOL IsHUDEnabled(void);
OBJC_EXTERN void SetHUDEnabled(BOOL isEnabled);


#pragma mark - MainApplication

@interface MainApplication : UIApplication
@end

@implementation MainApplication
@end


#pragma mark - RootViewController

@interface RootViewController: UIViewController
@end

@implementation RootViewController {
    UIButton *_mainButton;
}

- (void)loadView
{
    CGRect bounds = UIScreen.mainScreen.bounds;
    self.view = [[UIView alloc] initWithFrame:bounds];
    self.view.backgroundColor = [UIColor systemPurpleColor];

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapView:)];
    tap.numberOfTapsRequired = 1;
    tap.numberOfTouchesRequired = 1;
    [self.view addGestureRecognizer:tap];
    [self.view setUserInteractionEnabled:YES];

    _mainButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_mainButton setTintColor:[UIColor whiteColor]];
    [_mainButton addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self reloadButtonState];
    [_mainButton.titleLabel setFont:[UIFont boldSystemFontOfSize:32]];
    [_mainButton sizeToFit];
    [self.view addSubview:_mainButton];

    [_mainButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    [NSLayoutConstraint activateConstraints:@[
        [_mainButton.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [_mainButton.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
    ]];
}

- (void)reloadButtonState
{
    [_mainButton setTitle:(IsHUDEnabled() ? @"Close HUD" : @"Open HUD") forState:UIControlStateNormal];
    [_mainButton sizeToFit];
}

- (void)tapView:(UITapGestureRecognizer *)sender
{
    os_log_debug(OS_LOG_DEFAULT, "- [HUDRootViewController tapView:%{public}@]: %{public}@", sender, NSStringFromCGPoint([sender locationInView:self.view]));
}

- (void)buttonTapped:(UIButton *)sender
{
    os_log_debug(OS_LOG_DEFAULT, "- [HUDRootViewController buttonTapped:%{public}@]", sender);
    SetHUDEnabled(!IsHUDEnabled());
    [self reloadButtonState];
}

@end


#pragma mark - MainApplicationDelegate

@interface MainApplicationDelegate : UIResponder <UIApplicationDelegate>
@property (nonatomic, strong) UIWindow *window;
@end

@implementation MainApplicationDelegate {
    RootViewController *_rootViewController;
}

- (instancetype)init {
    if (self = [super init]) {
        os_log_debug(OS_LOG_DEFAULT, "- [MainApplicationDelegate init]");
    }
    return self;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary <UIApplicationLaunchOptionsKey, id> *)launchOptions {
    os_log_debug(OS_LOG_DEFAULT, "- [MainApplicationDelegate application:%{public}@ didFinishLaunchingWithOptions:%{public}@]", application, launchOptions);
    
    _rootViewController = [[RootViewController alloc] init];

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [self.window setRootViewController:_rootViewController];
    [self.window makeKeyAndVisible];

    return YES;
}

@end