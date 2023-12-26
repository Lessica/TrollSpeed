#import <cstddef>
#import <cstring>
#import <cstdlib>
#import <dlfcn.h>
#import <spawn.h>
#import <notify.h>
#import <unistd.h>
#import <os/log.h>
#import <rootless.h>
#import <objc/objc.h>
#import <sys/param.h>
#import <sys/sysctl.h>
#import <mach-o/dyld.h>
#import <objc/runtime.h>
#import <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


#pragma mark -

typedef struct __IOHIDEvent *IOHIDEventRef;
typedef struct __IOHIDNotification *IOHIDNotificationRef;
typedef struct __IOHIDService *IOHIDServiceRef;
typedef struct __GSEvent *GSEventRef;

#if __cplusplus
extern "C" {
#endif
void *BKSHIDEventRegisterEventCallback(void (*)(void *, void *, IOHIDServiceRef, IOHIDEventRef));
void UIApplicationInstantiateSingleton(id aclass);
void UIApplicationInitialize();
void BKSDisplayServicesStart();
void GSInitialize();
void GSEventInitialize(Boolean registerPurple);
void GSEventPopRunLoopMode(CFStringRef mode);
void GSEventPushRunLoopMode(CFStringRef mode);
void GSEventRegisterEventCallBack(void (*)(GSEventRef));
#if __cplusplus
}
#endif


#pragma mark -

@interface UIApplication (Private)
- (id)_systemAnimationFenceExemptQueue;
- (void)_accessibilityInit;
- (void)_enqueueHIDEvent:(IOHIDEventRef)event;
- (void)__completeAndRunAsPlugin;
@end

@interface UIEventFetcher : NSObject
- (void)_receiveHIDEvent:(IOHIDEventRef)arg1;
@end

@interface AXEventPathInfoRepresentation : NSObject
@property (assign, nonatomic) unsigned char pathIdentity;
@end

@interface AXEventHandInfoRepresentation : NSObject
- (NSArray <AXEventPathInfoRepresentation *> *)paths;
@end

@interface AXEventRepresentation : NSObject
@property (nonatomic, readonly) BOOL isTouchDown; 
@property (nonatomic, readonly) BOOL isMove; 
@property (nonatomic, readonly) BOOL isChordChange; 
@property (nonatomic, readonly) BOOL isLift; 
@property (nonatomic, readonly) BOOL isInRange; 
@property (nonatomic, readonly) BOOL isInRangeLift; 
@property (nonatomic, readonly) BOOL isCancel; 
+ (instancetype)representationWithHIDEvent:(IOHIDEventRef)event hidStreamIdentifier:(NSString *)identifier;
- (AXEventHandInfoRepresentation *)handInfo;
- (CGPoint)location;
@end


#pragma mark -

#import "TSEventFetcher.h"

static __used void _HUDEventCallback(void *target, void *refcon, IOHIDServiceRef service, IOHIDEventRef event)
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


#pragma mark -

#define PID_PATH "/var/mobile/Library/Caches/ch.xxtou.hudapp.pid"

#ifdef __cplusplus
extern "C" {
#endif
#import "libproc.h"
#import "kern_memorystatus.h"
#ifdef __cplusplus
}
#endif

__unused
static inline
void BypassJetsamByProcess(pid_t me, BOOL critical) {
    int rc; memorystatus_priority_properties_t props = { JETSAM_PRIORITY_CRITICAL, 0 };
    rc = memorystatus_control(MEMORYSTATUS_CMD_SET_PRIORITY_PROPERTIES, me, 0, &props, sizeof(props));
    if (critical && rc < 0) { perror ("memorystatus_control"); exit(rc); }
    rc = memorystatus_control(MEMORYSTATUS_CMD_SET_JETSAM_HIGH_WATER_MARK, me, -1, NULL, 0);
    if (critical && rc < 0) { perror ("memorystatus_control"); exit(rc); }
    rc = memorystatus_control(MEMORYSTATUS_CMD_SET_JETSAM_TASK_LIMIT, me, 0, NULL, 0);
    if (critical && rc < 0) { perror ("memorystatus_control"); exit(rc); }
    rc = memorystatus_control(MEMORYSTATUS_CMD_SET_PROCESS_IS_MANAGED, me, 0, NULL, 0);
    if (critical && rc < 0) { perror ("memorystatus_control"); exit(rc); }
    rc = memorystatus_control(MEMORYSTATUS_CMD_SET_PROCESS_IS_FREEZABLE, me, 0, NULL, 0);
    if (critical && rc < 0) { perror ("memorystatus_control"); exit(rc); }
    rc = proc_track_dirty(me, 0);
    if (critical && rc != 0) { perror("proc_track_dirty"); exit(rc); }
    os_log_debug(OS_LOG_DEFAULT, "Oh, My Jetsam: %d", me);
}


#pragma mark -

OBJC_EXTERN void SetHUDEnabled(BOOL isEnabled);

int main(int argc, char *argv[])
{
    @autoreleasepool
    {
#if DEBUG
        os_log_debug(OS_LOG_DEFAULT, "launched argc %{public}d, argv[1] %{public}s", argc, argc > 1 ? argv[1] : "NULL");
#endif

        if (argc <= 1)
            return UIApplicationMain(argc, argv, @"MainApplication", @"MainApplicationDelegate");
        
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
            notify_register_dispatch("SBSpringBoardDidLaunchNotification", &_springboardBootToken, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0l), ^(int token) {
                notify_cancel(token);

                // Re-enable HUD after SpringBoard is launched.
                SetHUDEnabled(YES);

                // Exit the current instance of HUD.
#ifdef NOTIFY_DISMISSAL_HUD
                notify_post(NOTIFY_DISMISSAL_HUD);
#endif
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
    }
}