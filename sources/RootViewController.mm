//
//  RootViewController.mm
//  TrollSpeed
//
//  Created by Lessica on 2024/1/24.
//

#import <notify.h>

#import "HUDHelper.h"
#import "MainButton.h"
#import "MainApplication.h"
#import "HUDPresetPosition.h"
#import "RootViewController.h"
#import "UIApplication+Private.h"
#import "HUDRootViewController.h"

#define HUD_TRANSITION_DURATION 0.25

static BOOL _gShouldToggleHUDAfterLaunch = NO;
static const CGFloat _gTopButtonConstraintsConstantCompact = 46.f;
static const CGFloat _gTopButtonConstraintsConstantRegular = 28.f;
static const CGFloat _gTopButtonConstraintsConstantRegularPad = 46.f;
static const CGFloat _gAuthorLabelBottomConstraintConstantCompact = -20.f;
static const CGFloat _gAuthorLabelBottomConstraintConstantRegular = -80.f;

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
    NSLayoutConstraint *_topLeftConstraint;
    NSLayoutConstraint *_topRightConstraint;
    NSLayoutConstraint *_topCenterConstraint;
    NSLayoutConstraint *_authorLabelBottomConstraint;
    BOOL _isRemoteHUDActive;
    HUDRootViewController *_localHUDRootViewController;  // Only for debugging
    UIImpactFeedbackGenerator *_impactFeedbackGenerator;
}

+ (void)setShouldToggleHUDAfterLaunch:(BOOL)flag
{
    _gShouldToggleHUDAfterLaunch = flag;
}

+ (BOOL)shouldToggleHUDAfterLaunch
{
    return _gShouldToggleHUDAfterLaunch;
}

- (BOOL)isHUDEnabled
{
#if !NO_TROLL
    return IsHUDEnabled();
#else
    return _localHUDRootViewController != nil;
#endif
}

- (void)setHUDEnabled:(BOOL)enabled
{
#if !NO_TROLL
    SetHUDEnabled(enabled);
#else
    if (enabled && _localHUDRootViewController == nil) {
        _localHUDRootViewController = [[HUDRootViewController alloc] init];
        [self presentViewController:_localHUDRootViewController animated:YES completion:nil];
    } else {
        [_localHUDRootViewController dismissViewControllerAnimated:YES completion:nil];
        _localHUDRootViewController = nil;
    }
#endif
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
    self.view.backgroundColor = [UIColor colorWithRed:0.0f / 255.0f green:0.0f / 255.0f blue:0.0f / 255.0f alpha:.580f / 1.0f];  // rgba(0, 0, 0, 0.580)

    self.backgroundView = [[UIView alloc] initWithFrame:bounds];
    self.backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.backgroundView.backgroundColor = [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
        if ([traitCollection userInterfaceStyle] == UIUserInterfaceStyleDark) {
            return [UIColor colorWithRed:28/255.0 green:74/255.0 blue:82/255.0 alpha:1.0];  // rgba(28, 74, 82, 1.0)
        } else {
            return [UIColor colorWithRed:26/255.0 green:188/255.0 blue:156/255.0 alpha:1.0];  // rgba(26, 188, 156, 1.0)
        }
    }];
    [self.view addSubview:self.backgroundView];

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
    _topLeftConstraint = [_topLeftButton.topAnchor constraintEqualToAnchor:safeArea.topAnchor constant:_gTopButtonConstraintsConstantRegular];
    [NSLayoutConstraint activateConstraints:@[
        _topLeftConstraint,
        [_topLeftButton.leadingAnchor constraintEqualToAnchor:safeArea.leadingAnchor constant:20.0f],
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
    _topRightConstraint = [_topRightButton.topAnchor constraintEqualToAnchor:safeArea.topAnchor constant:_gTopButtonConstraintsConstantRegular];
    [NSLayoutConstraint activateConstraints:@[
        _topRightConstraint,
        [_topRightButton.trailingAnchor constraintEqualToAnchor:safeArea.trailingAnchor constant:-20.0f],
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
    _topCenterConstraint = [_topCenterButton.topAnchor constraintEqualToAnchor:safeArea.topAnchor constant:_gTopButtonConstraintsConstantRegular];
    [NSLayoutConstraint activateConstraints:@[
        _topCenterConstraint,
        [_topCenterButton.centerXAnchor constraintEqualToAnchor:safeArea.centerXAnchor],
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
        [_mainButton.centerXAnchor constraintEqualToAnchor:safeArea.centerXAnchor],
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
        [_settingsButton.centerXAnchor constraintEqualToAnchor:safeArea.centerXAnchor],
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

    _authorLabelBottomConstraint = [_authorLabel.bottomAnchor constraintEqualToAnchor:safeArea.bottomAnchor constant:_gAuthorLabelBottomConstraintConstantRegular];
    [_authorLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    [NSLayoutConstraint activateConstraints:@[
        _authorLabelBottomConstraint,
        [_authorLabel.centerXAnchor constraintEqualToAnchor:safeArea.centerXAnchor],
    ]];

    UITapGestureRecognizer *authorTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAuthorLabel:)];
    [_authorLabel setUserInteractionEnabled:YES];
    [_authorLabel addGestureRecognizer:authorTapGesture];

    [self verticalSizeClassUpdated];
    [self reloadMainButtonState];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    _supportsCenterMost = CGRectGetMinY(self.view.window.safeAreaLayoutGuide.layoutFrame) >= 51;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    _impactFeedbackGenerator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];

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
    if ([RootViewController shouldToggleHUDAfterLaunch]) {
        [RootViewController setShouldToggleHUDAfterLaunch:NO];
        [self tapMainButton:_mainButton];
        [[UIApplication sharedApplication] suspend];
    }
}

- (void)toggleOnHUDAfterLaunch {
    if ([RootViewController shouldToggleHUDAfterLaunch]) {
        [RootViewController setShouldToggleHUDAfterLaunch:NO];
        if (!_isRemoteHUDActive) {
            [self tapMainButton:_mainButton];
        }
        [[UIApplication sharedApplication] suspend];
    }
}

- (void)toggleOffHUDAfterLaunch {
    if ([RootViewController shouldToggleHUDAfterLaunch]) {
        [RootViewController setShouldToggleHUDAfterLaunch:NO];
        if (_isRemoteHUDActive) {
            [self tapMainButton:_mainButton];
        }
        [[UIApplication sharedApplication] suspend];
    }
}

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    if (motion == UIEventSubtypeMotionShake) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Developer Area", nil) message:NSLocalizedString(@"Choose an action below.", nil) preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Dismiss", nil) style:UIAlertActionStyleCancel handler:nil]];
        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Reset Settings", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self resetUserDefaults];
        }]];
#if DEBUG && !NO_TROLL
        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Memory Pressure", nil) style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            SimulateMemoryPressure();
        }]];
#endif
        [self presentViewController:alertController animated:YES completion:nil];
    }
}

- (void)resetUserDefaults
{
#if !NO_TROLL
    // Reset user defaults
    NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
    if (bundleIdentifier) {
        [GetStandardUserDefaults() removePersistentDomainForName:bundleIdentifier];
        [GetStandardUserDefaults() synchronize];
    }
#endif

    // Reset custom user defaults
    BOOL removed = [[NSFileManager defaultManager] removeItemAtPath:(ROOT_PATH_NS_VAR(USER_DEFAULTS_PATH)) error:nil];
    if (removed)
    {
        // Terminate HUD
        [self setHUDEnabled:NO];

        // Terminate App
        [[UIApplication sharedApplication] terminateWithSuccess];
    }
}

- (void)loadUserDefaults:(BOOL)forceReload
{
    if (forceReload || !_userDefaults) {
        _userDefaults = [[NSDictionary dictionaryWithContentsOfFile:(ROOT_PATH_NS_VAR(USER_DEFAULTS_PATH))] mutableCopy] ?: [NSMutableDictionary dictionary];
    }
}

- (void)saveUserDefaults
{
    [_userDefaults writeToFile:(ROOT_PATH_NS_VAR(USER_DEFAULTS_PATH)) atomically:YES];
    notify_post(NOTIFY_RELOAD_HUD);
}

- (BOOL)isLandscapeOrientation
{
    UIInterfaceOrientation orientation;
    orientation = self.view.window.windowScene.interfaceOrientation;
    BOOL isLandscape;
    if (orientation == UIInterfaceOrientationUnknown) {
        isLandscape = CGRectGetWidth(self.view.bounds) > CGRectGetHeight(self.view.bounds);
    } else {
        isLandscape = UIInterfaceOrientationIsLandscape(orientation);
    }
    return isLandscape;
}

- (HUDUserDefaultsKey)selectedModeKeyForCurrentOrientation
{
    return [self isLandscapeOrientation] ? HUDUserDefaultsKeySelectedModeLandscape : HUDUserDefaultsKeySelectedMode;
}

- (HUDPresetPosition)selectedModeForCurrentOrientation
{
    [self loadUserDefaults:NO];
    NSNumber *mode = [_userDefaults objectForKey:[self selectedModeKeyForCurrentOrientation]];
    return mode != nil ? (HUDPresetPosition)[mode integerValue] : HUDPresetPositionTopCenter;
}

- (void)setSelectedModeForCurrentOrientation:(HUDPresetPosition)selectedMode
{
    [self loadUserDefaults:NO];
    // Remove some keys that are not persistent
    if ([self isLandscapeOrientation]) {
        [_userDefaults removeObjectForKey:HUDUserDefaultsKeyCurrentLandscapePositionY];
    } else {
        [_userDefaults removeObjectForKey:HUDUserDefaultsKeyCurrentPositionY];
    }
    [_userDefaults setObject:@(selectedMode) forKey:[self selectedModeKeyForCurrentOrientation]];
    [self saveUserDefaults];
}

- (BOOL)passthroughMode
{
    [self loadUserDefaults:NO];
    NSNumber *mode = [_userDefaults objectForKey:HUDUserDefaultsKeyPassthroughMode];
    return mode != nil ? [mode boolValue] : NO;
}

- (void)setPassthroughMode:(BOOL)passthroughMode
{
    [self loadUserDefaults:NO];
    [_userDefaults setObject:@(passthroughMode) forKey:HUDUserDefaultsKeyPassthroughMode];
    [self saveUserDefaults];
}

- (BOOL)singleLineMode
{
    [self loadUserDefaults:NO];
    NSNumber *mode = [_userDefaults objectForKey:HUDUserDefaultsKeySingleLineMode];
    return mode != nil ? [mode boolValue] : NO;
}

- (void)setSingleLineMode:(BOOL)singleLineMode
{
    [self loadUserDefaults:NO];
    [_userDefaults setObject:@(singleLineMode) forKey:HUDUserDefaultsKeySingleLineMode];
    [self saveUserDefaults];
}

- (BOOL)usesBitrate
{
    [self loadUserDefaults:NO];
    NSNumber *mode = [_userDefaults objectForKey:HUDUserDefaultsKeyUsesBitrate];
    return mode != nil ? [mode boolValue] : NO;
}

- (void)setUsesBitrate:(BOOL)usesBitrate
{
    [self loadUserDefaults:NO];
    [_userDefaults setObject:@(usesBitrate) forKey:HUDUserDefaultsKeyUsesBitrate];
    [self saveUserDefaults];
}

- (BOOL)usesArrowPrefixes
{
    [self loadUserDefaults:NO];
    NSNumber *mode = [_userDefaults objectForKey:HUDUserDefaultsKeyUsesArrowPrefixes];
    return mode != nil ? [mode boolValue] : NO;
}

- (void)setUsesArrowPrefixes:(BOOL)usesArrowPrefixes
{
    [self loadUserDefaults:NO];
    [_userDefaults setObject:@(usesArrowPrefixes) forKey:HUDUserDefaultsKeyUsesArrowPrefixes];
    [self saveUserDefaults];
}

- (BOOL)usesLargeFont
{
    [self loadUserDefaults:NO];
    NSNumber *mode = [_userDefaults objectForKey:HUDUserDefaultsKeyUsesLargeFont];
    return mode != nil ? [mode boolValue] : NO;
}

- (void)setUsesLargeFont:(BOOL)usesLargeFont
{
    [self loadUserDefaults:NO];
    [_userDefaults setObject:@(usesLargeFont) forKey:HUDUserDefaultsKeyUsesLargeFont];
    [self saveUserDefaults];
}

- (BOOL)usesRotation
{
    [self loadUserDefaults:NO];
    NSNumber *mode = [_userDefaults objectForKey:HUDUserDefaultsKeyUsesRotation];
    return mode != nil ? [mode boolValue] : NO;
}

- (void)setUsesRotation:(BOOL)usesRotation
{
    [self loadUserDefaults:NO];
    [_userDefaults setObject:@(usesRotation) forKey:HUDUserDefaultsKeyUsesRotation];
    [self saveUserDefaults];
}

- (BOOL)usesInvertedColor
{
    [self loadUserDefaults:NO];
    NSNumber *mode = [_userDefaults objectForKey:HUDUserDefaultsKeyUsesInvertedColor];
    return mode != nil ? [mode boolValue] : NO;
}

- (void)setUsesInvertedColor:(BOOL)usesInvertedColor
{
    [self loadUserDefaults:NO];
    [_userDefaults setObject:@(usesInvertedColor) forKey:HUDUserDefaultsKeyUsesInvertedColor];
    [self saveUserDefaults];
}

- (BOOL)keepInPlace
{
    [self loadUserDefaults:NO];
    NSNumber *mode = [_userDefaults objectForKey:HUDUserDefaultsKeyKeepInPlace];
    return mode != nil ? [mode boolValue] : NO;
}

- (void)setKeepInPlace:(BOOL)keepInPlace
{
    [self loadUserDefaults:NO];
    [_userDefaults setObject:@(keepInPlace) forKey:HUDUserDefaultsKeyKeepInPlace];
    [self saveUserDefaults];
}

- (BOOL)hideAtSnapshot
{
    [self loadUserDefaults:NO];
    NSNumber *mode = [_userDefaults objectForKey:HUDUserDefaultsKeyHideAtSnapshot];
    return mode != nil ? [mode boolValue] : NO;
}

- (void)setHideAtSnapshot:(BOOL)hideAtSnapshot
{
    [self loadUserDefaults:NO];
    [_userDefaults setObject:@(hideAtSnapshot) forKey:HUDUserDefaultsKeyHideAtSnapshot];
    [self saveUserDefaults];
}

- (void)reloadMainButtonState
{
    _isRemoteHUDActive = [self isHUDEnabled];

    static NSAttributedString *hintAttributedString = nil;
    static NSAttributedString *creditsAttributedString = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSDictionary *defaultAttributes = @{
            NSForegroundColorAttributeName: [UIColor whiteColor],
            NSFontAttributeName: [UIFont systemFontOfSize:14],
        };

        NSMutableParagraphStyle *creditsParaStyle = [[NSMutableParagraphStyle alloc] init];
        creditsParaStyle.lineHeightMultiple = 1.2;
        creditsParaStyle.alignment = NSTextAlignmentCenter;

        NSDictionary *creditsAttributes = @{
            NSForegroundColorAttributeName: [UIColor whiteColor],
            NSFontAttributeName: [UIFont systemFontOfSize:14],
            NSParagraphStyleAttributeName: creditsParaStyle,
        };

        NSString *hintText = NSLocalizedString(@"You can quit this app now.\nThe HUD will persist on your screen.", nil);
        hintAttributedString = [[NSAttributedString alloc] initWithString:hintText attributes:defaultAttributes];

        NSTextAttachment *githubIcon = [NSTextAttachment textAttachmentWithImage:[UIImage imageNamed:@"github-mark-white"]];
        [githubIcon setBounds:CGRectMake(0, 0, 14, 14)];

        NSTextAttachment *i18nIcon = [NSTextAttachment textAttachmentWithImage:[UIImage systemImageNamed:@"character.bubble.fill"]];
        [i18nIcon setBounds:CGRectMake(0, 0, 14, 14)];

        NSAttributedString *githubIconText = [NSAttributedString attributedStringWithAttachment:githubIcon];
        NSMutableAttributedString *githubIconTextFull = [[NSMutableAttributedString alloc] initWithAttributedString:githubIconText];
        [githubIconTextFull appendAttributedString:[[NSAttributedString alloc] initWithString:@" " attributes:creditsAttributes]];

        NSAttributedString *i18nIconText = [NSAttributedString attributedStringWithAttachment:i18nIcon];
        NSMutableAttributedString *i18nIconTextFull = [[NSMutableAttributedString alloc] initWithAttributedString:i18nIconText];
        [i18nIconTextFull appendAttributedString:[[NSAttributedString alloc] initWithString:@" " attributes:creditsAttributes]];

        NSString *creditsText = NSLocalizedString(@"Made with ♥ by @GITHUB@Lessica and @GITHUB@jmpews\nTranslation @TRANSLATION@", nil);
        NSMutableAttributedString *creditsAttributedText = [[NSMutableAttributedString alloc] initWithString:creditsText attributes:creditsAttributes];

        // replace all "@GITHUB@" with github icon
        NSRange atRange;
        
        atRange = [creditsAttributedText.string rangeOfString:@"@GITHUB@"];
        while (atRange.location != NSNotFound) {
            [creditsAttributedText replaceCharactersInRange:atRange withAttributedString:githubIconTextFull];
            atRange = [creditsAttributedText.string rangeOfString:@"@GITHUB@"];
        }
        
        // replace all "@TRANSLATION@" with character bubble
        atRange = [creditsAttributedText.string rangeOfString:@"@TRANSLATION@"];
        while (atRange.location != NSNotFound) {
            [creditsAttributedText replaceCharactersInRange:atRange withAttributedString:i18nIconTextFull];
            atRange = [creditsAttributedText.string rangeOfString:@"@TRANSLATION@"];
        }

        creditsAttributedString = creditsAttributedText;
    });

    __weak typeof(self) weakSelf = self;
    [UIView transitionWithView:self.backgroundView duration:HUD_TRANSITION_DURATION options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf->_mainButton setTitle:(strongSelf->_isRemoteHUDActive ? NSLocalizedString(@"Exit HUD", nil) : NSLocalizedString(@"Open HUD", nil)) forState:UIControlStateNormal];
        [strongSelf->_authorLabel setAttributedText:(strongSelf->_isRemoteHUDActive ? hintAttributedString : creditsAttributedString)];
    } completion:nil];
}

- (void)presentTopCenterMostHints
{
    if (!_isRemoteHUDActive) {
        return;
    }
    [_authorLabel setText:NSLocalizedString(@"Tap that button on the center again,\nto toggle ON/OFF “Dynamic Island” mode.", nil)];
}

- (BOOL)settingHighlightedWithKey:(NSString * _Nonnull)key
{
    [self loadUserDefaults:NO];
    NSNumber *mode = [_userDefaults objectForKey:key];
    return mode != nil ? [mode boolValue] : NO;
}

- (void)settingDidSelectWithKey:(NSString * _Nonnull)key
{
    BOOL highlighted = [self settingHighlightedWithKey:key];
    [_userDefaults setObject:@(!highlighted) forKey:key];
    [self saveUserDefaults];
}

- (void)reloadModeButtonState
{
    HUDPresetPosition selectedMode = [self selectedModeForCurrentOrientation];
    BOOL isCentered = (selectedMode == HUDPresetPositionTopCenter || selectedMode == HUDPresetPositionTopCenterMost);
    BOOL isCenteredMost = (selectedMode == HUDPresetPositionTopCenterMost);
    [_topLeftButton setSelected:(selectedMode == HUDPresetPositionTopLeft)];
    [_topCenterButton setSelected:isCentered];
    [_topRightButton setSelected:(selectedMode == HUDPresetPositionTopRight)];
    UIImage *topCenterImage = (isCenteredMost ? [UIImage systemImageNamed:@"arrow.up.to.line"] : [UIImage systemImageNamed:@"arrow.up"]);
    [_topCenterButton setImage:topCenterImage forState:UIControlStateNormal];
}

- (void)tapAuthorLabel:(UITapGestureRecognizer *)sender
{
    if (_isRemoteHUDActive) {
        return;
    }
    NSString *repoURLString = @"https://trollspeed.app";
    NSURL *repoURL = [NSURL URLWithString:repoURLString];
    [[UIApplication sharedApplication] openURL:repoURL options:@{} completionHandler:nil];
}

- (void)tapTopLeftButton:(UIButton *)sender
{
    log_debug(OS_LOG_DEFAULT, "- [RootViewController tapTopLeftButton:%{public}@]", sender);
    [self setSelectedModeForCurrentOrientation:HUDPresetPositionTopLeft];
    [self reloadModeButtonState];
}

- (void)tapTopRightButton:(UIButton *)sender
{
    log_debug(OS_LOG_DEFAULT, "- [RootViewController tapTopRightButton:%{public}@]", sender);
    [self setSelectedModeForCurrentOrientation:HUDPresetPositionTopRight];
    [self reloadModeButtonState];
}

- (void)tapTopCenterButton:(UIButton *)sender
{
    log_debug(OS_LOG_DEFAULT, "- [RootViewController tapTopCenterButton:%{public}@]", sender);
    HUDPresetPosition selectedMode = [self selectedModeForCurrentOrientation];
    BOOL isCenteredMost = (selectedMode == HUDPresetPositionTopCenterMost);
    if (!sender.isSelected || !_supportsCenterMost) {
        [self setSelectedModeForCurrentOrientation:HUDPresetPositionTopCenter];
        if (_supportsCenterMost) {
            [self presentTopCenterMostHints];
        }
    } else {
        if (isCenteredMost) {
            [self setSelectedModeForCurrentOrientation:HUDPresetPositionTopCenter];
        } else {
            [self setSelectedModeForCurrentOrientation:HUDPresetPositionTopCenterMost];
        }
    }
    [self reloadModeButtonState];
}

- (void)tapMainButton:(UIButton *)sender
{
    log_debug(OS_LOG_DEFAULT, "- [RootViewController tapMainButton:%{public}@]", sender);

    BOOL isNowEnabled = [self isHUDEnabled];
    [self setHUDEnabled:!isNowEnabled];
    isNowEnabled = !isNowEnabled;

    if (isNowEnabled)
    {
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

        [_impactFeedbackGenerator prepare];
        int anyToken;
        __weak typeof(self) weakSelf = self;
        notify_register_dispatch(NOTIFY_LAUNCHED_HUD, &anyToken, dispatch_get_main_queue(), ^(int token) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            notify_cancel(token);
            [strongSelf->_impactFeedbackGenerator impactOccurred];
            dispatch_semaphore_signal(semaphore);
        });

        [self.backgroundView setUserInteractionEnabled:NO];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
            intptr_t timedOut = dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)));
            dispatch_async(dispatch_get_main_queue(), ^{
                if (timedOut) {
                    log_error(OS_LOG_DEFAULT, "Timed out waiting for HUD to launch");
                }
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
    log_debug(OS_LOG_DEFAULT, "- [RootViewController tapSettingsButton:%{public}@]", sender);

    TSSettingsController *settingsViewController = [[TSSettingsController alloc] init];
    settingsViewController.delegate = self;
    settingsViewController.alreadyLaunched = _isRemoteHUDActive;

    SPLarkTransitioningDelegate *transitioningDelegate = [[SPLarkTransitioningDelegate alloc] init];
    settingsViewController.transitioningDelegate = transitioningDelegate;
    settingsViewController.modalPresentationStyle = UIModalPresentationCustom;
    settingsViewController.modalPresentationCapturesStatusBarAppearance = YES;
    [self presentViewController:settingsViewController animated:YES completion:nil];
}

- (void)verticalSizeClassUpdated
{
    UIUserInterfaceSizeClass verticalClass = self.traitCollection.verticalSizeClass;
    BOOL isPad = ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad);
    if (verticalClass == UIUserInterfaceSizeClassCompact) {
        CGFloat topConstant = _gTopButtonConstraintsConstantCompact;
        [_settingsButton setHidden:YES];
        [_authorLabelBottomConstraint setConstant:_gAuthorLabelBottomConstraintConstantCompact];
        [_topLeftConstraint setConstant:topConstant];
        [_topRightConstraint setConstant:topConstant];
        [_topCenterConstraint setConstant:topConstant];
    } else {
        CGFloat topConstant = isPad ? _gTopButtonConstraintsConstantRegularPad : _gTopButtonConstraintsConstantRegular;
        [_settingsButton setHidden:NO];
        [_authorLabelBottomConstraint setConstant:_gAuthorLabelBottomConstraintConstantRegular];
        [_topLeftConstraint setConstant:topConstant];
        [_topRightConstraint setConstant:topConstant];
        [_topCenterConstraint setConstant:topConstant];
    }
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [self verticalSizeClassUpdated];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];

    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        [self reloadModeButtonState];
    } completion:nil];
}

@end
