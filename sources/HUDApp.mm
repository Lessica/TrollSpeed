#import <notify.h>
#import <mach-o/dyld.h>
#import <objc/runtime.h>

#if !NO_TROLL
#import "IOKit+SPI.h"
#import "HUDHelper.h"
#import "TSEventFetcher.h"
#import "BackboardServices.h"
#import "AXEventRepresentation.h"
#import "UIApplication+Private.h"

#define PID_PATH "/var/mobile/Library/Caches/ch.xxtou.hudapp.pid"
#endif  // !NO_TROLL

#if !NO_TROLL
static __used
void _HUDEventCallback(void *target, void *refcon, IOHIDServiceRef service, IOHIDEventRef event)
{
    static UIApplication *app = [UIApplication sharedApplication];
#if DEBUG
    os_log_debug(OS_LOG_DEFAULT, "_HUDEventCallback => %{public}@", event);
#endif
    
    // iOS 15.1+ has a new API for handling HID events.
    if (@available(iOS 15.1, *)) {}
    else {
        [app _enqueueHIDEvent:event];
    }

    BOOL shouldUseAXEvent = YES;  // Always use AX events now...

    BOOL isExactly15 = NO;
    static NSOperatingSystemVersion version = [[NSProcessInfo processInfo] operatingSystemVersion];
    if (version.majorVersion == 15 && version.minorVersion == 0 && version.patchVersion == 0) {
        isExactly15 = YES;
    }

    if (@available(iOS 15.0, *)) {
        shouldUseAXEvent = !isExactly15;
    } else {
        shouldUseAXEvent = NO;
    }

    if (shouldUseAXEvent)
    {
        static Class AXEventRepresentationCls = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            [[NSBundle bundleWithPath:@"/System/Library/PrivateFrameworks/AccessibilityUtilities.framework"] load];
            AXEventRepresentationCls = objc_getClass("AXEventRepresentation");
        });

        AXEventRepresentation *rep = [AXEventRepresentationCls representationWithHIDEvent:event hidStreamIdentifier:@"UIApplicationEvents"];
#if DEBUG
        os_log_debug(OS_LOG_DEFAULT, "_HUDEventCallback => %{public}@", rep.handInfo);
#endif

        /* I don't like this. It's too hacky, but it works. */
        {
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                static UIWindow *keyWindow = nil;
                static dispatch_once_t onceToken;
                dispatch_once(&onceToken, ^{
                    keyWindow = [[app windows] firstObject];
                });

                UIView *keyView = [keyWindow hitTest:[rep location] withEvent:nil];

                UITouchPhase phase = UITouchPhaseEnded;
                if ([rep isTouchDown])
                    phase = UITouchPhaseBegan;
                else if ([rep isMove])
                    phase = UITouchPhaseMoved;
                else if ([rep isCancel])
                    phase = UITouchPhaseCancelled;
                else if ([rep isLift] || [rep isInRange] || [rep isInRangeLift])
                    phase = UITouchPhaseEnded;

                NSInteger pointerId = [[[[rep handInfo] paths] firstObject] pathIdentity];
                if (pointerId > 0)
                    [TSEventFetcher receiveAXEventID:MIN(MAX(pointerId, 1), 98) atGlobalCoordinate:[rep location] withTouchPhase:phase inWindow:keyWindow onView:keyView];
            });
        }
    }
}
#endif  // !NO_TROLL

int main(int argc, char *argv[])
{
    @autoreleasepool
    {
#if DEBUG
        os_log_debug(OS_LOG_DEFAULT, "launched argc %{public}d, argv[1] %{public}s", argc, argc > 1 ? argv[1] : "NULL");
#endif

#if NO_TROLL
        return UIApplicationMain(argc, argv, @"MainApplication", @"MainApplicationDelegate");
#else
        if (argc <= 1) {
            return UIApplicationMain(argc, argv, @"MainApplication", @"MainApplicationDelegate");
        }
        
        if (strcmp(argv[1], "-hud") == 0)
        {
            pid_t pid = getpid();
            pid_t pgid = getgid();
            (void)pgid;
#if DEBUG
            os_log_debug(OS_LOG_DEFAULT, "HUD pid %d, pgid %d", pid, pgid);
#endif
            NSString *pidString = [NSString stringWithFormat:@"%d", pid];
            [pidString writeToFile:ROOT_PATH_NS(PID_PATH)
                        atomically:YES
                          encoding:NSUTF8StringEncoding
                             error:nil];
            
            [UIScreen initialize];
            CFRunLoopGetCurrent();

            GSInitialize();
            BKSDisplayServicesStart();
            UIApplicationInitialize();

            UIApplicationInstantiateSingleton(objc_getClass("HUDMainApplication"));
            static id<UIApplicationDelegate> appDelegate = [[objc_getClass("HUDMainApplicationDelegate") alloc] init];
            [UIApplication.sharedApplication setDelegate:appDelegate];
            [UIApplication.sharedApplication _accessibilityInit];

            [NSRunLoop currentRunLoop];
            BKSHIDEventRegisterEventCallback(_HUDEventCallback);

            if (@available(iOS 15.0, *)) {
                GSEventInitialize(0);
                GSEventPushRunLoopMode(kCFRunLoopDefaultMode);
            }
            
            [UIApplication.sharedApplication __completeAndRunAsPlugin];

            static int _springboardBootToken;
            notify_register_dispatch("SBSpringBoardDidLaunchNotification", &_springboardBootToken, dispatch_get_main_queue(), ^(int token) {
                notify_cancel(token);

#ifdef NOTIFY_DISMISSAL_HUD
                notify_post(NOTIFY_DISMISSAL_HUD);
#endif

                // Re-enable HUD after SpringBoard is launched.
                SetHUDEnabled(YES);

                // Exit the current instance of HUD.
                kill(pid, SIGKILL);
            });

            CFRunLoopRun();
            return EXIT_SUCCESS;
        }
        else if (strcmp(argv[1], "-exit") == 0)
        {
            NSString *pidString = [NSString stringWithContentsOfFile:ROOT_PATH_NS(PID_PATH)
                                                            encoding:NSUTF8StringEncoding
                                                               error:nil];
            
            if (pidString)
            {
                pid_t pid = (pid_t)[pidString intValue];
                kill(pid, SIGKILL);
                unlink([ROOT_PATH_NS(PID_PATH) UTF8String]);
            }

            return EXIT_SUCCESS;
        }
        else if (strcmp(argv[1], "-check") == 0)
        {
            NSString *pidString = [NSString stringWithContentsOfFile:ROOT_PATH_NS(PID_PATH)
                                                            encoding:NSUTF8StringEncoding
                                                               error:nil];
            
            if (pidString)
            {
                pid_t pid = (pid_t)[pidString intValue];
                int killed = kill(pid, 0);
                return (killed == 0 ? EXIT_FAILURE : EXIT_SUCCESS);
            }
            else return EXIT_SUCCESS;  // No PID file, so HUD is not running
        }
#endif  // NO_TROLL
    }
}
