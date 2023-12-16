#include <CoreGraphics/CoreGraphics.h>
#include <Foundation/Foundation.h>
#import <notify.h>
#import <UIKit/UIKit.h>
#import "TrollSpeed-Swift.h"
#import "HUDPresetPosition.h"

OBJC_EXTERN BOOL IsHUDEnabled(void);
OBJC_EXTERN void SetHUDEnabled(BOOL isEnabled);

@interface UIApplication (Private)
- (void)suspend;
- (void)terminateWithSuccess;
@end

static BOOL _shouldToggleHUDAfterLaunch = NO;
static NSString * const kToggleHUDAfterLaunchNotificationName = @"ch.xxtou.hudapp.notification.toggle-hud";
static NSString * const kToggleHUDAfterLaunchNotificationActionKey = @"action";
static NSString * const kToggleHUDAfterLaunchNotificationActionToggleOn = @"toggle-on";
static NSString * const kToggleHUDAfterLaunchNotificationActionToggleOff = @"toggle-off";


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
@property (nonatomic, strong) UIView *backgroundView;
@property (nonatomic, assign) BOOL isHUDActive;
@end

@implementation RootViewController {
    NSMutableDictionary *_userDefaults;
    MainButton *_mainButton;
    UIButton *_settingsButton;
    UIButton *_topLeftButton;
    UIButton *_topRightButton;
    UIButton *_topCenterButton;
    UIButton *_topCenterMostButton;
    UILabel *_authorLabel;
    BOOL _supportsCenterMost;
}

- (void)registerNotifications
{
    int token;
    notify_register_dispatch(NOTIFY_RELOAD_APP, &token, dispatch_get_main_queue(), ^(int token) {
        [self loadUserDefaults:YES];
    });
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(toggleHUDNotificationReceived:) name:kToggleHUDAfterLaunchNotificationName object:nil];
}

- (void)loadView
{
    CGRect bounds = UIScreen.mainScreen.bounds;

    self.view = [[UIView alloc] initWithFrame:bounds];
    self.view.backgroundColor = [UIColor colorWithRed:0.0f/255.0f green:0.0f/255.0f blue:0.0f/255.0f alpha:.580f/1.0f];  // rgba(0, 0, 0, 0.580)

    self.backgroundView = [[UIView alloc] initWithFrame:bounds];
    self.backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.backgroundView.backgroundColor = [UIColor colorWithRed:26.0f/255.0f green:188.0f/255.0f blue:156.0f/255.0f alpha:1.0f];  // rgba(26, 188, 156, 1.0)
    [self.view addSubview:self.backgroundView];

    BOOL isPad = ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad);

    _topLeftButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_topLeftButton setTintColor:[UIColor whiteColor]];
    [_topLeftButton addTarget:self action:@selector(tapTopLeftButton:) forControlEvents:UIControlEventTouchUpInside];
    [_topLeftButton setImage:[UIImage systemImageNamed:@"arrow.up.left"] forState:UIControlStateNormal];
    [_topLeftButton setAdjustsImageWhenHighlighted:NO];
    [self.backgroundView addSubview:_topLeftButton];
    if (@available(iOS 15.0, *))
    {
        UIButtonConfiguration *config = [UIButtonConfiguration plainButtonConfiguration];
        [config setCornerStyle:UIButtonConfigurationCornerStyleLarge];
        [_topLeftButton setConfiguration:config];
    }
    UILayoutGuide *safeArea = self.backgroundView.safeAreaLayoutGuide;
    [_topLeftButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    [NSLayoutConstraint activateConstraints:@[
        [_topLeftButton.topAnchor constraintEqualToAnchor:safeArea.topAnchor constant:(isPad ? 40.0f : 28.f)],
        [_topLeftButton.leadingAnchor constraintEqualToAnchor:self.backgroundView.leadingAnchor constant:20.0f],
        [_topLeftButton.widthAnchor constraintEqualToConstant:40.0f],
        [_topLeftButton.heightAnchor constraintEqualToConstant:40.0f],
    ]];

    _topRightButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_topRightButton setTintColor:[UIColor whiteColor]];
    [_topRightButton addTarget:self action:@selector(tapTopRightButton:) forControlEvents:UIControlEventTouchUpInside];
    [_topRightButton setImage:[UIImage systemImageNamed:@"arrow.up.right"] forState:UIControlStateNormal];
    [_topRightButton setAdjustsImageWhenHighlighted:NO];
    [self.backgroundView addSubview:_topRightButton];
    if (@available(iOS 15.0, *))
    {
        UIButtonConfiguration *config = [UIButtonConfiguration plainButtonConfiguration];
        [config setCornerStyle:UIButtonConfigurationCornerStyleLarge];
        [_topRightButton setConfiguration:config];
    }
    [_topRightButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    [NSLayoutConstraint activateConstraints:@[
        [_topRightButton.topAnchor constraintEqualToAnchor:safeArea.topAnchor constant:(isPad ? 40.0f : 28.f)],
        [_topRightButton.trailingAnchor constraintEqualToAnchor:self.backgroundView.trailingAnchor constant:-20.0f],
        [_topRightButton.widthAnchor constraintEqualToConstant:40.0f],
        [_topRightButton.heightAnchor constraintEqualToConstant:40.0f],
    ]];

    _topCenterButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_topCenterButton setTintColor:[UIColor whiteColor]];
    [_topCenterButton addTarget:self action:@selector(tapTopCenterButton:) forControlEvents:UIControlEventTouchUpInside];
    [_topCenterButton setImage:[UIImage systemImageNamed:@"arrow.up"] forState:UIControlStateNormal];
    [_topCenterButton setAdjustsImageWhenHighlighted:NO];
    [self.backgroundView addSubview:_topCenterButton];
    if (@available(iOS 15.0, *))
    {
        UIButtonConfiguration *config = [UIButtonConfiguration plainButtonConfiguration];
        [config setCornerStyle:UIButtonConfigurationCornerStyleLarge];
        [_topCenterButton setConfiguration:config];
    }
    [_topCenterButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    [NSLayoutConstraint activateConstraints:@[
        [_topCenterButton.topAnchor constraintEqualToAnchor:safeArea.topAnchor constant:(isPad ? 40.0f : 28.f)],
        [_topCenterButton.centerXAnchor constraintEqualToAnchor:self.backgroundView.centerXAnchor],
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
    [self.backgroundView addSubview:_mainButton];

    [_mainButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    [NSLayoutConstraint activateConstraints:@[
        [_mainButton.centerXAnchor constraintEqualToAnchor:self.backgroundView.centerXAnchor],
        [_mainButton.centerYAnchor constraintEqualToAnchor:self.backgroundView.centerYAnchor],
    ]];

    _settingsButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_settingsButton setTintColor:[UIColor whiteColor]];
    [_settingsButton addTarget:self action:@selector(tapSettingsButton:) forControlEvents:UIControlEventTouchUpInside];
    [_settingsButton setImage:[UIImage systemImageNamed:@"gear"] forState:UIControlStateNormal];
    [self.backgroundView addSubview:_settingsButton];
    if (@available(iOS 15.0, *))
    {
        UIButtonConfiguration *config = [UIButtonConfiguration tintedButtonConfiguration];
        [config setCornerStyle:UIButtonConfigurationCornerStyleLarge];
        [_settingsButton setConfiguration:config];
    }
    [_settingsButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    [NSLayoutConstraint activateConstraints:@[
        [_settingsButton.bottomAnchor constraintEqualToAnchor:safeArea.bottomAnchor constant:-20.0f],
        [_settingsButton.centerXAnchor constraintEqualToAnchor:self.backgroundView.centerXAnchor],
        [_settingsButton.widthAnchor constraintEqualToConstant:40.0f],
        [_settingsButton.heightAnchor constraintEqualToConstant:40.0f],
    ]];

    _authorLabel = [[UILabel alloc] init];
    [_authorLabel setNumberOfLines:0];
    [_authorLabel setTextAlignment:NSTextAlignmentCenter];
    [_authorLabel setTextColor:[UIColor whiteColor]];
    [_authorLabel setFont:[UIFont systemFontOfSize:14.0]];
    [_authorLabel sizeToFit];
    [self.backgroundView addSubview:_authorLabel];

    [_authorLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    [NSLayoutConstraint activateConstraints:@[
        [_authorLabel.centerXAnchor constraintEqualToAnchor:self.backgroundView.centerXAnchor],
        [_authorLabel.bottomAnchor constraintEqualToAnchor:_settingsButton.topAnchor constant:-20],
    ]];

    UITapGestureRecognizer *authorTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAuthorLabel:)];
    [_authorLabel setUserInteractionEnabled:YES];
    [_authorLabel addGestureRecognizer:authorTapGesture];

    [self reloadMainButtonState];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    _supportsCenterMost = self.view.window.safeAreaLayoutGuide.layoutFrame.origin.y >= 51;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self registerNotifications];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self toggleHUDAfterLaunch];
}

- (void)toggleHUDNotificationReceived:(NSNotification *)notification {
    NSString *toggleAction = notification.userInfo[kToggleHUDAfterLaunchNotificationActionKey];
    if (!toggleAction) {
        [self toggleHUDAfterLaunch];
    } else if ([toggleAction isEqualToString:kToggleHUDAfterLaunchNotificationActionToggleOn]) {
        [self toggleOnHUDAfterLaunch];
    } else if ([toggleAction isEqualToString:kToggleHUDAfterLaunchNotificationActionToggleOff]) {
        [self toggleOffHUDAfterLaunch];
    }
}

- (void)toggleHUDAfterLaunch {
    if (_shouldToggleHUDAfterLaunch) {
        _shouldToggleHUDAfterLaunch = NO;
        [self tapMainButton:_mainButton];
        [[UIApplication sharedApplication] suspend];
    }
}

- (void)toggleOnHUDAfterLaunch {
    if (_shouldToggleHUDAfterLaunch) {
        _shouldToggleHUDAfterLaunch = NO;
        if (!_isHUDActive) {
            [self tapMainButton:_mainButton];
        }
        [[UIApplication sharedApplication] suspend];
    }
}

- (void)toggleOffHUDAfterLaunch {
    if (_shouldToggleHUDAfterLaunch) {
        _shouldToggleHUDAfterLaunch = NO;
        if (_isHUDActive) {
            [self tapMainButton:_mainButton];
        }
        [[UIApplication sharedApplication] suspend];
    }
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
    return mode ? [mode integerValue] : HUDPresetPositionTopCenter;
}

- (void)setSelectedMode:(NSInteger)selectedMode
{
    [self loadUserDefaults:NO];
    // Remove some keys that are not persistent
    [_userDefaults removeObjectsForKeys:@[
        @"currentPositionY",
        @"currentLandscapePositionY",
    ]];
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

- (BOOL)usesRotation
{
    [self loadUserDefaults:NO];
    NSNumber *mode = [_userDefaults objectForKey:@"usesRotation"];
    return mode ? [mode boolValue] : NO;
}

- (void)setUsesRotation:(BOOL)usesRotation
{
    [self loadUserDefaults:NO];
    [_userDefaults setObject:@(usesRotation) forKey:@"usesRotation"];
    [self saveUserDefaults];
}

- (BOOL)keepInPlace
{
    [self loadUserDefaults:NO];
    NSNumber *mode = [_userDefaults objectForKey:@"keepInPlace"];
    return mode ? [mode boolValue] : NO;
}

- (void)setKeepInPlace:(BOOL)keepInPlace
{
    [self loadUserDefaults:NO];
    [_userDefaults setObject:@(keepInPlace) forKey:@"keepInPlace"];
    [self saveUserDefaults];
}

- (void)reloadMainButtonState
{
    _isHUDActive = IsHUDEnabled();
    
    static NSAttributedString *hintAttributedString = nil;
    static NSAttributedString *githubAttributedString = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSDictionary *defaultAttributes = @{NSForegroundColorAttributeName: [UIColor whiteColor], NSFontAttributeName: [UIFont systemFontOfSize:14]};
        
        NSString *hintText = NSLocalizedString(@"You can quit this app now.\nThe HUD will persist on your screen.", nil);
        hintAttributedString = [[NSAttributedString alloc] initWithString:hintText attributes:defaultAttributes];
        
        NSTextAttachment *githubIcon = [NSTextAttachment textAttachmentWithImage:[UIImage imageNamed:@"github-mark-white"]];
        [githubIcon setBounds:CGRectMake(0, 0, 14, 14)];
        
        NSAttributedString *githubIconText = [NSAttributedString attributedStringWithAttachment:githubIcon];
        NSMutableAttributedString *githubIconTextFull = [[NSMutableAttributedString alloc] initWithAttributedString:githubIconText];
        [githubIconTextFull appendAttributedString:[[NSAttributedString alloc] initWithString:@" " attributes:defaultAttributes]];
        
        NSString *githubText = NSLocalizedString(@"Made with ♥ by @Lessica and @jmpews", nil);
        NSMutableAttributedString *githubAttributedText = [[NSMutableAttributedString alloc] initWithString:githubText attributes:defaultAttributes];
        
        // replace all "@" with github icon
        NSRange atRange = [githubAttributedText.string rangeOfString:@"@"];
        while (atRange.location != NSNotFound) {
            [githubAttributedText replaceCharactersInRange:atRange withAttributedString:githubIconTextFull];
            atRange = [githubAttributedText.string rangeOfString:@"@"];
        }
        
        githubAttributedString = githubAttributedText;
    });
    
    [UIView transitionWithView:self.backgroundView duration:0.25 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        [_mainButton setTitle:(_isHUDActive ? NSLocalizedString(@"Exit HUD", nil) : NSLocalizedString(@"Open HUD", nil)) forState:UIControlStateNormal];
        [_authorLabel setAttributedText:(_isHUDActive ? hintAttributedString : githubAttributedString)];
    } completion:nil];
}

- (void)presentTopCenterMostHints
{
    if (!_isHUDActive) {
        return;
    }
    [_authorLabel setText:NSLocalizedString(@"Tap that button on the center again,\nto toggle ON/OFF “Dynamic Island” mode.", nil)];
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
    NSInteger selectedMode = [self selectedMode];
    BOOL isCentered = (selectedMode == HUDPresetPositionTopCenter || selectedMode == HUDPresetPositionTopCenterMost);
    BOOL isCenteredMost = (selectedMode == HUDPresetPositionTopCenterMost);
    [_topLeftButton setSelected:([self selectedMode] == HUDPresetPositionTopLeft)];
    [_topCenterButton setSelected:isCentered];
    [_topRightButton setSelected:([self selectedMode] == HUDPresetPositionTopRight)];
    UIImage *topCenterImage = (isCenteredMost ? [UIImage systemImageNamed:@"arrow.up.to.line"] : [UIImage systemImageNamed:@"arrow.up"]);
    [_topCenterButton setImage:topCenterImage forState:UIControlStateNormal];
}

- (void)tapAuthorLabel:(UITapGestureRecognizer *)sender
{
    if (_isHUDActive) {
        return;
    }
    NSString *repoURLString = @"https://github.com/Lessica/TrollSpeed";
    NSURL *repoURL = [NSURL URLWithString:repoURLString];
    [[UIApplication sharedApplication] openURL:repoURL options:@{} completionHandler:nil];
}

- (void)tapTopLeftButton:(UIButton *)sender
{
    os_log_debug(OS_LOG_DEFAULT, "- [RootViewController tapTopLeftButton:%{public}@]", sender);
    [self setSelectedMode:HUDPresetPositionTopLeft];
    [self reloadModeButtonState];
}

- (void)tapTopRightButton:(UIButton *)sender
{
    os_log_debug(OS_LOG_DEFAULT, "- [RootViewController tapTopRightButton:%{public}@]", sender);
    [self setSelectedMode:HUDPresetPositionTopRight];
    [self reloadModeButtonState];
}

- (void)tapTopCenterButton:(UIButton *)sender
{
    os_log_debug(OS_LOG_DEFAULT, "- [RootViewController tapTopCenterButton:%{public}@]", sender);
    NSInteger selectedMode = [self selectedMode];
    BOOL isCenteredMost = (selectedMode == HUDPresetPositionTopCenterMost);
    if (!sender.isSelected || !_supportsCenterMost) {
        [self setSelectedMode:HUDPresetPositionTopCenter];
        if (_supportsCenterMost) {
            [self presentTopCenterMostHints];
        }
    } else {
        if (isCenteredMost) {
            [self setSelectedMode:HUDPresetPositionTopCenter];
        } else {
            [self setSelectedMode:HUDPresetPositionTopCenterMost];
        }
    }
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

        [self.backgroundView setUserInteractionEnabled:NO];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
            int timedOut = dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)));
            dispatch_async(dispatch_get_main_queue(), ^{
                if (timedOut)
                    os_log_error(OS_LOG_DEFAULT, "Timed out waiting for HUD to launch");
                
                [self reloadMainButtonState];
                [self.backgroundView setUserInteractionEnabled:YES];
            });
        });
    }
    else
    {
        [self.backgroundView setUserInteractionEnabled:NO];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self reloadMainButtonState];
            [self.backgroundView setUserInteractionEnabled:YES];
        });
    }
}

- (void)tapSettingsButton:(UIButton *)sender
{
    if (![_mainButton isEnabled]) return;
    os_log_debug(OS_LOG_DEFAULT, "- [RootViewController tapSettingsButton:%{public}@]", sender);

    TSSettingsController *settingsViewController = [[TSSettingsController alloc] init];
    settingsViewController.delegate = self;
    settingsViewController.alreadyLaunched = _isHUDActive;
    
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

- (BOOL)application:(UIApplication *)application openURL:(nonnull NSURL *)url options:(nonnull NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options
{
    if ([url.scheme isEqualToString:@"trollspeed"]) {
        if ([url.host isEqualToString:@"toggle"]) {
            [self setupAndNotifyToggleHUDAfterLaunchWithAction:nil];
            return YES;
        } else if ([url.host isEqualToString:@"on"]) {
            [self setupAndNotifyToggleHUDAfterLaunchWithAction:kToggleHUDAfterLaunchNotificationActionToggleOn];
            return YES;
        } else if ([url.host isEqualToString:@"off"]) {
            [self setupAndNotifyToggleHUDAfterLaunchWithAction:kToggleHUDAfterLaunchNotificationActionToggleOff];
            return YES;
        }
    }
    return NO;
}

- (void)application:(UIApplication *)application performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem completionHandler:(void (^)(BOOL succeeded))completionHandler
{
    if ([shortcutItem.type isEqualToString:@"ch.xxtou.shortcut.toggle-hud"])
    {
        [self setupAndNotifyToggleHUDAfterLaunchWithAction:nil];
    }
}

- (void)setupAndNotifyToggleHUDAfterLaunchWithAction:(NSString *)action
{
    _shouldToggleHUDAfterLaunch = YES;
    if (action) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kToggleHUDAfterLaunchNotificationName object:nil userInfo:@{
            kToggleHUDAfterLaunchNotificationActionKey: action,
        }];
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:kToggleHUDAfterLaunchNotificationName object:nil];
    }
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