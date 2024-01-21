#if NO_TROLL
#error "This target only compiles for real devices."
#endif

#import <notify.h>
#import <pthread.h>
#import <mach/mach.h>
#import <mach-o/dyld.h>
#import <objc/runtime.h>

#import "pac_helper.h"
#import "UIEventFetcher.h"
#import "UIEventDispatcher.h"
#import "HUDMainApplication.h"
#import "UIApplication+Private.h"

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

@implementation HUDMainApplication

- (instancetype)init
{
    if (self = [super init])
    {
#if DEBUG
        os_log_debug(OS_LOG_DEFAULT, "- [HUDMainApplication init]");
#endif
        
#ifdef NOTIFY_DISMISSAL_HUD
        {
            int outToken;
            notify_register_dispatch(NOTIFY_DISMISSAL_HUD, &outToken, dispatch_get_main_queue(), ^(int token) {
                notify_cancel(token);
                
                // Fade out the HUD window
                [UIView animateWithDuration:FADE_OUT_DURATION animations:^{
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

            if ([fetcher respondsToSelector:@selector(setEventFetcherSink:)]) {
                [fetcher setEventFetcherSink:dispatcher];
            }
            else
            {
                /* Tested on iOS 15.1.1 and below */
                [fetcher setValue:dispatcher forKey:@"eventFetcherSink"];

                /* Print NSThread names */
                DumpThreads();
            }

            [self setValue:fetcher forKey:@"eventFetcher"];
        } while (NO);
    }
    return self;
}

@end
