#import <notify.h>
#import <net/if.h>
#import <ifaddrs.h>
#import <objc/runtime.h>
#import <mach/vm_param.h>

#import "HUDPresetPosition.h"
#import "HUDRootViewController.h"
#import "TrollSpeed-Swift.h"

#pragma mark -

#if !NO_TROLL
#import "FBSOrientationUpdate.h"
#import "FBSOrientationObserver.h"
#import "UIApplication+Private.h"
#import "LSApplicationProxy.h"
#import "LSApplicationWorkspace.h"
#import "SpringBoardServices.h"

#define NOTIFY_UI_LOCKSTATE    "com.apple.springboard.lockstate"
#define NOTIFY_LS_APP_CHANGED  "com.apple.LaunchServices.ApplicationsChanged"

static void LaunchServicesApplicationStateChanged
(CFNotificationCenterRef center,
 void *observer,
 CFStringRef name,
 const void *object,
 CFDictionaryRef userInfo)
{
    /* Application installed or uninstalled */

    BOOL isAppInstalled = NO;
    
    for (LSApplicationProxy *app in [[objc_getClass("LSApplicationWorkspace") defaultWorkspace] allApplications])
    {
        if ([app.applicationIdentifier isEqualToString:@"ch.xxtou.hudapp"])
        {
            isAppInstalled = YES;
            break;
        }
    }

    if (!isAppInstalled)
    {
        UIApplication *app = [UIApplication sharedApplication];
        [app terminateWithSuccess];
    }
}

static void SpringBoardLockStatusChanged
(CFNotificationCenterRef center,
 void *observer,
 CFStringRef name,
 const void *object,
 CFDictionaryRef userInfo)
{
    HUDRootViewController *rootViewController = (__bridge HUDRootViewController *)observer;
    NSString *lockState = (__bridge NSString *)name;
    if ([lockState isEqualToString:@NOTIFY_UI_LOCKSTATE])
    {
        mach_port_t sbsPort = SBSSpringBoardServerPort();
        
        if (sbsPort == MACH_PORT_NULL)
            return;
        
        BOOL isLocked;
        BOOL isPasscodeSet;
        SBGetScreenLockStatus(sbsPort, &isLocked, &isPasscodeSet);

        if (!isLocked)
        {
            [rootViewController.view setHidden:NO];
            [rootViewController resetLoopTimer];
        }
        else
        {
            [rootViewController stopLoopTimer];
            [rootViewController.view setHidden:YES];
        }
    }
}
#endif

#pragma mark - NetworkSpeed13

// Thanks to: https://github.com/lwlsw/NetworkSpeed13

#define KILOBITS 1000
#define MEGABITS 1000000
#define GIGABITS 1000000000
#define KILOBYTES (1 << 10)
#define MEGABYTES (1 << 20)
#define GIGABYTES (1 << 30)
#define UPDATE_INTERVAL 1.0
#define SHOW_ALWAYS 1
#define INLINE_SEPARATOR "\t"
#define IDLE_INTERVAL 3.0

static double FONT_SIZE = 8.0;
static uint8_t DATAUNIT = 0;
static uint8_t SHOW_UPLOAD_SPEED = 1;
static uint8_t SHOW_DOWNLOAD_SPEED = 1;
static uint8_t SHOW_DOWNLOAD_SPEED_FIRST = 1;
static uint8_t SHOW_SECOND_SPEED_IN_NEW_LINE = 0;
static const char *UPLOAD_PREFIX = "▲";
static const char *DOWNLOAD_PREFIX = "▼";

typedef struct {
    uint64_t inputBytes;
    uint64_t outputBytes;
} UpDownBytes;

static NSString *formattedSpeed(uint64_t bytes, BOOL isFocused)
{
    if (isFocused)
    {
        if (0 == DATAUNIT)
        {
            if (bytes < KILOBYTES) return NSLocalizedString(@"0 KB", @"formattedSpeed");
            else if (bytes < MEGABYTES) return [NSString stringWithFormat:NSLocalizedString(@"%.0f KB", @"formattedSpeed"), (double)bytes / KILOBYTES];
            else if (bytes < GIGABYTES) return [NSString stringWithFormat:NSLocalizedString(@"%.2f MB", @"formattedSpeed"), (double)bytes / MEGABYTES];
            else return [NSString stringWithFormat:NSLocalizedString(@"%.2f GB", @"formattedSpeed"), (double)bytes / GIGABYTES];
        }
        else
        {
            if (bytes < KILOBITS) return NSLocalizedString(@"0 Kb", @"formattedSpeed");
            else if (bytes < MEGABITS) return [NSString stringWithFormat:NSLocalizedString(@"%.0f Kb", @"formattedSpeed"), (double)bytes / KILOBITS];
            else if (bytes < GIGABITS) return [NSString stringWithFormat:NSLocalizedString(@"%.2f Mb", @"formattedSpeed"), (double)bytes / MEGABITS];
            else return [NSString stringWithFormat:NSLocalizedString(@"%.2f Gb", @"formattedSpeed"), (double)bytes / GIGABITS];
        }
    }
    else {
        if (0 == DATAUNIT)
        {
            if (bytes < KILOBYTES) return NSLocalizedString(@"0 KB/s", @"formattedSpeed");
            else if (bytes < MEGABYTES) return [NSString stringWithFormat:NSLocalizedString(@"%.0f KB/s", @"formattedSpeed"), (double)bytes / KILOBYTES];
            else if (bytes < GIGABYTES) return [NSString stringWithFormat:NSLocalizedString(@"%.2f MB/s", @"formattedSpeed"), (double)bytes / MEGABYTES];
            else return [NSString stringWithFormat:NSLocalizedString(@"%.2f GB/s", @"formattedSpeed"), (double)bytes / GIGABYTES];
        }
        else
        {
            if (bytes < KILOBITS) return NSLocalizedString(@"0 Kb/s", @"formattedSpeed");
            else if (bytes < MEGABITS) return [NSString stringWithFormat:NSLocalizedString(@"%.0f Kb/s", @"formattedSpeed"), (double)bytes / KILOBITS];
            else if (bytes < GIGABITS) return [NSString stringWithFormat:NSLocalizedString(@"%.2f Mb/s", @"formattedSpeed"), (double)bytes / MEGABITS];
            else return [NSString stringWithFormat:NSLocalizedString(@"%.2f Gb/s", @"formattedSpeed"), (double)bytes / GIGABITS];
        }
    }
}

static UpDownBytes getUpDownBytes()
{
    struct ifaddrs *ifa_list = 0, *ifa;
    UpDownBytes upDownBytes;
    upDownBytes.inputBytes = 0;
    upDownBytes.outputBytes = 0;
    
    if (getifaddrs(&ifa_list) == -1) return upDownBytes;

    for (ifa = ifa_list; ifa; ifa = ifa->ifa_next)
    {
        /* Skip invalid interfaces */
        if (ifa->ifa_name == NULL || ifa->ifa_addr == NULL || ifa->ifa_data == NULL)
            continue;
        
        /* Skip interfaces that are not link level interfaces */
        if (AF_LINK != ifa->ifa_addr->sa_family)
            continue;

        /* Skip interfaces that are not up or running */
        if (!(ifa->ifa_flags & IFF_UP) && !(ifa->ifa_flags & IFF_RUNNING))
            continue;
        
        /* Skip interfaces that are not ethernet or cellular */
        if (strncmp(ifa->ifa_name, "en", 2) && strncmp(ifa->ifa_name, "pdp_ip", 6))
            continue;
        
        struct if_data *if_data = (struct if_data *)ifa->ifa_data;
        
        upDownBytes.inputBytes += if_data->ifi_ibytes;
        upDownBytes.outputBytes += if_data->ifi_obytes;
    }
    
    freeifaddrs(ifa_list);
    return upDownBytes;
}

static BOOL shouldUpdateSpeedLabel;
static uint64_t prevOutputBytes = 0, prevInputBytes = 0;
static NSAttributedString *attributedUploadPrefix = nil;
static NSAttributedString *attributedDownloadPrefix = nil;
static NSAttributedString *attributedInlineSeparator = nil;
static NSAttributedString *attributedLineSeparator = nil;

static NSAttributedString* formattedAttributedString(BOOL isFocused)
{
    @autoreleasepool
    {
        if (!attributedUploadPrefix)
            attributedUploadPrefix = [[NSAttributedString alloc] initWithString:[[NSString stringWithUTF8String:UPLOAD_PREFIX] stringByAppendingString:@" "] attributes:@{NSFontAttributeName: [UIFont boldSystemFontOfSize:FONT_SIZE]}];
        if (!attributedDownloadPrefix)
            attributedDownloadPrefix = [[NSAttributedString alloc] initWithString:[[NSString stringWithUTF8String:DOWNLOAD_PREFIX] stringByAppendingString:@" "] attributes:@{NSFontAttributeName: [UIFont boldSystemFontOfSize:FONT_SIZE]}];
        if (!attributedInlineSeparator)
            attributedInlineSeparator = [[NSAttributedString alloc] initWithString:[NSString stringWithUTF8String:INLINE_SEPARATOR] attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:FONT_SIZE]}];
        if (!attributedLineSeparator)
            attributedLineSeparator = [[NSAttributedString alloc] initWithString:@"\n" attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:FONT_SIZE]}];

        NSMutableAttributedString* mutableString = [[NSMutableAttributedString alloc] init];
        
        UpDownBytes upDownBytes = getUpDownBytes();

        uint64_t upDiff;
        uint64_t downDiff;

        if (isFocused)
        {
            upDiff = upDownBytes.outputBytes;
            downDiff = upDownBytes.inputBytes;
        }
        else
        {
            if (upDownBytes.outputBytes > prevOutputBytes)
                upDiff = upDownBytes.outputBytes - prevOutputBytes;
            else
                upDiff = 0;
            
            if (upDownBytes.inputBytes > prevInputBytes)
                downDiff = upDownBytes.inputBytes - prevInputBytes;
            else
                downDiff = 0;
        }
        
        prevOutputBytes = upDownBytes.outputBytes;
        prevInputBytes = upDownBytes.inputBytes;

        if (!SHOW_ALWAYS && (upDiff < 2 * KILOBYTES && downDiff < 2 * KILOBYTES))
        {
            shouldUpdateSpeedLabel = NO;
            return nil;
        }
        else shouldUpdateSpeedLabel = YES;

        if (DATAUNIT == 1)
        {
            upDiff *= BYTE_SIZE;
            downDiff *= BYTE_SIZE;
        }

        if (SHOW_DOWNLOAD_SPEED_FIRST)
        {
            if (SHOW_DOWNLOAD_SPEED)
            {
                [mutableString appendAttributedString:attributedDownloadPrefix];
                [mutableString appendAttributedString:[[NSAttributedString alloc] initWithString:formattedSpeed(downDiff, isFocused) attributes:@{NSFontAttributeName: [UIFont monospacedDigitSystemFontOfSize:FONT_SIZE weight:UIFontWeightRegular]}]];
            }

            if (SHOW_UPLOAD_SPEED)
            {
                if ([mutableString length] > 0)
                {
                    if (SHOW_SECOND_SPEED_IN_NEW_LINE) [mutableString appendAttributedString:attributedLineSeparator];
                    else [mutableString appendAttributedString:attributedInlineSeparator];
                }

                [mutableString appendAttributedString:attributedUploadPrefix];
                [mutableString appendAttributedString:[[NSAttributedString alloc] initWithString:formattedSpeed(upDiff, isFocused) attributes:@{NSFontAttributeName: [UIFont monospacedDigitSystemFontOfSize:FONT_SIZE weight:UIFontWeightRegular]}]];
            }
        }
        else
        {
            if (SHOW_UPLOAD_SPEED)
            {
                [mutableString appendAttributedString:attributedUploadPrefix];
                [mutableString appendAttributedString:[[NSAttributedString alloc] initWithString:formattedSpeed(upDiff, isFocused) attributes:@{NSFontAttributeName: [UIFont monospacedDigitSystemFontOfSize:FONT_SIZE weight:UIFontWeightRegular]}]];
            }
            if (SHOW_DOWNLOAD_SPEED)
            {
                if ([mutableString length] > 0)
                {
                    if (SHOW_SECOND_SPEED_IN_NEW_LINE) [mutableString appendAttributedString:attributedLineSeparator];
                    else [mutableString appendAttributedString:attributedInlineSeparator];
                }

                [mutableString appendAttributedString:attributedDownloadPrefix];
                [mutableString appendAttributedString:[[NSAttributedString alloc] initWithString:formattedSpeed(downDiff, isFocused) attributes:@{NSFontAttributeName: [UIFont monospacedDigitSystemFontOfSize:FONT_SIZE weight:UIFontWeightRegular]}]];
            }
        }
        
        return [mutableString copy];
    }
}

#pragma mark - HUDRootViewController

@interface HUDRootViewController (Troll)
- (void)updateOrientation:(UIInterfaceOrientation)orientation animateWithDuration:(NSTimeInterval)duration;
@end

// static const CACornerMask kCornerMaskNone = 0;
static const CACornerMask kCornerMaskBottom = kCALayerMinXMaxYCorner | kCALayerMaxXMaxYCorner;
static const CACornerMask kCornerMaskAll = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner | kCALayerMinXMaxYCorner | kCALayerMaxXMaxYCorner;

@implementation HUDRootViewController {
    NSMutableDictionary *_userDefaults;
    NSMutableArray <NSLayoutConstraint *> *_constraints;
    UIVisualEffectView *_blurView;
    ScreenshotInvisibleContainer *_containerView;
    UIView *_contentView;
    UILabel *_speedLabel;
    UIImageView *_lockedView;
    NSTimer *_timer;
    UITapGestureRecognizer *_tapGestureRecognizer;
    UIPanGestureRecognizer *_panGestureRecognizer;
    UIImpactFeedbackGenerator *_impactFeedbackGenerator;
    UINotificationFeedbackGenerator *_notificationFeedbackGenerator;
    BOOL _isFocused;
    UIInterfaceOrientation _remoteOrientation;
    UIInterfaceOrientation _localOrientation;
    NSLayoutConstraint *_topConstraint;
    NSLayoutConstraint *_centerXConstraint;
    NSLayoutConstraint *_leadingConstraint;
    NSLayoutConstraint *_trailingConstraint;
#if !NO_TROLL
    FBSOrientationObserver *_remoteOrientationObserver;
#endif
}

- (void)registerNotifications
{
    int token;
    notify_register_dispatch(NOTIFY_RELOAD_HUD, &token, dispatch_get_main_queue(), ^(int token) {
        [self reloadUserDefaults];
    });

#if !NO_TROLL
    CFNotificationCenterRef darwinCenter = CFNotificationCenterGetDarwinNotifyCenter();
    
    CFNotificationCenterAddObserver(
        darwinCenter,
        (__bridge const void *)self,
        LaunchServicesApplicationStateChanged,
        CFSTR(NOTIFY_LS_APP_CHANGED),
        NULL,
        CFNotificationSuspensionBehaviorCoalesce
    );
    
    CFNotificationCenterAddObserver(
        darwinCenter,
        (__bridge const void *)self,
        SpringBoardLockStatusChanged,
        CFSTR(NOTIFY_UI_LOCKSTATE),
        NULL,
        CFNotificationSuspensionBehaviorCoalesce
    );
#endif
}

- (void)loadUserDefaults:(BOOL)forceReload
{
    if (forceReload || !_userDefaults)
        _userDefaults = [[NSDictionary dictionaryWithContentsOfFile:(ROOT_PATH_NS_VAR(USER_DEFAULTS_PATH))] mutableCopy] ?: [NSMutableDictionary dictionary];
}

- (void)saveUserDefaults
{
    BOOL wroteSucceed = [_userDefaults writeToFile:(ROOT_PATH_NS_VAR(USER_DEFAULTS_PATH)) atomically:YES];
    if (wroteSucceed) {
        [[NSFileManager defaultManager] setAttributes:@{
            NSFileOwnerAccountID: @501,
            NSFileGroupOwnerAccountID: @501,
        } ofItemAtPath:(ROOT_PATH_NS_VAR(USER_DEFAULTS_PATH)) error:nil];
        notify_post(NOTIFY_RELOAD_APP);
    }
}

- (void)reloadUserDefaults
{
    [self loadUserDefaults:YES];

    HUDPresetPosition selectedMode = [self selectedMode];
    BOOL isCentered = (selectedMode == HUDPresetPositionTopCenter || selectedMode == HUDPresetPositionTopCenterMost);
    BOOL isCenteredMost = (selectedMode == HUDPresetPositionTopCenterMost);

    BOOL singleLineMode = [self singleLineMode];
    BOOL usesBitrate = [self usesBitrate];
    BOOL usesArrowPrefixes = [self usesArrowPrefixes];
    BOOL usesLargeFont = [self usesLargeFont] && !isCenteredMost;
    BOOL hideAtSnapshot = [self hideAtSnapshot];

    _blurView.layer.cornerRadius = (usesLargeFont ? 4.5 : 4.0);
    _speedLabel.textAlignment = (isCentered ? NSTextAlignmentCenter : NSTextAlignmentLeft);
    if (isCentered) {
        _lockedView.image = [UIImage systemImageNamed:@"hand.raised.slash.fill"];
    } else {
        _lockedView.image = [UIImage systemImageNamed:@"lock.fill"];
    }

    DATAUNIT = usesBitrate;
    SHOW_UPLOAD_SPEED = !singleLineMode;
    SHOW_DOWNLOAD_SPEED_FIRST = isCentered;
    SHOW_SECOND_SPEED_IN_NEW_LINE = !isCentered;
    FONT_SIZE = (usesLargeFont ? 9.0 : 8.0);

    UPLOAD_PREFIX = (usesArrowPrefixes ? "↑" : "▲");
    DOWNLOAD_PREFIX = (usesArrowPrefixes ? "↓" : "▼");

    prevInputBytes = 0;
    prevOutputBytes = 0;

    attributedUploadPrefix = nil;
    attributedDownloadPrefix = nil;

    if (hideAtSnapshot) {
        [_containerView setupContainerAsHideContentInScreenshots];
    } else {
        [_containerView setupContainerAsDisplayContentInScreenshots];
    }

    [self removeAllAnimations];
    [self resetGestureRecognizers];
    [self updateViewConstraints];

    if (!_isFocused) {
        [self onFocus:_contentView];
    } else {
        [self keepFocus:_contentView];
    }

    [self performSelector:@selector(onBlur:) withObject:_contentView afterDelay:IDLE_INTERVAL];
}

+ (BOOL)passthroughMode
{
    return [[[NSDictionary dictionaryWithContentsOfFile:(ROOT_PATH_NS_VAR(USER_DEFAULTS_PATH))] objectForKey:@"passthroughMode"] boolValue];
}

- (HUDPresetPosition)selectedMode
{
    [self loadUserDefaults:NO];
    NSNumber *mode = [_userDefaults objectForKey:@"selectedMode"];
    return mode != nil ? (HUDPresetPosition)[mode integerValue] : HUDPresetPositionTopCenter;
}

- (BOOL)singleLineMode
{
    [self loadUserDefaults:NO];
    NSNumber *mode = [_userDefaults objectForKey:@"singleLineMode"];
    return mode != nil ? [mode boolValue] : NO;
}

- (BOOL)usesBitrate
{
    [self loadUserDefaults:NO];
    NSNumber *mode = [_userDefaults objectForKey:@"usesBitrate"];
    return mode != nil ? [mode boolValue] : NO;
}

- (BOOL)usesArrowPrefixes
{
    [self loadUserDefaults:NO];
    NSNumber *mode = [_userDefaults objectForKey:@"usesArrowPrefixes"];
    return mode != nil ? [mode boolValue] : NO;
}

- (BOOL)usesLargeFont
{
    [self loadUserDefaults:NO];
    NSNumber *mode = [_userDefaults objectForKey:@"usesLargeFont"];
    return mode != nil ? [mode boolValue] : NO;
}

- (BOOL)usesRotation
{
    [self loadUserDefaults:NO];
    NSNumber *mode = [_userDefaults objectForKey:@"usesRotation"];
    return mode != nil ? [mode boolValue] : NO;
}

- (BOOL)keepInPlace
{
    [self loadUserDefaults:NO];
    NSNumber *mode = [_userDefaults objectForKey:@"keepInPlace"];
    return mode != nil ? [mode boolValue] : NO;
}

- (BOOL)hideAtSnapshot
{
    [self loadUserDefaults:NO];
    NSNumber *mode = [_userDefaults objectForKey:@"hideAtSnapshot"];
    return mode != nil ? [mode boolValue] : NO;
}

- (CGFloat)currentPositionY
{
    [self loadUserDefaults:NO];
    NSNumber *positionY = [_userDefaults objectForKey:@"currentPositionY"];
    return positionY != nil ? [positionY doubleValue] : CGFLOAT_MAX;
}

- (void)setCurrentPositionY:(CGFloat)positionY
{
    [self loadUserDefaults:NO];
    [_userDefaults setObject:[NSNumber numberWithDouble:positionY] forKey:@"currentPositionY"];
    [self saveUserDefaults];
}

- (CGFloat)currentLandscapePositionY
{
    [self loadUserDefaults:NO];
    NSNumber *positionY = [_userDefaults objectForKey:@"currentLandscapePositionY"];
    return positionY != nil ? [positionY doubleValue] : CGFLOAT_MAX;
}

- (void)setCurrentLandscapePositionY:(CGFloat)positionY
{
    [self loadUserDefaults:NO];
    [_userDefaults setObject:[NSNumber numberWithDouble:positionY] forKey:@"currentLandscapePositionY"];
    [self saveUserDefaults];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _constraints = [NSMutableArray array];
        [self registerNotifications];
#if !NO_TROLL
        _remoteOrientationObserver = [[objc_getClass("FBSOrientationObserver") alloc] init];
        __weak HUDRootViewController *weakSelf = self;
        [_remoteOrientationObserver setHandler:^(FBSOrientationUpdate *orientationUpdate) {
            HUDRootViewController *strongSelf = weakSelf;
            dispatch_async(dispatch_get_main_queue(), ^{
                [strongSelf updateOrientation:(UIInterfaceOrientation)orientationUpdate.orientation animateWithDuration:orientationUpdate.duration];
            });
        }];
#endif
    }
    return self;
}

- (void)dealloc
{
#if !NO_TROLL
    [_remoteOrientationObserver invalidate];
#endif
}

- (void)updateSpeedLabel
{
#if DEBUG
    os_log_debug(OS_LOG_DEFAULT, "updateSpeedLabel");
#endif
    NSAttributedString *attributedText = formattedAttributedString(_isFocused);
    if (attributedText)
        [_speedLabel setAttributedText:attributedText];
    [_speedLabel sizeToFit];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    /* Just put your HUD view here */

    _contentView = [[UIView alloc] init];
    _contentView.backgroundColor = [UIColor clearColor];
    _contentView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_contentView];

    _blurView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
    _blurView.layer.cornerRadius = 4.0;
    _blurView.layer.masksToBounds = YES;
    _blurView.translatesAutoresizingMaskIntoConstraints = NO;
    _containerView = [[ScreenshotInvisibleContainer alloc] initWithContent:_blurView];
    _containerView.hiddenContainer.translatesAutoresizingMaskIntoConstraints = NO;
    [_contentView addSubview:_containerView.hiddenContainer];

    _speedLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _speedLabel.numberOfLines = 0;
    _speedLabel.textAlignment = NSTextAlignmentCenter;
    _speedLabel.textColor = [UIColor whiteColor];
    _speedLabel.font = [UIFont systemFontOfSize:FONT_SIZE];
    _speedLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [_speedLabel setContentHuggingPriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisVertical];
    [_blurView.contentView addSubview:_speedLabel];

    _lockedView = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"lock.fill"]];
    _lockedView.tintColor = [UIColor whiteColor];
    _lockedView.translatesAutoresizingMaskIntoConstraints = NO;
    _lockedView.contentMode = UIViewContentModeScaleAspectFit;
    _lockedView.alpha = 0.0;
    [_lockedView setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisVertical];
    [_lockedView setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisVertical];
    [_blurView.contentView addSubview:_lockedView];

    _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureRecognized:)];
    _tapGestureRecognizer.numberOfTapsRequired = 1;
    _tapGestureRecognizer.numberOfTouchesRequired = 1;
    [_contentView addGestureRecognizer:_tapGestureRecognizer];

    _panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureRecognized:)];
    _panGestureRecognizer.minimumNumberOfTouches = 1;
    _panGestureRecognizer.maximumNumberOfTouches = 1;
    [_contentView addGestureRecognizer:_panGestureRecognizer];

    [_contentView setUserInteractionEnabled:YES];

    [self reloadUserDefaults];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    notify_post(NOTIFY_LAUNCHED_HUD);
}

- (void)resetLoopTimer
{
    [_timer invalidate];
    _timer = [NSTimer scheduledTimerWithTimeInterval:UPDATE_INTERVAL target:self selector:@selector(updateSpeedLabel) userInfo:nil repeats:YES];
}

- (void)stopLoopTimer
{
    [_timer invalidate];
    _timer = nil;
}

- (void)viewSafeAreaInsetsDidChange
{
    [super viewSafeAreaInsetsDidChange];
    [self removeAllAnimations];
    [self resetGestureRecognizers];
    [self updateViewConstraints];
}

- (void)updateViewConstraints
{
    [NSLayoutConstraint deactivateConstraints:_constraints];
    [_constraints removeAllObjects];

    HUDPresetPosition selectedMode = [self selectedMode];
    BOOL isCentered = (selectedMode == HUDPresetPositionTopCenter || selectedMode == HUDPresetPositionTopCenterMost);
    BOOL isCenteredMost = (selectedMode == HUDPresetPositionTopCenterMost);
    BOOL isPad = ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad);

#if !NO_TROLL
    UIInterfaceOrientation orientation = _remoteOrientation;
#else
    _localOrientation = [self.view.window.windowScene interfaceOrientation];
    UIInterfaceOrientation orientation = _localOrientation;
#endif

    BOOL isLandscape;
    if (orientation == UIInterfaceOrientationUnknown) {
        isLandscape = CGRectGetWidth(self.view.bounds) > CGRectGetHeight(self.view.bounds);
    } else {
        isLandscape = UIInterfaceOrientationIsLandscape(orientation);
    }
    _blurView.layer.maskedCorners = (isCenteredMost && !isLandscape) ? kCornerMaskBottom : kCornerMaskAll;

    UILayoutGuide *layoutGuide = self.view.safeAreaLayoutGuide;
    if (isLandscape)
    {
#if !NO_TROLL
        CGFloat notchHeight = CGRectGetMinY(layoutGuide.layoutFrame);
        CGFloat paddingNearNotch = (notchHeight > 40) ? notchHeight - 16 : 4;
        CGFloat paddingFarFromNotch = (notchHeight > 40) ? -24 : -4;
#else
        CGFloat notchHeight = CGRectGetMinX(layoutGuide.layoutFrame);
        CGFloat paddingNearNotch = (notchHeight > 40) ? -16 : 4;
        CGFloat paddingFarFromNotch = (notchHeight > 40) ? notchHeight - 24 : -4;
#endif

        [_constraints addObjectsFromArray:@[
            [_contentView.leadingAnchor constraintEqualToAnchor:layoutGuide.leadingAnchor constant:(orientation == UIInterfaceOrientationLandscapeLeft ? -paddingFarFromNotch : paddingNearNotch)],
            [_contentView.trailingAnchor constraintEqualToAnchor:layoutGuide.trailingAnchor constant:(orientation == UIInterfaceOrientationLandscapeLeft ? -paddingNearNotch : paddingFarFromNotch)],
        ]];

        CGFloat minimumLandscapeConstant = (isPad ? 30 : 10);

        /* Fixed Constraints */
        [_constraints addObjectsFromArray:@[
            [_contentView.topAnchor constraintGreaterThanOrEqualToAnchor:self.view.topAnchor constant:minimumLandscapeConstant],
            [_contentView.bottomAnchor constraintLessThanOrEqualToAnchor:self.view.bottomAnchor constant:-(minimumLandscapeConstant + 4)],
        ]];

        /* Flexible Constraint */
        _topConstraint = [_contentView.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:minimumLandscapeConstant];
        if (!isCentered) {
            CGFloat currentPositionY = [self currentLandscapePositionY];
            if (currentPositionY < CGFLOAT_MAX) {
                _topConstraint.constant = currentPositionY;
            }
        }
        _topConstraint.priority = UILayoutPriorityDefaultLow;

        [_constraints addObject:_topConstraint];
    }
    else
    {
        [_constraints addObjectsFromArray:@[
            [_contentView.leadingAnchor constraintEqualToAnchor:layoutGuide.leadingAnchor],
            [_contentView.trailingAnchor constraintEqualToAnchor:layoutGuide.trailingAnchor],
        ]];
        
        if (isCenteredMost && !isPad) {
            [_constraints addObject:[_contentView.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:0]];
        } else {
            CGFloat minimumTopConstraintConstant;
            if (CGRectGetMinY(layoutGuide.layoutFrame) > 40)
                minimumTopConstraintConstant = -10;
            else
                minimumTopConstraintConstant = (isPad ? 30 : 20);
            
            /* Fixed Constraints */
            [_constraints addObjectsFromArray:@[
                [_contentView.topAnchor constraintGreaterThanOrEqualToAnchor:layoutGuide.topAnchor constant:minimumTopConstraintConstant],
                [_contentView.bottomAnchor constraintLessThanOrEqualToAnchor:layoutGuide.bottomAnchor constant:-4],
            ]];
            
            /* Flexible Constraint */
            _topConstraint = [_contentView.topAnchor constraintEqualToAnchor:layoutGuide.topAnchor constant:minimumTopConstraintConstant];
            if (!isCentered) {
                CGFloat currentPositionY = [self currentPositionY];
                if (currentPositionY < CGFLOAT_MAX) {
                    _topConstraint.constant = currentPositionY;
                }
            }
            _topConstraint.priority = UILayoutPriorityDefaultLow;

            [_constraints addObject:_topConstraint];
        }
    }
    
    [_constraints addObjectsFromArray:@[
        [_speedLabel.topAnchor constraintEqualToAnchor:_contentView.topAnchor],
        [_speedLabel.bottomAnchor constraintEqualToAnchor:_contentView.bottomAnchor],
    ]];

    _centerXConstraint = [_speedLabel.centerXAnchor constraintEqualToAnchor:_contentView.centerXAnchor];
    if (isCentered) {
        [_constraints addObject:_centerXConstraint];
    }

    _leadingConstraint = [_speedLabel.leadingAnchor constraintEqualToAnchor:_contentView.leadingAnchor constant:10];
    if (selectedMode == HUDPresetPositionTopLeft) {
        [_constraints addObject:_leadingConstraint];
    }

    _trailingConstraint = [_speedLabel.trailingAnchor constraintEqualToAnchor:_contentView.trailingAnchor constant:-10];
    if (selectedMode == HUDPresetPositionTopRight) {
        [_constraints addObject:_trailingConstraint];
    }

    [_constraints addObjectsFromArray:@[
        [_blurView.topAnchor constraintEqualToAnchor:_speedLabel.topAnchor constant:-2],
        [_blurView.leadingAnchor constraintEqualToAnchor:_speedLabel.leadingAnchor constant:-4],
        [_blurView.trailingAnchor constraintEqualToAnchor:_speedLabel.trailingAnchor constant:4],
        [_blurView.bottomAnchor constraintEqualToAnchor:_speedLabel.bottomAnchor constant:2],
    ]];

    [_constraints addObjectsFromArray:@[
        [_lockedView.topAnchor constraintGreaterThanOrEqualToAnchor:_blurView.topAnchor constant:2],
        [_lockedView.centerXAnchor constraintEqualToAnchor:_blurView.centerXAnchor],
        [_lockedView.centerYAnchor constraintEqualToAnchor:_blurView.centerYAnchor],
    ]];

    [NSLayoutConstraint activateConstraints:_constraints];
    [super updateViewConstraints];
}

- (void)keepFocus:(UIView *)view
{
    [self onFocus:view duration:0];
}

- (void)onFocus:(UIView *)view
{
    [self onFocus:view duration:0.2];
}

- (void)onFocus:(UIView *)view duration:(NSTimeInterval)duration
{
    [self onFocus:view scaleFactor:0.1 duration:duration beginFromInitialState:YES blurWhenDone:YES];
}

- (void)onFocus:(UIView *)view scaleFactor:(CGFloat)scaleFactor duration:(NSTimeInterval)duration beginFromInitialState:(BOOL)beginFromInitialState blurWhenDone:(BOOL)blurWhenDone
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(onBlur:) object:view];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(onFocus:) object:view];
    
    _isFocused = YES;
    [self updateSpeedLabel];
    [self resetLoopTimer];

    HUDPresetPosition selectedMode = [self selectedMode];
    BOOL isCentered = (selectedMode == HUDPresetPositionTopCenter || selectedMode == HUDPresetPositionTopCenterMost);
    
    CGFloat topTrans = CGRectGetHeight(view.bounds) * (scaleFactor / 2);
    CGFloat leadingTrans = (isCentered ? 0 : (selectedMode == HUDPresetPositionTopLeft ? CGRectGetWidth(view.bounds) * (scaleFactor / 2) : -CGRectGetWidth(view.bounds) * (scaleFactor / 2)));

    if (beginFromInitialState)
        [view setTransform:CGAffineTransformIdentity];
    
    [UIView animateWithDuration:duration delay:0.0 usingSpringWithDamping:1.0 initialSpringVelocity:1.0 options:UIViewAnimationOptionCurveEaseIn | UIViewAnimationOptionBeginFromCurrentState animations:^{
        if (ABS(leadingTrans) > 1e-6 || ABS(topTrans) > 1e-6)
        {
            CGAffineTransform transform = CGAffineTransformMakeTranslation(leadingTrans, topTrans);
            view.transform = CGAffineTransformScale(transform, 1.0 + scaleFactor, 1.0 + scaleFactor);
        }

        view.alpha = 1.0;
    } completion:^(BOOL finished) {
        if (blurWhenDone)
            [self performSelector:@selector(onBlur:) withObject:view afterDelay:IDLE_INTERVAL];
    }];
}

- (void)onBlur:(UIView *)view
{
    [self onBlur:view duration:0.6];
}

- (void)onBlur:(UIView *)view duration:(NSTimeInterval)duration
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(onBlur:) object:view];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(onFocus:) object:view];
    
    _isFocused = NO;
    [self updateSpeedLabel];
    [self resetLoopTimer];

    [UIView animateWithDuration:duration delay:0.0 usingSpringWithDamping:1.0 initialSpringVelocity:1.0 options:UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionBeginFromCurrentState animations:^{
        view.transform = CGAffineTransformIdentity;
        view.alpha = 0.667;
    } completion:nil];
}

- (void)removeAllAnimations
{
    [_contentView.layer removeAllAnimations];
}

- (void)resetGestureRecognizers
{
    for (UIGestureRecognizer *recognizer in _contentView.gestureRecognizers)
    {
        [recognizer setEnabled:NO];
        [recognizer setEnabled:YES];
    }
}

- (void)tapGestureRecognized:(UITapGestureRecognizer *)sender
{
#if DEBUG
    os_log_info(OS_LOG_DEFAULT, "TAPPED");
#endif
    if (!_isFocused) {
        [self onFocus:sender.view];
    } else {
        [self keepFocus:sender.view];
    }
}

- (void)cancelPreviousPerformRequestsWithTarget:(UIView *)view
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(onBlur:) object:view];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(onFocus:) object:view];
}

- (void)flashLockedViewWithDuration:(NSTimeInterval)duration
{
    [_lockedView.layer removeAllAnimations];
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    animation.fromValue = [NSNumber numberWithFloat:0.0];
    animation.toValue = [NSNumber numberWithFloat:1.0];
    animation.duration = duration;
    animation.autoreverses = YES;
    animation.repeatCount = 1;
    animation.removedOnCompletion = YES;
    animation.fillMode = kCAFillModeForwards;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [_lockedView.layer addAnimation:animation forKey:@"opacity"];

    [_speedLabel.layer removeAllAnimations];
    CABasicAnimation *animationReverse = [CABasicAnimation animationWithKeyPath:@"opacity"];
    animationReverse.fromValue = [NSNumber numberWithFloat:1.0];
    animationReverse.toValue = [NSNumber numberWithFloat:0.0];
    animationReverse.duration = duration;
    animationReverse.autoreverses = YES;
    animationReverse.repeatCount = 1;
    animationReverse.removedOnCompletion = YES;
    animationReverse.fillMode = kCAFillModeForwards;
    animationReverse.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [_speedLabel.layer addAnimation:animationReverse forKey:@"opacity"];
}

- (void)panGestureRecognized:(UIPanGestureRecognizer *)sender
{
    if (!_isFocused)
        return;
    
    HUDPresetPosition selectedMode = [self selectedMode];
    BOOL isCentered = (selectedMode == HUDPresetPositionTopCenter || selectedMode == HUDPresetPositionTopCenterMost);
    
    if (isCentered || [self keepInPlace])
    {
        if (sender.state == UIGestureRecognizerStateBegan)
            [self cancelPreviousPerformRequestsWithTarget:sender.view];
        else if (sender.state == UIGestureRecognizerStateFailed || sender.state == UIGestureRecognizerStateEnded || sender.state == UIGestureRecognizerStateCancelled)
            [self performSelector:@selector(onBlur:) withObject:sender.view afterDelay:IDLE_INTERVAL];

        if (sender.state == UIGestureRecognizerStateBegan)
        {
            if (!_notificationFeedbackGenerator)
                _notificationFeedbackGenerator = [[UINotificationFeedbackGenerator alloc] init];
            
            [_notificationFeedbackGenerator prepare];
            [_notificationFeedbackGenerator notificationOccurred:UINotificationFeedbackTypeError];

            [self flashLockedViewWithDuration:0.2];
        }
        
        return;
    }

    static CGFloat beginConstantY = 0.0;
    if (sender.state == UIGestureRecognizerStatePossible || sender.state == UIGestureRecognizerStateBegan)
    {
        beginConstantY = _topConstraint.constant;
        [self onFocus:sender.view scaleFactor:0.2 duration:0.1 beginFromInitialState:NO blurWhenDone:NO];
    }
    else
    {
        if (sender.state == UIGestureRecognizerStateChanged || sender.state == UIGestureRecognizerStateEnded)
        {
            CGFloat currentOffsetY = [sender translationInView:sender.view.superview].y;
            [_topConstraint setConstant:beginConstantY + currentOffsetY];
        }
        
        if (sender.state == UIGestureRecognizerStateEnded)
        {
            if (UIInterfaceOrientationIsLandscape(_localOrientation))
                [self setCurrentLandscapePositionY:_topConstraint.constant];
            else
                [self setCurrentPositionY:_topConstraint.constant];
        }
        
        if (sender.state != UIGestureRecognizerStateChanged)
        {
            [self onFocus:sender.view scaleFactor:0.1 duration:0.1 beginFromInitialState:NO blurWhenDone:NO];
            [self reloadUserDefaults];
        }
    }

    if (!_impactFeedbackGenerator)
    {
        _impactFeedbackGenerator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];
    }

    if (sender.state == UIGestureRecognizerStateBegan || sender.state == UIGestureRecognizerStateEnded || sender.state == UIGestureRecognizerStateCancelled)
    {
        [_impactFeedbackGenerator prepare];
        [_impactFeedbackGenerator impactOccurred];
    }
}

@end

#if !NO_TROLL
@implementation HUDRootViewController (Troll)

static inline CGFloat orientationAngle(UIInterfaceOrientation orientation)
{
    switch (orientation) {
        case UIInterfaceOrientationPortraitUpsideDown:
            return M_PI;
        case UIInterfaceOrientationLandscapeLeft:
            return -M_PI_2;
        case UIInterfaceOrientationLandscapeRight:
            return M_PI_2;
        default:
            return 0;
    }
}

static inline CGRect orientationBounds(UIInterfaceOrientation orientation, CGRect bounds)
{
    switch (orientation) {
        case UIInterfaceOrientationLandscapeLeft:
        case UIInterfaceOrientationLandscapeRight:
            return CGRectMake(0, 0, bounds.size.height, bounds.size.width);
        default:
            return bounds;
    }
}

- (void)updateOrientation:(UIInterfaceOrientation)orientation animateWithDuration:(NSTimeInterval)duration
{
    BOOL usesRotation = [self usesRotation];

    if (!usesRotation)
    {
        [self onBlur:_contentView duration:0];

        if (orientation == UIInterfaceOrientationPortrait)
        {
            __weak typeof(self) weakSelf = self;
            [UIView animateWithDuration:duration animations:^{
                __strong typeof(weakSelf) strongSelf = weakSelf;
                strongSelf->_contentView.alpha = strongSelf->_isFocused ? 1.0 : 0.667;
            }];
        }
        else
        {
            __weak typeof(self) weakSelf = self;
            [UIView animateWithDuration:duration animations:^{
                __strong typeof(weakSelf) strongSelf = weakSelf;
                strongSelf->_contentView.alpha = 0.0;
            }];
        }

        return;
    }

    if (orientation == _remoteOrientation) {
        return;
    }

    _remoteOrientation = orientation;
    [self cancelPreviousPerformRequestsWithTarget:_contentView];

    CGRect bounds = orientationBounds(orientation, [UIScreen mainScreen].bounds);
    [self.view setNeedsUpdateConstraints];
    [self.view setHidden:YES];
    [self.view setBounds:bounds];

    [self resetGestureRecognizers];
    [self onBlur:_contentView duration:duration];

    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:duration animations:^{
        [weakSelf.view setTransform:CGAffineTransformMakeRotation(orientationAngle(orientation))];
    } completion:^(BOOL finished) {
        [weakSelf.view setHidden:NO];
    }];
}

@end
#else
@implementation HUDRootViewController (NoTroll)

- (UIModalPresentationStyle)modalPresentationStyle { return UIModalPresentationOverFullScreen; }
- (UIModalTransitionStyle)modalTransitionStyle { return UIModalTransitionStyleCrossDissolve; }

- (void)viewWillTransitionToSize:(CGSize)size
       withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];

    BOOL usesRotation = [self usesRotation];
    __weak typeof(self) weakSelf = self;
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> _Nonnull context)
     {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        UIInterfaceOrientation orientation = [strongSelf.view.window.windowScene interfaceOrientation];

        if (!usesRotation)
        {
            [strongSelf onBlur:strongSelf->_contentView duration:0];

            if (orientation == UIInterfaceOrientationPortrait) {
                strongSelf->_contentView.alpha = strongSelf->_isFocused ? 1.0 : 0.667;
            } else {
                strongSelf->_contentView.alpha = 0.0;
            }
        }
        else
        {
            if (orientation == strongSelf->_localOrientation) {
                return;
            }

            strongSelf->_localOrientation = orientation;
            [strongSelf cancelPreviousPerformRequestsWithTarget:strongSelf->_contentView];

            [strongSelf.view setNeedsUpdateConstraints];
            [strongSelf.view setHidden:YES];

            [strongSelf resetGestureRecognizers];
            [strongSelf onBlur:strongSelf->_contentView duration:context.transitionDuration];
        }
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> _Nonnull context)
     {
        if (usesRotation)
        {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            [strongSelf.view setHidden:NO];
        }
    }];
}

@end
#endif
