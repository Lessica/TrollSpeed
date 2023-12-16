#import <CoreFoundation/CoreFoundation.h>
#import <CoreGraphics/CoreGraphics.h>
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
#import <mach/vm_param.h>
#import <mach-o/dyld.h>
#import <objc/runtime.h>
#import <UIKit/UIKit.h>
#import "HUDPresetPosition.h"

#define SPAWN_AS_ROOT 0


extern "C" char **environ;

#if SPAWN_AS_ROOT
#define POSIX_SPAWN_PERSONA_FLAGS_OVERRIDE 1
extern "C" int posix_spawnattr_set_persona_np(const posix_spawnattr_t* __restrict, uid_t, uint32_t);
extern "C" int posix_spawnattr_set_persona_uid_np(const posix_spawnattr_t* __restrict, uid_t);
extern "C" int posix_spawnattr_set_persona_gid_np(const posix_spawnattr_t* __restrict, uid_t);
#endif

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

#if SPAWN_AS_ROOT
    posix_spawnattr_set_persona_np(&attr, 99, POSIX_SPAWN_PERSONA_FLAGS_OVERRIDE);
    posix_spawnattr_set_persona_uid_np(&attr, 0);
    posix_spawnattr_set_persona_gid_np(&attr, 0);
#endif

    pid_t task_pid;
    const char *args[] = { executablePath, "-check", NULL };
    posix_spawn(&task_pid, executablePath, NULL, &attr, (char **)args, environ);
    posix_spawnattr_destroy(&attr);

#if DEBUG
    os_log_debug(OS_LOG_DEFAULT, "spawned %{public}s -check pid = %{public}d", executablePath, task_pid);
#endif
    
    int status;
    do {
        if (waitpid(task_pid, &status, 0) != -1)
        {
#if DEBUG
            os_log_debug(OS_LOG_DEFAULT, "child status %d", WEXITSTATUS(status));
#endif
        }
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

#if SPAWN_AS_ROOT
    posix_spawnattr_set_persona_np(&attr, 99, POSIX_SPAWN_PERSONA_FLAGS_OVERRIDE);
    posix_spawnattr_set_persona_uid_np(&attr, 0);
    posix_spawnattr_set_persona_gid_np(&attr, 0);
#endif

    if (isEnabled)
    {
        posix_spawnattr_setpgroup(&attr, 0);
        posix_spawnattr_setflags(&attr, POSIX_SPAWN_SETPGROUP);

        pid_t task_pid;
        const char *args[] = { executablePath, "-hud", NULL };
        posix_spawn(&task_pid, executablePath, NULL, &attr, (char **)args, environ);
        posix_spawnattr_destroy(&attr);

#if DEBUG
        os_log_debug(OS_LOG_DEFAULT, "spawned %{public}s -hud pid = %{public}d", executablePath, task_pid);
#endif
    }
    else
    {
        [NSThread sleepForTimeInterval:0.25];

        pid_t task_pid;
        const char *args[] = { executablePath, "-exit", NULL };
        posix_spawn(&task_pid, executablePath, NULL, &attr, (char **)args, environ);
        posix_spawnattr_destroy(&attr);

#if DEBUG
        os_log_debug(OS_LOG_DEFAULT, "spawned %{public}s -exit pid = %{public}d", executablePath, task_pid);
#endif
        
        int status;
        do {
            if (waitpid(task_pid, &status, 0) != -1)
            {
#if DEBUG
                os_log_debug(OS_LOG_DEFAULT, "child status %d", WEXITSTATUS(status));
#endif
            }
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


#pragma mark -

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
- (void)resetLoopTimer;
- (void)stopLoopTimer;
@end

@interface HUDMainWindow : UIAutoRotatingWindow
@end


#pragma mark - Darwin Notification

#define NOTIFY_UI_LOCKCOMPLETE "com.apple.springboard.lockcomplete"
#define NOTIFY_UI_LOCKSTATE    "com.apple.springboard.lockstate"
#define NOTIFY_LS_APP_CHANGED  "com.apple.LaunchServices.ApplicationsChanged"

#import "LSApplicationProxy.h"
#import "LSApplicationWorkspace.h"

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

#import "SpringBoardServices.h"

static void SpringBoardLockStatusChanged
(CFNotificationCenterRef center,
 void *observer,
 CFStringRef name,
 const void *object,
 CFDictionaryRef userInfo)
{
    HUDRootViewController *rootViewController = (__bridge HUDRootViewController *)observer;
    NSString *lockState = (__bridge NSString *)name;
    if ([lockState isEqualToString:@NOTIFY_UI_LOCKCOMPLETE])
    {
        [rootViewController stopLoopTimer];
        [rootViewController.view setHidden:YES];
    }
    else if ([lockState isEqualToString:@NOTIFY_UI_LOCKSTATE])
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
#if DEBUG
            int rc = pthread_getname_np(pt, name, sizeof name);
            os_log_debug(OS_LOG_DEFAULT, "mach thread %u: getname returned %d: %{public}s", list[i], rc, name);
#endif
        }
        else
        {
#if DEBUG
            os_log_debug(OS_LOG_DEFAULT, "mach thread %u: no pthread found", list[i]);
#endif
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
#if DEBUG
        os_log_debug(OS_LOG_DEFAULT, "- [HUDMainApplication init]");
#endif
        notify_post(NOTIFY_LAUNCHED_HUD);
        
#ifdef NOTIFY_DISMISSAL_HUD
        {
            int outToken;
            notify_register_dispatch(NOTIFY_DISMISSAL_HUD, &outToken, dispatch_get_main_queue(), ^(int token) {
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
#if DEBUG
                os_log_error(OS_LOG_DEFAULT, "failed to get ivar _eventDispatcher");
#endif
                break;
            }

#if DEBUG
            os_log_debug(OS_LOG_DEFAULT, "got ivar _eventDispatcher: %p", dispatcher);
#endif

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
#if DEBUG
                    os_log_error(OS_LOG_DEFAULT, "failed to get - [UIApplication _run] method");
#endif
                    break;
                }

                uint32_t *runMethodPtr = (uint32_t *)make_sym_readable((void *)runMethodIMP);
#if DEBUG
                os_log_debug(OS_LOG_DEFAULT, "- [UIApplication _run]: %p", runMethodPtr);
#endif

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
#if DEBUG
                        os_log_error(OS_LOG_DEFAULT, "not a BL instruction: 0x%x, address %p", blInst, blInstPtr);
#endif
                        continue;
                    }

#if DEBUG
                    os_log_debug(OS_LOG_DEFAULT, "found BL instruction: 0x%x, address %p", blInst, blInstPtr);
#endif

                    int32_t blOffset = blInst & 0x03ffffff;
                    if (blOffset & 0x02000000)
                        blOffset |= 0xfc000000;
                    blOffset <<= 2;

#if DEBUG
                    os_log_debug(OS_LOG_DEFAULT, "BL offset: 0x%x", blOffset);
#endif

                    uint64_t blAddr = (uint64_t)blInstPtr + blOffset;

#if DEBUG
                    os_log_debug(OS_LOG_DEFAULT, "BL target address: %p", (void *)blAddr);
#endif
                    
                    // cbz x0, loc_?????????
                    uint32_t cbzInst = *((uint32_t *)make_sym_readable((void *)blAddr));
                    if ((cbzInst & 0xff000000) != 0xb4000000)
                    {
#if DEBUG
                        os_log_error(OS_LOG_DEFAULT, "not a CBZ instruction: 0x%x", cbzInst);
#endif
                        continue;
                    }

#if DEBUG
                    os_log_debug(OS_LOG_DEFAULT, "found CBZ instruction: 0x%x, address %p", cbzInst, (void *)blAddr);
#endif
                    
                    orig_UIEventDispatcher__installEventRunLoopSources_ = (void (*)(id  _Nonnull __strong, SEL _Nonnull, CFRunLoopRef))make_sym_callable((void *)blAddr);
                }

                if (!orig_UIEventDispatcher__installEventRunLoopSources_)
                {
#if DEBUG
                    os_log_error(OS_LOG_DEFAULT, "failed to find -[UIEventDispatcher _installEventRunLoopSources:]");
#endif
                    break;
                }

#if DEBUG
                os_log_debug(OS_LOG_DEFAULT, "- [UIEventDispatcher _installEventRunLoopSources:]: %p", orig_UIEventDispatcher__installEventRunLoopSources_);
#endif

                CFRunLoopRef mainRunLoop = CFRunLoopGetMain();
                orig_UIEventDispatcher__installEventRunLoopSources_(dispatcher, @selector(_installEventRunLoopSources:), mainRunLoop);
            }

#if DEBUG
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
#endif

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
    {
#if DEBUG
        os_log_debug(OS_LOG_DEFAULT, "- [HUDMainApplicationDelegate init]");
#endif
    }
    return self;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary <UIApplicationLaunchOptionsKey, id> *)launchOptions
{
#if DEBUG
    os_log_debug(OS_LOG_DEFAULT, "- [HUDMainApplicationDelegate application:%{public}@ didFinishLaunchingWithOptions:%{public}@]", application, launchOptions);
#endif

    _rootViewController = [[HUDRootViewController alloc] init];

    self.window = [[HUDMainWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [self.window setRootViewController:_rootViewController];
    
    [self.window setWindowLevel:10000010.0];
    [self.window setHidden:NO];
    [self.window makeKeyAndVisible];

    _windowHostingController = [[objc_getClass("SBSAccessibilityWindowHostingController") alloc] init];
    unsigned int _contextId = [self.window _contextId];
    double windowLevel = [self.window windowLevel];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    // [_windowHostingController registerWindowWithContextID:_contextId atLevel:windowLevel];
    NSMethodSignature *signature = [NSMethodSignature signatureWithObjCTypes:"v@:Id"];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    [invocation setTarget:_windowHostingController];
    [invocation setSelector:NSSelectorFromString(@"registerWindowWithContextID:atLevel:")];
    [invocation setArgument:&_contextId atIndex:2];
    [invocation setArgument:&windowLevel atIndex:3];
    [invocation invoke];
#pragma clang diagnostic pop

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
    UIImageView *_lockedView;
    NSTimer *_timer;
    UITapGestureRecognizer *_tapGestureRecognizer;
    UIPanGestureRecognizer *_panGestureRecognizer;
    UIImpactFeedbackGenerator *_impactFeedbackGenerator;
    UINotificationFeedbackGenerator *_notificationFeedbackGenerator;
    BOOL _isFocused;
    UIInterfaceOrientation _orientation;
    NSLayoutConstraint *_topConstraint;
}

- (void)registerNotifications
{
    int token;
    notify_register_dispatch(NOTIFY_RELOAD_HUD, &token, dispatch_get_main_queue(), ^(int token) {
        [self reloadUserDefaults];
    });

    CFNotificationCenterRef darwinCenter = CFNotificationCenterGetDarwinNotifyCenter();
    
    CFNotificationCenterAddObserver(
        darwinCenter,
        (__bridge const void *)self,
        LaunchServicesApplicationStateChanged,
        CFSTR(NOTIFY_LS_APP_CHANGED),
        NULL,
        CFNotificationSuspensionBehaviorDeliverImmediately
    );
    
    CFNotificationCenterAddObserver(
        darwinCenter,
        (__bridge const void *)self,
        SpringBoardLockStatusChanged,
        CFSTR(NOTIFY_UI_LOCKCOMPLETE),
        NULL,
        CFNotificationSuspensionBehaviorDeliverImmediately
    );
    
    CFNotificationCenterAddObserver(
        darwinCenter,
        (__bridge const void *)self,
        SpringBoardLockStatusChanged,
        CFSTR(NOTIFY_UI_LOCKSTATE),
        NULL,
        CFNotificationSuspensionBehaviorDeliverImmediately
    );
}

#define USER_DEFAULTS_PATH @"/var/mobile/Library/Preferences/ch.xxtou.hudapp.plist"

- (void)loadUserDefaults:(BOOL)forceReload
{
    if (forceReload || !_userDefaults)
        _userDefaults = [[NSDictionary dictionaryWithContentsOfFile:USER_DEFAULTS_PATH] mutableCopy] ?: [NSMutableDictionary dictionary];
}

- (void)saveUserDefaults
{
    BOOL wroteSucceed = [_userDefaults writeToFile:USER_DEFAULTS_PATH atomically:YES];
    if (wroteSucceed) {
        [[NSFileManager defaultManager] setAttributes:@{
            NSFileOwnerAccountID: @501,
            NSFileGroupOwnerAccountID: @501,
        } ofItemAtPath:USER_DEFAULTS_PATH error:nil];
        notify_post(NOTIFY_RELOAD_APP);
    }
}

- (void)reloadUserDefaults
{
    [self loadUserDefaults:YES];

    NSInteger selectedMode = [self selectedMode];
    BOOL isCentered = (selectedMode == HUDPresetPositionTopCenter || selectedMode == HUDPresetPositionTopCenterMost);
    BOOL isCenteredMost = (selectedMode == HUDPresetPositionTopCenterMost);
    
    BOOL singleLineMode = [self singleLineMode];
    BOOL usesBitrate = [self usesBitrate];
    BOOL usesArrowPrefixes = [self usesArrowPrefixes];
    BOOL usesLargeFont = [self usesLargeFont] && !isCenteredMost;

    _blurView.layer.maskedCorners = (isCenteredMost ? kCALayerMinXMaxYCorner | kCALayerMaxXMaxYCorner : kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner | kCALayerMinXMaxYCorner | kCALayerMaxXMaxYCorner);
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
    return [[[NSDictionary dictionaryWithContentsOfFile:USER_DEFAULTS_PATH] objectForKey:@"passthroughMode"] boolValue];
}

- (NSInteger)selectedMode
{
    [self loadUserDefaults:NO];
    NSNumber *mode = [_userDefaults objectForKey:@"selectedMode"];
    return mode ? [mode integerValue] : HUDPresetPositionTopCenter;
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

- (BOOL)usesLargeFont
{
    [self loadUserDefaults:NO];
    NSNumber *mode = [_userDefaults objectForKey:@"usesLargeFont"];
    return mode ? [mode boolValue] : NO;
}

- (BOOL)usesRotation
{
    [self loadUserDefaults:NO];
    NSNumber *mode = [_userDefaults objectForKey:@"usesRotation"];
    return mode ? [mode boolValue] : NO;
}

- (BOOL)keepInPlace
{
    [self loadUserDefaults:NO];
    NSNumber *mode = [_userDefaults objectForKey:@"keepInPlace"];
    return mode ? [mode boolValue] : NO;
}

- (CGFloat)currentPositionY
{
    [self loadUserDefaults:NO];
    NSNumber *positionY = [_userDefaults objectForKey:@"currentPositionY"];
    return positionY ? [positionY doubleValue] : CGFLOAT_MAX;
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
    return positionY ? [positionY doubleValue] : CGFLOAT_MAX;
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
#if DEBUG
    os_log_debug(OS_LOG_DEFAULT, "updateSpeedLabel");
#endif
    NSAttributedString *attributedText = formattedAttributedString(_isFocused);
    if (attributedText)
        [_speedLabel setAttributedText:attributedText];
    [_speedLabel sizeToFit];
}

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
        
        return;
    }

    if (orientation == _orientation)
        return;
    _orientation = orientation;

    CGRect bounds = orientationBounds(orientation, [UIScreen mainScreen].bounds);
    [self.view setNeedsUpdateConstraints];
    [self.view setHidden:YES];
    [self.view setBounds:bounds];
    
    [self resetGestureRecognizers];
    [self onBlur:_contentView duration:duration];
    
    [UIView animateWithDuration:duration animations:^{
        [self.view setTransform:CGAffineTransformMakeRotation(orientationAngle(orientation))];
    } completion:^(BOOL finished) {
        [self.view setHidden:NO];
    }];
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
    [_contentView addSubview:_blurView];

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

    NSInteger selectedMode = [self selectedMode];
    BOOL isCentered = (selectedMode == HUDPresetPositionTopCenter || selectedMode == HUDPresetPositionTopCenterMost);
    BOOL isCenteredMost = (selectedMode == HUDPresetPositionTopCenterMost);
    BOOL isPad = ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad);

    UILayoutGuide *layoutGuide = self.view.safeAreaLayoutGuide;
    if (_orientation == UIInterfaceOrientationLandscapeLeft || _orientation == UIInterfaceOrientationLandscapeRight)
    {
        CGFloat notchHeight = CGRectGetMinY(layoutGuide.layoutFrame);

        [_constraints addObjectsFromArray:@[
            [_contentView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:(notchHeight > 1) ? notchHeight - 16 : 4],
            [_contentView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:(notchHeight > 1) ? -20 : -4],
        ]];

        CGFloat minimumLandscapeConstant = (isPad ? 30 : 10);

        /* Fixed Constraints */
        [_constraints addObjectsFromArray:@[
            [_contentView.topAnchor constraintGreaterThanOrEqualToAnchor:self.view.topAnchor constant:minimumLandscapeConstant],
            [_contentView.bottomAnchor constraintLessThanOrEqualToAnchor:self.view.bottomAnchor constant:-minimumLandscapeConstant],
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
            if (CGRectGetMinY(layoutGuide.layoutFrame) > 1)
                minimumTopConstraintConstant = -10;
            else
                minimumTopConstraintConstant = (isPad ? 30 : 20);
            
            /* Fixed Constraints */
            [_constraints addObjectsFromArray:@[
                [_contentView.topAnchor constraintGreaterThanOrEqualToAnchor:layoutGuide.topAnchor constant:minimumTopConstraintConstant],
                [_contentView.bottomAnchor constraintLessThanOrEqualToAnchor:layoutGuide.bottomAnchor],
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
    
    if (isCentered)
        [_constraints addObject:[_speedLabel.centerXAnchor constraintEqualToAnchor:_contentView.centerXAnchor]];
    else if (selectedMode == HUDPresetPositionTopLeft)
        [_constraints addObject:[_speedLabel.leadingAnchor constraintEqualToAnchor:_contentView.leadingAnchor constant:10]];
    else  // HUDPresetPositionTopLeft
        [_constraints addObject:[_speedLabel.trailingAnchor constraintEqualToAnchor:_contentView.trailingAnchor constant:-10]];

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

    NSInteger selectedMode = [self selectedMode];
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
        {
            [self performSelector:@selector(onBlur:) withObject:view afterDelay:IDLE_INTERVAL];
        }
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
    
    if ([self selectedMode] == HUDPresetPositionTopCenter || [self keepInPlace])
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

    static CGFloat beginOffsetY = 0.0;
    static CGFloat beginConstantY = 0.0;
    if (sender.state == UIGestureRecognizerStatePossible || sender.state == UIGestureRecognizerStateBegan)
    {
        beginOffsetY = [sender locationInView:sender.view.superview].y;
        beginConstantY = _topConstraint.constant;
        [self onFocus:sender.view scaleFactor:0.2 duration:0.1 beginFromInitialState:NO blurWhenDone:NO];
    }
    else if (sender.state == UIGestureRecognizerStateChanged)
    {
        CGFloat currentOffsetY = [sender locationInView:sender.view.superview].y - beginOffsetY;
        [_topConstraint setConstant:beginConstantY + currentOffsetY];
    }
    else
    {
        if (sender.state == UIGestureRecognizerStateEnded)
        {
            if (_orientation == UIInterfaceOrientationLandscapeLeft || _orientation == UIInterfaceOrientationLandscapeRight)
                [self setCurrentLandscapePositionY:_topConstraint.constant];
            else
                [self setCurrentPositionY:_topConstraint.constant];
        }
        
        [self onFocus:sender.view scaleFactor:0.1 duration:0.1 beginFromInitialState:NO blurWhenDone:NO];
        [self reloadUserDefaults];
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