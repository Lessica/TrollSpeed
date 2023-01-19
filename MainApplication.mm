#import <notify.h>
#import <UIKit/UIKit.h>

OBJC_EXTERN BOOL IsHUDEnabled(void);
OBJC_EXTERN void SetHUDEnabled(BOOL isEnabled);


#pragma mark - MainApplication

@interface MainApplication : UIApplication
@end

@implementation MainApplication

- (instancetype)init
{
    self = [super init];
    if (self)
    {
#if DEBUG
        /* Force HIDTransformer to print logs */
        [[NSUserDefaults standardUserDefaults] setObject:@"YES" forKey:@"LogTouch" inDomain:@"com.apple.UIKit"];
        [[NSUserDefaults standardUserDefaults] setObject:@"YES" forKey:@"LogGesture" inDomain:@"com.apple.UIKit"];
        [[NSUserDefaults standardUserDefaults] setObject:@"YES" forKey:@"LogEventDispatch" inDomain:@"com.apple.UIKit"];
        [[NSUserDefaults standardUserDefaults] setObject:@"YES" forKey:@"LogGestureEnvironment" inDomain:@"com.apple.UIKit"];
        [[NSUserDefaults standardUserDefaults] setObject:@"YES" forKey:@"LogGestureExclusion" inDomain:@"com.apple.UIKit"];
        [[NSUserDefaults standardUserDefaults] setObject:@"YES" forKey:@"LogSystemGestureUpdate" inDomain:@"com.apple.UIKit"];
        [[NSUserDefaults standardUserDefaults] setObject:@"YES" forKey:@"LogGesturePerformance" inDomain:@"com.apple.UIKit"];
        [[NSUserDefaults standardUserDefaults] setObject:@"YES" forKey:@"LogHIDTransformer" inDomain:@"com.apple.UIKit"];
        [[NSUserDefaults standardUserDefaults] synchronize];
#endif
    }
    return self;
}

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

    // rgba(26, 188, 156, 1.0)
    self.view.backgroundColor = [UIColor colorWithRed:26.0f/255.0f green:188.0f/255.0f blue:156.0f/255.0f alpha:1.0f];

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
    [_mainButton setTitle:(IsHUDEnabled() ? @"Exit HUD" : @"Open HUD") forState:UIControlStateNormal];
    [_mainButton sizeToFit];
}

- (void)tapView:(UITapGestureRecognizer *)sender
{
    os_log_debug(OS_LOG_DEFAULT, "- [HUDRootViewController tapView:%{public}@]: %{public}@", sender, NSStringFromCGPoint([sender locationInView:self.view]));
}

- (void)buttonTapped:(UIButton *)sender
{
    os_log_debug(OS_LOG_DEFAULT, "- [HUDRootViewController buttonTapped:%{public}@]", sender);

    BOOL isNowEnabled = IsHUDEnabled();
    SetHUDEnabled(!isNowEnabled);
    isNowEnabled = !isNowEnabled;

    if (isNowEnabled)
    {
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

        int token;
        notify_register_dispatch(NOTIFY_LAUNCHED_HUD, &token, dispatch_get_main_queue(), ^(int token) {
            notify_cancel(token);
            dispatch_semaphore_signal(semaphore);
        });

        [sender setEnabled:NO];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
            int timedOut = dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)));
            dispatch_async(dispatch_get_main_queue(), ^{
                if (timedOut)
                    os_log_error(OS_LOG_DEFAULT, "Timed out waiting for HUD to launch");
                
                [self reloadButtonState];
                [sender setEnabled:YES];
            });
        });
    }
    else {
        [sender setEnabled:NO];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self reloadButtonState];
            [sender setEnabled:YES];
        });
    }
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