#import <cstddef>
#import <cstdlib>
#import <dlfcn.h>
#import <spawn.h>
#import <unistd.h>
#import <notify.h>
#import <net/if.h>
#import <ifaddrs.h>
#import <sys/wait.h>
#import <sys/types.h>
#import <sys/sysctl.h>
#import <mach-o/dyld.h>
#import <objc/runtime.h>


extern "C" char **environ;

#define POSIX_SPAWN_PERSONA_FLAGS_OVERRIDE 1
extern "C" int posix_spawnattr_set_persona_np(const posix_spawnattr_t* __restrict, uid_t, uint32_t);
extern "C" int posix_spawnattr_set_persona_uid_np(const posix_spawnattr_t* __restrict, uid_t);
extern "C" int posix_spawnattr_set_persona_gid_np(const posix_spawnattr_t* __restrict, uid_t);


OBJC_EXTERN BOOL IsHUDEnabled(void);
BOOL IsHUDEnabled(void)
{
    static char *executablePath = NULL;
    uint32_t executablePathSize = 0;
    _NSGetExecutablePath(NULL, &executablePathSize);
    executablePath = (char *)calloc(1, executablePathSize);
    _NSGetExecutablePath(executablePath, &executablePathSize);

    posix_spawnattr_t attr;
    posix_spawnattr_init(&attr);

    posix_spawnattr_set_persona_np(&attr, 99, POSIX_SPAWN_PERSONA_FLAGS_OVERRIDE);
    posix_spawnattr_set_persona_uid_np(&attr, 0);
    posix_spawnattr_set_persona_gid_np(&attr, 0);

    pid_t task_pid;
    const char *args[] = { executablePath, "-check", NULL };
    posix_spawn(&task_pid, executablePath, NULL, &attr, (char **)args, environ);
    posix_spawnattr_destroy(&attr);

    os_log_debug(OS_LOG_DEFAULT, "spawned %{public}s -check pid = %{public}d", executablePath, task_pid);
    
    int status;
    do {
        if (waitpid(task_pid, &status, 0) != -1)
            os_log_debug(OS_LOG_DEFAULT, "child status %d", WEXITSTATUS(status));
    } while (!WIFEXITED(status) && !WIFSIGNALED(status));

    return WEXITSTATUS(status) != 0;
}

OBJC_EXTERN void SetHUDEnabled(BOOL isEnabled);
void SetHUDEnabled(BOOL isEnabled)
{
#ifdef NOTIFY_DISMISSAL_HUD
    notify_post(NOTIFY_DISMISSAL_HUD);
#endif

    static char *executablePath = NULL;
    uint32_t executablePathSize = 0;
    _NSGetExecutablePath(NULL, &executablePathSize);
    executablePath = (char *)calloc(1, executablePathSize);
    _NSGetExecutablePath(executablePath, &executablePathSize);

    posix_spawnattr_t attr;
    posix_spawnattr_init(&attr);

    posix_spawnattr_set_persona_np(&attr, 99, POSIX_SPAWN_PERSONA_FLAGS_OVERRIDE);
    posix_spawnattr_set_persona_uid_np(&attr, 0);
    posix_spawnattr_set_persona_gid_np(&attr, 0);

    if (isEnabled)
    {
        posix_spawnattr_setpgroup(&attr, 0);
        posix_spawnattr_setflags(&attr, POSIX_SPAWN_SETPGROUP);

        pid_t task_pid;
        const char *args[] = { executablePath, "-hud", NULL };
        posix_spawn(&task_pid, executablePath, NULL, &attr, (char **)args, environ);
        posix_spawnattr_destroy(&attr);

        os_log_debug(OS_LOG_DEFAULT, "spawned %{public}s -hud pid = %{public}d", executablePath, task_pid);
    }
    else
    {
        [NSThread sleepForTimeInterval:0.25];

        pid_t task_pid;
        const char *args[] = { executablePath, "-exit", NULL };
        posix_spawn(&task_pid, executablePath, NULL, &attr, (char **)args, environ);
        posix_spawnattr_destroy(&attr);

        os_log_debug(OS_LOG_DEFAULT, "spawned %{public}s -exit pid = %{public}d", executablePath, task_pid);
        
        int status;
        do {
            if (waitpid(task_pid, &status, 0) != -1)
                os_log_debug(OS_LOG_DEFAULT, "child status %d", WEXITSTATUS(status));
        } while (!WIFEXITED(status) && !WIFSIGNALED(status));
    }
}


#pragma mark -

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
#define FONT_SIZE 8.0

static uint8_t DATAUNIT = 0;
static uint8_t SHOW_UPLOAD_SPEED = 1;
static uint8_t SHOW_DOWNLOAD_SPEED = 1;
static uint8_t SHOW_DOWNLOAD_SPEED_FIRST = 1;
static uint8_t SHOW_SECOND_SPEED_IN_NEW_LINE = 0;
static uint8_t SHOW_FPS = 0;
static const char *UPLOAD_PREFIX = "▲";
static const char *DOWNLOAD_PREFIX = "▼";

typedef struct {
    uint64_t inputBytes;
    uint64_t outputBytes;
} UpDownBytes;

static NSString* formattedSpeed(uint64_t bytes, BOOL isFocused)
{
    if (isFocused)
    {
        if (0 == DATAUNIT)
        {
            if (bytes < KILOBYTES) return @"0 KB";
            else if (bytes < MEGABYTES) return [NSString stringWithFormat:@"%.0f KB", (double)bytes / KILOBYTES];
            else if (bytes < GIGABYTES) return [NSString stringWithFormat:@"%.2f MB", (double)bytes / MEGABYTES];
            else return [NSString stringWithFormat:@"%.2f GB", (double)bytes / GIGABYTES];
        }
        else
        {
            if (bytes < KILOBITS) return @"0 Kb";
            else if (bytes < MEGABITS) return [NSString stringWithFormat:@"%.0f Kb", (double)bytes / KILOBITS];
            else if (bytes < GIGABITS) return [NSString stringWithFormat:@"%.2f Mb", (double)bytes / MEGABITS];
            else return [NSString stringWithFormat:@"%.2f Gb", (double)bytes / GIGABITS];
        }
    }
    else {
        if (0 == DATAUNIT)
        {
            if (bytes < KILOBYTES) return @"0 KB/s";
            else if (bytes < MEGABYTES) return [NSString stringWithFormat:@"%.0f KB/s", (double)bytes / KILOBYTES];
            else if (bytes < GIGABYTES) return [NSString stringWithFormat:@"%.2f MB/s", (double)bytes / MEGABYTES];
            else return [NSString stringWithFormat:@"%.2f GB/s", (double)bytes / GIGABYTES];
        }
        else
        {
            if (bytes < KILOBITS) return @"0 Kb/s";
            else if (bytes < MEGABITS) return [NSString stringWithFormat:@"%.0f Kb/s", (double)bytes / KILOBITS];
            else if (bytes < GIGABITS) return [NSString stringWithFormat:@"%.2f Mb/s", (double)bytes / MEGABITS];
            else return [NSString stringWithFormat:@"%.2f Gb/s", (double)bytes / GIGABITS];
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
        if (AF_LINK != ifa->ifa_addr->sa_family || 
            (!(ifa->ifa_flags & IFF_UP) && !(ifa->ifa_flags & IFF_RUNNING)) || 
            ifa->ifa_data == 0) continue;
        
        struct if_data *if_data = (struct if_data *)ifa->ifa_data;

        upDownBytes.inputBytes += if_data->ifi_ibytes;
        upDownBytes.outputBytes += if_data->ifi_obytes;
    }
    
    freeifaddrs(ifa_list);
    return upDownBytes;
}

#import <QuartzCore/QuartzCore.h>

@interface HUDDisplayLinkCounter : NSObject
@property (nonatomic, assign) uint64_t ticks;
@end

@implementation HUDDisplayLinkCounter {
    CADisplayLink *displayLink;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkTick:)];
        [displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    }
    return self;
}

- (void)dealloc {
    [displayLink invalidate];
    displayLink = nil;
}

- (void)displayLinkTick:(CADisplayLink *)sender {
    self.ticks++;
}

- (void)reset {
    self.ticks = 0;
}

@end

static BOOL shouldUpdateSpeedLabel;
static uint64_t prevOutputBytes = 0, prevInputBytes = 0;
static uint64_t lastTicks = 0;
static NSAttributedString *attributedUploadPrefix = nil;
static NSAttributedString *attributedDownloadPrefix = nil;
static NSAttributedString *attributedInlineSeparator = nil;
static NSAttributedString *attributedLineSeparator = nil;
static HUDDisplayLinkCounter *displayLinkCounter = nil;

static NSAttributedString* formattedAttributedString(BOOL isFocused)
{
    @autoreleasepool
    {
        if (SHOW_FPS)
        {
            if (!displayLinkCounter)
                displayLinkCounter = [[HUDDisplayLinkCounter alloc] init];

            uint64_t currentTicks = displayLinkCounter.ticks;
            uint64_t deltaTicks = currentTicks - lastTicks;
            lastTicks = currentTicks;
            
            if (deltaTicks == 0 || deltaTicks > 300)
                return nil;

            NSAttributedString *attrStr = 
                [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%llu fps", deltaTicks] attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:FONT_SIZE]}];

            return attrStr;
        }
        else
        {
            if (displayLinkCounter)
                displayLinkCounter = nil;
        }

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
            upDiff = (upDownBytes.outputBytes - prevOutputBytes) / UPDATE_INTERVAL;
            downDiff = (upDownBytes.inputBytes - prevInputBytes) / UPDATE_INTERVAL;
        }
        
        prevOutputBytes = upDownBytes.outputBytes;
        prevInputBytes = upDownBytes.inputBytes;

        if (!SHOW_ALWAYS && ((upDiff < 2 * KILOBYTES && downDiff < 2 * KILOBYTES) || (upDiff > 500 * MEGABYTES && downDiff > 500 * MEGABYTES)))
        {
            shouldUpdateSpeedLabel = NO;
            return nil;
        }
        else shouldUpdateSpeedLabel = YES;

        if (DATAUNIT == 1)
        {
            upDiff *= 8;
            downDiff *= 8;
        }

        if (SHOW_DOWNLOAD_SPEED_FIRST)
        {
            if (SHOW_DOWNLOAD_SPEED)
            {
                [mutableString appendAttributedString:attributedDownloadPrefix];
                [mutableString appendAttributedString:[[NSAttributedString alloc] initWithString:formattedSpeed(downDiff, isFocused) attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:FONT_SIZE]}]];
            }

            if (SHOW_UPLOAD_SPEED)
            {
                if ([mutableString length] > 0)
                {
                    if (SHOW_SECOND_SPEED_IN_NEW_LINE) [mutableString appendAttributedString:attributedLineSeparator];
                    else [mutableString appendAttributedString:attributedInlineSeparator];
                }

                [mutableString appendAttributedString:attributedUploadPrefix];
                [mutableString appendAttributedString:[[NSAttributedString alloc] initWithString:formattedSpeed(upDiff, isFocused) attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:FONT_SIZE]}]];
            }
        }
        else
        {
            if (SHOW_UPLOAD_SPEED)
            {
                [mutableString appendAttributedString:attributedUploadPrefix];
                [mutableString appendAttributedString:[[NSAttributedString alloc] initWithString:formattedSpeed(upDiff, isFocused) attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:FONT_SIZE]}]];
            }
            if (SHOW_DOWNLOAD_SPEED)
            {
                if ([mutableString length] > 0)
                {
                    if (SHOW_SECOND_SPEED_IN_NEW_LINE) [mutableString appendAttributedString:attributedLineSeparator];
                    else [mutableString appendAttributedString:attributedInlineSeparator];
                }

                [mutableString appendAttributedString:attributedDownloadPrefix];
                [mutableString appendAttributedString:[[NSAttributedString alloc] initWithString:formattedSpeed(downDiff, isFocused) attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:FONT_SIZE]}]];
            }
        }
        
        return [mutableString copy];
    }
}


@interface UIApplication (Private)
- (void)suspend;
- (void)terminateWithSuccess;
- (void)_run;
@end

@interface UIWindow (Private)
- (unsigned int)_contextId;
@end

@interface UIEventDispatcher : NSObject
- (void)_installEventRunLoopSources:(CFRunLoopRef)arg1;
@end

@interface UIEventFetcher : NSObject
- (void)setEventFetcherSink:(id)arg1;
- (void)displayLinkDidFire:(id)arg1;
@end

@interface _UIHIDEventSynchronizer : NSObject
- (void)_renderEvents:(id)arg1;
@end

@interface SBSAccessibilityWindowHostingController : NSObject
- (void)registerWindowWithContextID:(unsigned)arg1 atLevel:(double)arg2;
@end

@interface FBSOrientationObserver : NSObject
- (long long)activeInterfaceOrientation;
- (void)activeInterfaceOrientationWithCompletion:(id)arg1;
- (void)invalidate;
- (void)setHandler:(id)arg1;
- (id)handler;
@end

@interface FBSOrientationUpdate : NSObject
- (unsigned long long)sequenceNumber;
- (long long)rotationDirection;
- (long long)orientation;
- (double)duration;
@end


#pragma mark -

#import "UIAutoRotatingWindow.h"
#import "UIApplicationRotationFollowingControllerNoTouches.h"

@interface HUDMainApplicationDelegate : UIResponder <UIApplicationDelegate>
@property (nonatomic, strong) UIWindow *window;
@end

@interface HUDRootViewController: UIApplicationRotationFollowingControllerNoTouches
+ (BOOL)passthroughMode;
@end

@interface HUDMainWindow : UIAutoRotatingWindow
@end


#pragma mark - HUDMainApplication

#import <pthread.h>
#import <mach/mach.h>

#import "pac_helper.h"

static void DumpThreads(void)
{
    char name[256];
    mach_msg_type_number_t count;
    thread_act_array_t list;
    task_threads(mach_task_self(), &list, &count);
    for (int i = 0; i < count; ++i)
    {
        pthread_t pt = pthread_from_mach_thread_np(list[i]);
        if (pt)
        {
            name[0] = '\0';
            int rc = pthread_getname_np(pt, name, sizeof name);
            os_log_debug(OS_LOG_DEFAULT, "mach thread %u: getname returned %d: %{public}s", list[i], rc, name);
        }
        else
        {
            os_log_debug(OS_LOG_DEFAULT, "mach thread %u: no pthread found", list[i]);
        }
    }
}

@interface HUDMainApplication : UIApplication
@end

@implementation HUDMainApplication

- (instancetype)init
{
    if (self = [super init])
    {
        os_log_debug(OS_LOG_DEFAULT, "- [HUDMainApplication init]");
        notify_post(NOTIFY_LAUNCHED_HUD);
        
#ifdef NOTIFY_DISMISSAL_HUD
        {
            int token;
            notify_register_dispatch(NOTIFY_DISMISSAL_HUD, &token, dispatch_get_main_queue(), ^(int token) {
                notify_cancel(token);
                
                // Fade out the HUD window
                [UIView animateWithDuration:0.25f animations:^{
                    [[self.windows firstObject] setAlpha:0.0];
                } completion:^(BOOL finished) {
                    // Terminate the HUD app
                    [self terminateWithSuccess];
                }];
            });
        }
#endif
        do {
            UIEventDispatcher *dispatcher = (UIEventDispatcher *)[self valueForKey:@"eventDispatcher"];
            if (!dispatcher)
            {
                os_log_error(OS_LOG_DEFAULT, "failed to get ivar _eventDispatcher");
                break;
            }

            os_log_debug(OS_LOG_DEFAULT, "got ivar _eventDispatcher: %p", dispatcher);

            if ([dispatcher respondsToSelector:@selector(_installEventRunLoopSources:)])
            {
                CFRunLoopRef mainRunLoop = CFRunLoopGetMain();
                [dispatcher _installEventRunLoopSources:mainRunLoop];
            }
            else
            {
                IMP runMethodIMP = class_getMethodImplementation([self class], @selector(_run));
                if (!runMethodIMP)
                {
                    os_log_error(OS_LOG_DEFAULT, "failed to get - [UIApplication _run] method");
                    break;
                }

                uint32_t *runMethodPtr = (uint32_t *)make_sym_readable((void *)runMethodIMP);
                os_log_debug(OS_LOG_DEFAULT, "- [UIApplication _run]: %p", runMethodPtr);

                void (*orig_UIEventDispatcher__installEventRunLoopSources_)(id _Nonnull, SEL _Nonnull, CFRunLoopRef) = NULL;
                for (int i = 0; i < 0x140; i++)
                {
                    // mov x2, x0
                    // mov x0, x?
                    if (runMethodPtr[i] != 0xaa0003e2 || (runMethodPtr[i + 1] & 0xff000000) != 0xaa000000)
                        continue;
                    
                    // bl -[UIEventDispatcher _installEventRunLoopSources:]
                    uint32_t blInst = runMethodPtr[i + 2];
                    uint32_t *blInstPtr = &runMethodPtr[i + 2];
                    if ((blInst & 0xfc000000) != 0x94000000)
                    {
                        os_log_error(OS_LOG_DEFAULT, "not a BL instruction: 0x%x, address %p", blInst, blInstPtr);
                        continue;
                    }

                    os_log_debug(OS_LOG_DEFAULT, "found BL instruction: 0x%x, address %p", blInst, blInstPtr);

                    int32_t blOffset = blInst & 0x03ffffff;
                    if (blOffset & 0x02000000)
                        blOffset |= 0xfc000000;
                    blOffset <<= 2;
                    os_log_debug(OS_LOG_DEFAULT, "BL offset: 0x%x", blOffset);

                    uint64_t blAddr = (uint64_t)blInstPtr + blOffset;
                    os_log_debug(OS_LOG_DEFAULT, "BL target address: %p", (void *)blAddr);
                    
                    // cbz x0, loc_?????????
                    uint32_t cbzInst = *((uint32_t *)make_sym_readable((void *)blAddr));
                    if ((cbzInst & 0xff000000) != 0xb4000000)
                    {
                        os_log_error(OS_LOG_DEFAULT, "not a CBZ instruction: 0x%x", cbzInst);
                        continue;
                    }

                    os_log_debug(OS_LOG_DEFAULT, "found CBZ instruction: 0x%x, address %p", cbzInst, (void *)blAddr);
                    
                    orig_UIEventDispatcher__installEventRunLoopSources_ = (void (*)(id  _Nonnull __strong, SEL _Nonnull, CFRunLoopRef))make_sym_callable((void *)blAddr);
                }

                if (!orig_UIEventDispatcher__installEventRunLoopSources_)
                {
                    os_log_error(OS_LOG_DEFAULT, "failed to find -[UIEventDispatcher _installEventRunLoopSources:]");
                    break;
                }

                os_log_debug(OS_LOG_DEFAULT, "- [UIEventDispatcher _installEventRunLoopSources:]: %p", orig_UIEventDispatcher__installEventRunLoopSources_);
                
                CFRunLoopRef mainRunLoop = CFRunLoopGetMain();
                orig_UIEventDispatcher__installEventRunLoopSources_(dispatcher, @selector(_installEventRunLoopSources:), mainRunLoop);
            }

            // Get image base with dyld, the image is /System/Library/PrivateFrameworks/UIKitCore.framework/UIKitCore.
            uint64_t imageUIKitCore = 0;
            {
                uint32_t imageCount = _dyld_image_count();
                for (uint32_t i = 0; i < imageCount; i++)
                {
                    const char *imageName = _dyld_get_image_name(i);
                    if (imageName && !strcmp(imageName, "/System/Library/PrivateFrameworks/UIKitCore.framework/UIKitCore"))
                    {
                        imageUIKitCore = _dyld_get_image_vmaddr_slide(i);
                        break;
                    }
                }
            }
            os_log_debug(OS_LOG_DEFAULT, "UIKitCore: %p", (void *)imageUIKitCore);

            UIEventFetcher *fetcher = [[objc_getClass("UIEventFetcher") alloc] init];
            [dispatcher setValue:fetcher forKey:@"eventFetcher"];

            if ([fetcher respondsToSelector:@selector(setEventFetcherSink:)])
                [fetcher setEventFetcherSink:dispatcher];
            else
            {
                /* Tested on iOS 15.1.1 and below */
                [fetcher setValue:dispatcher forKey:@"eventFetcherSink"];

                /* Print NSThread names */
                DumpThreads();

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

            [self setValue:fetcher forKey:@"eventFetcher"];
        } while (NO);
    }
    return self;
}

@end


#pragma mark - HUDMainApplicationDelegate

@implementation HUDMainApplicationDelegate {
    HUDRootViewController *_rootViewController;
    SBSAccessibilityWindowHostingController *_windowHostingController;
}

- (instancetype)init
{
    if (self = [super init])
        os_log_debug(OS_LOG_DEFAULT, "- [HUDMainApplicationDelegate init]");
    return self;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary <UIApplicationLaunchOptionsKey, id> *)launchOptions
{
    os_log_debug(OS_LOG_DEFAULT, "- [HUDMainApplicationDelegate application:%{public}@ didFinishLaunchingWithOptions:%{public}@]", application, launchOptions);
    
    _rootViewController = [[HUDRootViewController alloc] init];

    self.window = [[HUDMainWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [self.window setRootViewController:_rootViewController];
    
    [self.window setWindowLevel:10000010.0];
    [self.window setHidden:NO];
    [self.window makeKeyAndVisible];

    _windowHostingController = [[objc_getClass("SBSAccessibilityWindowHostingController") alloc] init];
    unsigned int _contextId = [self.window _contextId];
    double windowLevel = [self.window windowLevel];
    [_windowHostingController registerWindowWithContextID:_contextId atLevel:windowLevel];

    return YES;
}

@end


#pragma mark - HUDMainWindow

@implementation HUDMainWindow

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super _initWithFrame:frame attached:NO])
    {
        self.backgroundColor = [UIColor clearColor];
        [self commonInit];
    }
    return self;
}

+ (BOOL)_isSystemWindow { return YES; }
- (BOOL)_isWindowServerHostingManaged { return NO; }
- (BOOL)_ignoresHitTest { return [HUDRootViewController passthroughMode]; }
// - (BOOL)keepContextInBackground { return YES; }
// - (BOOL)_usesWindowServerHitTesting { return NO; }
// - (BOOL)_isSecure { return YES; }
// - (BOOL)_wantsSceneAssociation { return NO; }
// - (BOOL)_alwaysGetsContexts { return YES; }
// - (BOOL)_shouldCreateContextAsSecure { return YES; }

@end


#pragma mark - HUDRootViewController

@implementation HUDRootViewController {
    NSMutableDictionary *_userDefaults;
    NSMutableArray <NSLayoutConstraint *> *_constraints;
    FBSOrientationObserver *_orientationObserver;
    UIVisualEffectView *_blurView;
    UIView *_contentView;
    UILabel *_speedLabel;
    NSTimer *_timer;
    UITapGestureRecognizer *_tapGestureRecognizer;
    BOOL _isFocused;
}

- (void)registerNotifications
{
    int token;
    notify_register_dispatch(NOTIFY_RELOAD_HUD, &token, dispatch_get_main_queue(), ^(int token) {
        [self reloadUserDefaults];
    });
}

#define USER_DEFAULTS_PATH @"/var/mobile/Library/Preferences/ch.xxtou.hudapp.plist"

- (void)loadUserDefaults:(BOOL)forceReload
{
    if (forceReload || !_userDefaults)
        _userDefaults = [[NSDictionary dictionaryWithContentsOfFile:USER_DEFAULTS_PATH] mutableCopy] ?: [NSMutableDictionary dictionary];
}

- (void)reloadUserDefaults
{
    [self loadUserDefaults:YES];

    NSInteger selectedMode = [self selectedMode];
    BOOL displayMode = [self displayMode];
    BOOL singleLineMode = [self singleLineMode];
    BOOL usesBitrate = [self usesBitrate];
    BOOL usesArrowPrefixes = [self usesArrowPrefixes];

    _speedLabel.textAlignment = (selectedMode == 1 ? NSTextAlignmentCenter : NSTextAlignmentLeft);
    
    DATAUNIT = usesBitrate;
    SHOW_UPLOAD_SPEED = !singleLineMode;
    SHOW_DOWNLOAD_SPEED_FIRST = (selectedMode == 1);
    SHOW_SECOND_SPEED_IN_NEW_LINE = (selectedMode == 0 || selectedMode == 2);
    SHOW_FPS = displayMode;
    
    UPLOAD_PREFIX = (usesArrowPrefixes ? "↑" : "▲");
    DOWNLOAD_PREFIX = (usesArrowPrefixes ? "↓" : "▼");
    
    prevInputBytes = 0;
    prevOutputBytes = 0;
    
    [displayLinkCounter reset];
    lastTicks = 0;
    
    attributedUploadPrefix = nil;
    attributedDownloadPrefix = nil;

    [self updateViewConstraints];
    [self onFocus:_contentView];
    [self performSelector:@selector(onBlur:) withObject:_contentView afterDelay:IDLE_INTERVAL];
}

+ (BOOL)passthroughMode
{
    return [[[NSDictionary dictionaryWithContentsOfFile:USER_DEFAULTS_PATH] objectForKey:@"passthroughMode"] boolValue];
}

- (NSInteger)selectedMode
{
    [self loadUserDefaults:NO];
    NSNumber *mode = [_userDefaults objectForKey:@"selectedMode"];
    return mode ? [mode integerValue] : 1;
}

- (BOOL)displayMode
{
    [self loadUserDefaults:NO];
    NSNumber *mode = [_userDefaults objectForKey:@"displayMode"];
    return mode ? [mode boolValue] : NO;
}

- (BOOL)singleLineMode
{
    [self loadUserDefaults:NO];
    NSNumber *mode = [_userDefaults objectForKey:@"singleLineMode"];
    return mode ? [mode boolValue] : NO;
}

- (BOOL)usesBitrate
{
    [self loadUserDefaults:NO];
    NSNumber *mode = [_userDefaults objectForKey:@"usesBitrate"];
    return mode ? [mode boolValue] : NO;
}

- (BOOL)usesArrowPrefixes
{
    [self loadUserDefaults:NO];
    NSNumber *mode = [_userDefaults objectForKey:@"usesArrowPrefixes"];
    return mode ? [mode boolValue] : NO;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _constraints = [NSMutableArray array];
        _orientationObserver = [[objc_getClass("FBSOrientationObserver") alloc] init];
        __weak HUDRootViewController *weakSelf = self;
        [_orientationObserver setHandler:^(FBSOrientationUpdate *orientationUpdate) {
            HUDRootViewController *strongSelf = weakSelf;
            dispatch_async(dispatch_get_main_queue(), ^{
                [strongSelf updateOrientation:(UIInterfaceOrientation)orientationUpdate.orientation animateWithDuration:orientationUpdate.duration];
            });
        }];
        [self registerNotifications];
    }
    return self;
}

- (void)dealloc
{
    [_orientationObserver invalidate];
}

- (void)updateSpeedLabel
{
    NSAttributedString *attributedText = formattedAttributedString(_isFocused);
    if (!attributedText)
        return;
    [_speedLabel setAttributedText:attributedText];
    [_speedLabel sizeToFit];
}

- (void)updateOrientation:(UIInterfaceOrientation)orientation animateWithDuration:(NSTimeInterval)duration
{
    if (orientation == UIInterfaceOrientationPortrait)
    {
        [UIView animateWithDuration:duration animations:^{
            self->_contentView.alpha = self->_isFocused ? 1.0 : 0.667;
        }];
    }
    else
    {
        [UIView animateWithDuration:duration animations:^{
            self->_contentView.alpha = 0.0;
        }];
    }
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
    _blurView.layer.cornerRadius = 4;
    _blurView.layer.masksToBounds = YES;
    _blurView.translatesAutoresizingMaskIntoConstraints = NO;
    [_contentView addSubview:_blurView];

    _speedLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 20)];
    _speedLabel.numberOfLines = 0;
    _speedLabel.textAlignment = NSTextAlignmentCenter;
    _speedLabel.textColor = [UIColor whiteColor];
    _speedLabel.font = [UIFont systemFontOfSize:FONT_SIZE];
    _speedLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [_blurView.contentView addSubview:_speedLabel];

    _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureRecognized:)];
    _tapGestureRecognizer.numberOfTapsRequired = 1;
    _tapGestureRecognizer.numberOfTouchesRequired = 1;
    [_contentView addGestureRecognizer:_tapGestureRecognizer];
    [_contentView setUserInteractionEnabled:YES];

    [self reloadUserDefaults];
}

- (void)resetLoopTimer
{
    [_timer invalidate];
    _timer = [NSTimer scheduledTimerWithTimeInterval:UPDATE_INTERVAL target:self selector:@selector(updateSpeedLabel) userInfo:nil repeats:YES];
}

- (void)viewSafeAreaInsetsDidChange
{
    [super viewSafeAreaInsetsDidChange];
    [self updateViewConstraints];
}

- (void)updateViewConstraints
{
    [NSLayoutConstraint deactivateConstraints:_constraints];
    [_constraints removeAllObjects];

    UILayoutGuide *layoutGuide = self.view.safeAreaLayoutGuide;
    
    [_constraints addObjectsFromArray:@[
        [_contentView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [_contentView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
    ]];
    
    if (layoutGuide.layoutFrame.origin.y > 1)
        [_constraints addObject:[_contentView.topAnchor constraintEqualToAnchor:layoutGuide.topAnchor constant:-10]];
    else
        [_constraints addObject:[_contentView.topAnchor constraintEqualToAnchor:layoutGuide.topAnchor constant:20]];
    
    [_constraints addObjectsFromArray:@[
        [_speedLabel.topAnchor constraintEqualToAnchor:_contentView.topAnchor],
        [_speedLabel.bottomAnchor constraintEqualToAnchor:_contentView.bottomAnchor],
    ]];
    
    NSInteger mode = [self selectedMode];
    if (mode == 1)
        [_constraints addObject:[_speedLabel.centerXAnchor constraintEqualToAnchor:_contentView.centerXAnchor]];
    else if (mode == 0)
        [_constraints addObject:[_speedLabel.leadingAnchor constraintEqualToAnchor:_contentView.leadingAnchor constant:10]];
    else
        [_constraints addObject:[_speedLabel.trailingAnchor constraintEqualToAnchor:_contentView.trailingAnchor constant:-10]];

    [_constraints addObjectsFromArray:@[
        [_blurView.topAnchor constraintEqualToAnchor:_speedLabel.topAnchor constant:-2],
        [_blurView.leadingAnchor constraintEqualToAnchor:_speedLabel.leadingAnchor constant:-4],
        [_blurView.trailingAnchor constraintEqualToAnchor:_speedLabel.trailingAnchor constant:4],
        [_blurView.bottomAnchor constraintEqualToAnchor:_speedLabel.bottomAnchor constant:2],
    ]];

    [NSLayoutConstraint activateConstraints:_constraints];
    [super updateViewConstraints];
}

- (void)onFocus:(UIView *)view
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(onBlur:) object:view];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(onFocus:) object:view];
    
    _isFocused = YES;
    [self updateSpeedLabel];
    [self resetLoopTimer];

    [UIView animateWithDuration:0.2 animations:^{
        view.alpha = 1.0;
    } completion:^(BOOL finished) {
        [self performSelector:@selector(onBlur:) withObject:view afterDelay:IDLE_INTERVAL];
    }];
}

- (void)onBlur:(UIView *)view
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(onBlur:) object:view];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(onFocus:) object:view];
    
    _isFocused = NO;
    [self updateSpeedLabel];
    [self resetLoopTimer];

    [UIView animateWithDuration:0.6 animations:^{
        view.alpha = 0.667;
    }];
}

- (void)tapGestureRecognized:(UITapGestureRecognizer *)sender
{
    os_log_info(OS_LOG_DEFAULT, "TAPPED");
    [self onFocus:sender.view];
}

@end