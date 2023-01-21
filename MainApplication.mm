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
        [[NSUserDefaults standardUserDefaults] setObject:@YES forKey:@"LogTouch" inDomain:@"com.apple.UIKit"];
        [[NSUserDefaults standardUserDefaults] setObject:@YES forKey:@"LogGesture" inDomain:@"com.apple.UIKit"];
        [[NSUserDefaults standardUserDefaults] setObject:@YES forKey:@"LogEventDispatch" inDomain:@"com.apple.UIKit"];
        [[NSUserDefaults standardUserDefaults] setObject:@YES forKey:@"LogGestureEnvironment" inDomain:@"com.apple.UIKit"];
        [[NSUserDefaults standardUserDefaults] setObject:@YES forKey:@"LogGestureExclusion" inDomain:@"com.apple.UIKit"];
        [[NSUserDefaults standardUserDefaults] setObject:@YES forKey:@"LogSystemGestureUpdate" inDomain:@"com.apple.UIKit"];
        [[NSUserDefaults standardUserDefaults] setObject:@YES forKey:@"LogGesturePerformance" inDomain:@"com.apple.UIKit"];
        [[NSUserDefaults standardUserDefaults] setObject:@YES forKey:@"LogHIDTransformer" inDomain:@"com.apple.UIKit"];
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
    UIButton *_topLeftButton;
    UIButton *_topRightButton;
    UIButton *_topCenterButton;
    UILabel *_authorLabel;
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

    _topLeftButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_topLeftButton setTintColor:[UIColor whiteColor]];
    [_topLeftButton addTarget:self action:@selector(tapTopLeftButton:) forControlEvents:UIControlEventTouchUpInside];
    [_topLeftButton setImage:[UIImage systemImageNamed:@"1.circle"] forState:UIControlStateNormal];
    [_topLeftButton setImage:[UIImage systemImageNamed:@"1.circle.fill"] forState:UIControlStateSelected];
    [self.view addSubview:_topLeftButton];

    UILayoutGuide *safeArea = self.view.safeAreaLayoutGuide;
    [_topLeftButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    [NSLayoutConstraint activateConstraints:@[
        [_topLeftButton.topAnchor constraintEqualToAnchor:safeArea.topAnchor constant:20.0f],
        [_topLeftButton.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20.0f],
        [_topLeftButton.widthAnchor constraintEqualToConstant:40.0f],
        [_topLeftButton.heightAnchor constraintEqualToConstant:40.0f],
    ]];

    _topRightButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_topRightButton setTintColor:[UIColor whiteColor]];
    [_topRightButton addTarget:self action:@selector(tapTopRightButton:) forControlEvents:UIControlEventTouchUpInside];
    [_topRightButton setImage:[UIImage systemImageNamed:@"3.circle"] forState:UIControlStateNormal];
    [_topRightButton setImage:[UIImage systemImageNamed:@"3.circle.fill"] forState:UIControlStateSelected];
    [self.view addSubview:_topRightButton];

    [_topRightButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    [NSLayoutConstraint activateConstraints:@[
        [_topRightButton.topAnchor constraintEqualToAnchor:safeArea.topAnchor constant:20.0f],
        [_topRightButton.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20.0f],
        [_topRightButton.widthAnchor constraintEqualToConstant:40.0f],
        [_topRightButton.heightAnchor constraintEqualToConstant:40.0f],
    ]];

    _topCenterButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_topCenterButton setTintColor:[UIColor whiteColor]];
    [_topCenterButton addTarget:self action:@selector(tapTopCenterButton:) forControlEvents:UIControlEventTouchUpInside];
    [_topCenterButton setImage:[UIImage systemImageNamed:@"2.circle"] forState:UIControlStateNormal];
    [_topCenterButton setImage:[UIImage systemImageNamed:@"2.circle.fill"] forState:UIControlStateSelected];
    [self.view addSubview:_topCenterButton];

    [_topCenterButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    [NSLayoutConstraint activateConstraints:@[
        [_topCenterButton.topAnchor constraintEqualToAnchor:safeArea.topAnchor constant:20.0f],
        [_topCenterButton.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [_topCenterButton.widthAnchor constraintEqualToConstant:40.0f],
        [_topCenterButton.heightAnchor constraintEqualToConstant:40.0f],
    ]];

    [self reloadModeButtonState];

    _mainButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_mainButton setTintColor:[UIColor whiteColor]];
    [_mainButton addTarget:self action:@selector(tapMainButton:) forControlEvents:UIControlEventTouchUpInside];
    [_mainButton.titleLabel setFont:[UIFont boldSystemFontOfSize:32.0]];
    [self.view addSubview:_mainButton];

    [_mainButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    [NSLayoutConstraint activateConstraints:@[
        [_mainButton.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [_mainButton.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
        [_mainButton.widthAnchor constraintEqualToAnchor:self.view.widthAnchor],
    ]];

    _authorLabel = [[UILabel alloc] init];
    [_authorLabel setNumberOfLines:0];
    [_authorLabel setTextAlignment:NSTextAlignmentCenter];
    [_authorLabel setTextColor:[UIColor whiteColor]];
    [_authorLabel setFont:[UIFont systemFontOfSize:14.0]];
    [_authorLabel sizeToFit];
    [self.view addSubview:_authorLabel];

    [_authorLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    [NSLayoutConstraint activateConstraints:@[
        [_authorLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [_authorLabel.bottomAnchor constraintEqualToAnchor:safeArea.bottomAnchor constant:-20],
    ]];

    [self reloadMainButtonState];
}

#define USER_DEFAULTS_PATH @"/var/mobile/Library/Preferences/ch.xxtou.hudapp.plist"

+ (void)load {
    [self registerPreferences];
}

+ (void)registerPreferences {
    NSDictionary *defaults = @{ @"mode": @(1) };
    if (![[NSFileManager defaultManager] fileExistsAtPath:USER_DEFAULTS_PATH])
        [defaults writeToFile:USER_DEFAULTS_PATH atomically:YES];
}

+ (NSInteger)selectedMode {
    return [[[NSDictionary dictionaryWithContentsOfFile:USER_DEFAULTS_PATH] objectForKey:@"selectedMode"] integerValue];
}

+ (void)setSelectedMode:(NSInteger)selectedMode {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithContentsOfFile:USER_DEFAULTS_PATH];
    if (!dict) dict = [NSMutableDictionary dictionary];
    [dict setObject:@(selectedMode) forKey:@"selectedMode"];
    [dict writeToFile:USER_DEFAULTS_PATH atomically:YES];

    notify_post(NOTIFY_RELOAD_HUD);
}

- (void)reloadMainButtonState
{
    [_mainButton setTitle:(IsHUDEnabled() ? @"Exit HUD" : @"Open HUD") forState:UIControlStateNormal];
    [_mainButton sizeToFit];
    [UIView transitionWithView:_authorLabel duration:0.25 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        [_authorLabel setText:(IsHUDEnabled() ? @"You can quit this app now.\nThe HUD will persist on your screen." : @"Made with ♥ by @i_82 and @jmpews")];
    } completion:nil];
}

- (void)reloadModeButtonState
{
    [_topLeftButton setSelected:([RootViewController selectedMode] == 0)];
    [_topCenterButton setSelected:([RootViewController selectedMode] == 1)];
    [_topRightButton setSelected:([RootViewController selectedMode] == 2)];
}

- (void)tapView:(UITapGestureRecognizer *)sender
{
    os_log_debug(OS_LOG_DEFAULT, "- [RootViewController tapView:%{public}@]: %{public}@", sender, NSStringFromCGPoint([sender locationInView:self.view]));
}

- (void)tapTopLeftButton:(UIButton *)sender
{
    os_log_debug(OS_LOG_DEFAULT, "- [RootViewController tapTopLeftButton:%{public}@]", sender);
    [RootViewController setSelectedMode:0];
    [self reloadModeButtonState];
}

- (void)tapTopRightButton:(UIButton *)sender
{
    os_log_debug(OS_LOG_DEFAULT, "- [RootViewController tapTopRightButton:%{public}@]", sender);
    [RootViewController setSelectedMode:2];
    [self reloadModeButtonState];
}

- (void)tapTopCenterButton:(UIButton *)sender
{
    os_log_debug(OS_LOG_DEFAULT, "- [RootViewController tapTopCenterButton:%{public}@]", sender);
    [RootViewController setSelectedMode:1];
    [self reloadModeButtonState];
}

- (void)tapMainButton:(UIButton *)sender
{
    os_log_debug(OS_LOG_DEFAULT, "- [RootViewController tapMainButton:%{public}@]", sender);

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
                
                [self reloadMainButtonState];
                [sender setEnabled:YES];
            });
        });
    }
    else {
        [sender setEnabled:NO];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self reloadMainButtonState];
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