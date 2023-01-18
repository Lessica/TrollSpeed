#import <cstddef>
#import <cstdlib>
#import <dlfcn.h>
#import <spawn.h>
#import <unistd.h>
#import <sys/sysctl.h>
#import <mach-o/dyld.h>
#import <objc/runtime.h>


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
- (void)_run;
@end

@interface FBSUIApplicationWorkspace : NSObject
- (instancetype)initWithSerialQueue:(id)arg1;
- (void)setDelegate:(id)arg1;
@end

@interface MyFBSUIApplicationWorkspaceDelegate : NSObject
@end

@implementation MyFBSUIApplicationWorkspaceDelegate
- (void)workspaceShouldExit:(FBSUIApplicationWorkspace *)arg1 {}
- (void)workspace:(FBSUIApplicationWorkspace *)arg1 didLaunchWithCompletion:(void (^)(id))arg2 {}
@end


#pragma mark -

static __used void _HUDEventCallback(void *target, void *refcon, IOHIDServiceRef service, IOHIDEventRef event)
{
    static UIApplication *app = [UIApplication sharedApplication];
    [app _enqueueHIDEvent:event];

    /* Not Implemented: Event Fetcher & Dispatcher */
    os_log_debug(OS_LOG_DEFAULT, "_HUDEventCallback => %{public}@", event);
}


#pragma mark -

int main(int argc, char *argv[])
{
    @autoreleasepool
    {
        os_log_debug(OS_LOG_DEFAULT, "Launched with bundle identifier %{public}@, uid = %{public}d", NSBundle.mainBundle.bundleIdentifier, getuid());

        if (argc < 2 || strcmp(argv[1], "-hud") != 0)
            return UIApplicationMain(argc, argv, @"MainApplication", @"MainApplicationDelegate");
        
        [UIScreen initialize];
        CFRunLoopGetCurrent();

        GSInitialize();
        BKSDisplayServicesStart();
        UIApplicationInitialize();

        [NSRunLoop currentRunLoop];
        BKSHIDEventRegisterEventCallback(_HUDEventCallback);

        GSEventInitialize(0);
        GSEventPushRunLoopMode(kCFRunLoopDefaultMode);

        UIApplicationInstantiateSingleton(objc_getClass("HUDMainApplication"));
        static id<UIApplicationDelegate> appDelegate = [[objc_getClass("HUDMainApplicationDelegate") alloc] init];
        [UIApplication.sharedApplication setDelegate:appDelegate];
        [UIApplication.sharedApplication _accessibilityInit];
        [UIApplication.sharedApplication __completeAndRunAsPlugin];

        static FBSUIApplicationWorkspace *workspace = 
            [[objc_getClass("FBSUIApplicationWorkspace") alloc] initWithSerialQueue:[UIApplication.sharedApplication _systemAnimationFenceExemptQueue]];
        [workspace setDelegate:[MyFBSUIApplicationWorkspaceDelegate new]];

        CFRunLoopRun();
        return EXIT_SUCCESS;
    }
}