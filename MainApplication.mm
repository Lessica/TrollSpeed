#import <notify.h>
#import <UIKit/UIKit.h>
#import "XXTAssistiveTouch-Swift.h"

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

@interface MainButton : UIButton
@end

@implementation MainButton

- (void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
    if (highlighted)
    {
        [UIView animateWithDuration:0.27 delay:0.0 usingSpringWithDamping:1.0 initialSpringVelocity:1.0 options:(UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionBeginFromCurrentState) animations:^{
            self.transform = CGAffineTransformMakeScale(0.92, 0.92);
        } completion:nil];
    }
    else
    {
        [UIView animateWithDuration:0.27 delay:0.0 usingSpringWithDamping:1.0 initialSpringVelocity:1.0 options:(UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionBeginFromCurrentState) animations:^{
            self.transform = CGAffineTransformIdentity;
        } completion:nil];
    }
}

@end

@interface RootViewController : UIViewController <TSSettingsControllerDelegate>
@end

@implementation RootViewController {
    NSMutableDictionary *_userDefaults;
    MainButton *_mainButton;
    UIButton *_settingsButton;
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

    BOOL isPad = ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad);

    _topLeftButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_topLeftButton setTintColor:[UIColor whiteColor]];
    [_topLeftButton addTarget:self action:@selector(tapTopLeftButton:) forControlEvents:UIControlEventTouchUpInside];
    [_topLeftButton setImage:[UIImage systemImageNamed:@"arrow.up.left.square.fill"] forState:UIControlStateNormal];
    [_topLeftButton setAdjustsImageWhenHighlighted:NO];
    [self.view addSubview:_topLeftButton];
    if (@available(iOS 15.0, *))
    {
        UIButtonConfiguration *config = [UIButtonConfiguration plainButtonConfiguration];
        [config setCornerStyle:UIButtonConfigurationCornerStyleLarge];
        [_topLeftButton setConfiguration:config];
    }
    UILayoutGuide *safeArea = self.view.safeAreaLayoutGuide;
    [_topLeftButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    [NSLayoutConstraint activateConstraints:@[
        [_topLeftButton.topAnchor constraintEqualToAnchor:safeArea.topAnchor constant:(isPad ? 40.0f : 28.f)],
        [_topLeftButton.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20.0f],
        [_topLeftButton.widthAnchor constraintEqualToConstant:40.0f],
        [_topLeftButton.heightAnchor constraintEqualToConstant:40.0f],
    ]];

    _topRightButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_topRightButton setTintColor:[UIColor whiteColor]];
    [_topRightButton addTarget:self action:@selector(tapTopRightButton:) forControlEvents:UIControlEventTouchUpInside];
    [_topRightButton setImage:[UIImage systemImageNamed:@"arrow.up.right.square.fill"] forState:UIControlStateNormal];
    [_topRightButton setAdjustsImageWhenHighlighted:NO];
    [self.view addSubview:_topRightButton];
    if (@available(iOS 15.0, *))
    {
        UIButtonConfiguration *config = [UIButtonConfiguration plainButtonConfiguration];
        [config setCornerStyle:UIButtonConfigurationCornerStyleLarge];
        [_topRightButton setConfiguration:config];
    }
    [_topRightButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    [NSLayoutConstraint activateConstraints:@[
        [_topRightButton.topAnchor constraintEqualToAnchor:safeArea.topAnchor constant:(isPad ? 40.0f : 28.f)],
        [_topRightButton.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20.0f],
        [_topRightButton.widthAnchor constraintEqualToConstant:40.0f],
        [_topRightButton.heightAnchor constraintEqualToConstant:40.0f],
    ]];

    _topCenterButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_topCenterButton setTintColor:[UIColor whiteColor]];
    [_topCenterButton addTarget:self action:@selector(tapTopCenterButton:) forControlEvents:UIControlEventTouchUpInside];
    [_topCenterButton setImage:[UIImage systemImageNamed:@"arrow.up.square.fill"] forState:UIControlStateNormal];
    [_topCenterButton setAdjustsImageWhenHighlighted:NO];
    [self.view addSubview:_topCenterButton];
    if (@available(iOS 15.0, *))
    {
        UIButtonConfiguration *config = [UIButtonConfiguration plainButtonConfiguration];
        [config setCornerStyle:UIButtonConfigurationCornerStyleLarge];
        [_topCenterButton setConfiguration:config];
    }
    [_topCenterButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    [NSLayoutConstraint activateConstraints:@[
        [_topCenterButton.topAnchor constraintEqualToAnchor:safeArea.topAnchor constant:(isPad ? 40.0f : 28.f)],
        [_topCenterButton.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [_topCenterButton.widthAnchor constraintEqualToConstant:40.0f],
        [_topCenterButton.heightAnchor constraintEqualToConstant:40.0f],
    ]];

    [self reloadModeButtonState];

    _mainButton = [MainButton buttonWithType:UIButtonTypeSystem];
    [_mainButton setTintColor:[UIColor whiteColor]];
    [_mainButton addTarget:self action:@selector(tapMainButton:) forControlEvents:UIControlEventTouchUpInside];
    if (@available(iOS 15.0, *))
    {
        UIButtonConfiguration *config = [UIButtonConfiguration tintedButtonConfiguration];
        [config setTitleTextAttributesTransformer:^NSDictionary <NSAttributedStringKey, id> * _Nonnull(NSDictionary <NSAttributedStringKey, id> * _Nonnull textAttributes) {
            NSMutableDictionary *newAttributes = [textAttributes mutableCopy];
            [newAttributes setObject:[UIFont boldSystemFontOfSize:32.0] forKey:NSFontAttributeName];
            return newAttributes;
        }];
        [config setCornerStyle:UIButtonConfigurationCornerStyleLarge];
        [_mainButton setConfiguration:config];
    }
    else
    {
        [_mainButton.titleLabel setFont:[UIFont boldSystemFontOfSize:32.0]];
    }
    [self.view addSubview:_mainButton];

    [_mainButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    [NSLayoutConstraint activateConstraints:@[
        [_mainButton.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [_mainButton.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
    ]];

    _settingsButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_settingsButton setTintColor:[UIColor whiteColor]];
    [_settingsButton addTarget:self action:@selector(tapSettingsButton:) forControlEvents:UIControlEventTouchUpInside];
    [_settingsButton setImage:[UIImage systemImageNamed:@"gear"] forState:UIControlStateNormal];
    [self.view addSubview:_settingsButton];
    if (@available(iOS 15.0, *))
    {
        UIButtonConfiguration *config = [UIButtonConfiguration tintedButtonConfiguration];
        [config setCornerStyle:UIButtonConfigurationCornerStyleLarge];
        [_settingsButton setConfiguration:config];
    }
    [_settingsButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    [NSLayoutConstraint activateConstraints:@[
        [_settingsButton.bottomAnchor constraintEqualToAnchor:safeArea.bottomAnchor constant:-20.0f],
        [_settingsButton.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [_settingsButton.widthAnchor constraintEqualToConstant:40.0f],
        [_settingsButton.heightAnchor constraintEqualToConstant:40.0f],
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
        [_authorLabel.bottomAnchor constraintEqualToAnchor:_settingsButton.topAnchor constant:-20],
    ]];

    [self reloadMainButtonState];
}

#define USER_DEFAULTS_PATH @"/var/mobile/Library/Preferences/ch.xxtou.hudapp.plist"

- (void)loadUserDefaults:(BOOL)forceReload
{
    if (forceReload || !_userDefaults)
        _userDefaults = [[NSDictionary dictionaryWithContentsOfFile:USER_DEFAULTS_PATH] mutableCopy] ?: [NSMutableDictionary dictionary];
}

- (void)saveUserDefaults
{
    [_userDefaults writeToFile:USER_DEFAULTS_PATH atomically:YES];
    notify_post(NOTIFY_RELOAD_HUD);
}

- (NSInteger)selectedMode
{
    [self loadUserDefaults:NO];
    NSNumber *mode = [_userDefaults objectForKey:@"selectedMode"];
    return mode ? [mode integerValue] : 1;
}

- (void)setSelectedMode:(NSInteger)selectedMode
{
    [self loadUserDefaults:NO];
    [_userDefaults setObject:@(selectedMode) forKey:@"selectedMode"];
    [self saveUserDefaults];
}

- (BOOL)passthroughMode
{
    [self loadUserDefaults:NO];
    NSNumber *mode = [_userDefaults objectForKey:@"passthroughMode"];
    return mode ? [mode boolValue] : NO;
}

- (void)setPassthroughMode:(BOOL)passthroughMode
{
    [self loadUserDefaults:NO];
    [_userDefaults setObject:@(passthroughMode) forKey:@"passthroughMode"];
    [self saveUserDefaults];
}

- (BOOL)singleLineMode
{
    [self loadUserDefaults:NO];
    NSNumber *mode = [_userDefaults objectForKey:@"singleLineMode"];
    return mode ? [mode boolValue] : NO;
}

- (void)setSingleLineMode:(BOOL)singleLineMode
{
    [self loadUserDefaults:NO];
    [_userDefaults setObject:@(singleLineMode) forKey:@"singleLineMode"];
    [self saveUserDefaults];
}

- (BOOL)usesBitrate
{
    [self loadUserDefaults:NO];
    NSNumber *mode = [_userDefaults objectForKey:@"usesBitrate"];
    return mode ? [mode boolValue] : NO;
}

- (void)setUsesBitrate:(BOOL)usesBitrate
{
    [self loadUserDefaults:NO];
    [_userDefaults setObject:@(usesBitrate) forKey:@"usesBitrate"];
    [self saveUserDefaults];
}

- (BOOL)usesArrowPrefixes
{
    [self loadUserDefaults:NO];
    NSNumber *mode = [_userDefaults objectForKey:@"usesArrowPrefixes"];
    return mode ? [mode boolValue] : NO;
}

- (void)setUsesArrowPrefixes:(BOOL)usesArrowPrefixes
{
    [self loadUserDefaults:NO];
    [_userDefaults setObject:@(usesArrowPrefixes) forKey:@"usesArrowPrefixes"];
    [self saveUserDefaults];
}

- (BOOL)usesLargeFont
{
    [self loadUserDefaults:NO];
    NSNumber *mode = [_userDefaults objectForKey:@"usesLargeFont"];
    return mode ? [mode boolValue] : NO;
}

- (void)setUsesLargeFont:(BOOL)usesLargeFont
{
    [self loadUserDefaults:NO];
    [_userDefaults setObject:@(usesLargeFont) forKey:@"usesLargeFont"];
    [self saveUserDefaults];
}

- (void)reloadMainButtonState
{
    [UIView transitionWithView:self.view duration:0.25 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        [_mainButton setTitle:(IsHUDEnabled() ? @"Exit HUD" : @"Open HUD") forState:UIControlStateNormal];
        [_authorLabel setText:(IsHUDEnabled() ? @"You can quit this app now.\nThe HUD will persist on your screen." : @"Made with ♥ by @i_82 and @jmpews")];
    } completion:nil];
}

- (BOOL)settingHighlightedWithKey:(NSString * _Nonnull)key
{
    [self loadUserDefaults:NO];
    NSNumber *mode = [_userDefaults objectForKey:key];
    return mode ? [mode boolValue] : NO;
}

- (void)settingDidSelectWithKey:(NSString * _Nonnull)key
{
    BOOL highlighted = [self settingHighlightedWithKey:key];
    [_userDefaults setObject:@(!highlighted) forKey:key];
    [self saveUserDefaults];
}

- (void)reloadModeButtonState
{
    [_topLeftButton setSelected:([self selectedMode] == 0)];
    [_topCenterButton setSelected:([self selectedMode] == 1)];
    [_topRightButton setSelected:([self selectedMode] == 2)];
}

- (void)tapView:(UITapGestureRecognizer *)sender
{
    os_log_debug(OS_LOG_DEFAULT, "- [RootViewController tapView:%{public}@]: %{public}@", sender, NSStringFromCGPoint([sender locationInView:self.view]));
}

- (void)tapTopLeftButton:(UIButton *)sender
{
    os_log_debug(OS_LOG_DEFAULT, "- [RootViewController tapTopLeftButton:%{public}@]", sender);
    [self setSelectedMode:0];
    [self reloadModeButtonState];
}

- (void)tapTopRightButton:(UIButton *)sender
{
    os_log_debug(OS_LOG_DEFAULT, "- [RootViewController tapTopRightButton:%{public}@]", sender);
    [self setSelectedMode:2];
    [self reloadModeButtonState];
}

- (void)tapTopCenterButton:(UIButton *)sender
{
    os_log_debug(OS_LOG_DEFAULT, "- [RootViewController tapTopCenterButton:%{public}@]", sender);
    [self setSelectedMode:1];
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

        [self.view setUserInteractionEnabled:NO];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
            int timedOut = dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)));
            dispatch_async(dispatch_get_main_queue(), ^{
                if (timedOut)
                    os_log_error(OS_LOG_DEFAULT, "Timed out waiting for HUD to launch");
                
                [self reloadMainButtonState];
                [self.view setUserInteractionEnabled:YES];
            });
        });
    }
    else
    {
        [self.view setUserInteractionEnabled:NO];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self reloadMainButtonState];
            [self.view setUserInteractionEnabled:YES];
        });
    }
}

- (void)tapSettingsButton:(UIButton *)sender
{
    if (![_mainButton isEnabled]) return;
    os_log_debug(OS_LOG_DEFAULT, "- [RootViewController tapSettingsButton:%{public}@]", sender);

    TSSettingsController *settingsViewController = [[TSSettingsController alloc] init];
    settingsViewController.delegate = self;
    settingsViewController.alreadyLaunched = IsHUDEnabled();
    
    SPLarkTransitioningDelegate *transitioningDelegate = [[SPLarkTransitioningDelegate alloc] init];
    settingsViewController.transitioningDelegate = transitioningDelegate;
    settingsViewController.modalPresentationStyle = UIModalPresentationCustom;
    settingsViewController.modalPresentationCapturesStatusBarAppearance = YES;
    [self presentViewController:settingsViewController animated:YES completion:nil];
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