#import <dlfcn.h>
#import <string.h>
#import "TSEventFetcher.h"
#import "CoreFoundation/CFRunLoop.h"
#import "UIApplication+Private.h"
#import "UIEvent+Private.h"
#import "UITouch-KIFAdditions.h"


static NSArray *_safeTouchAry = nil;
static NSMutableArray *_touchAry = nil;
static NSMutableArray *_livingTouchAry = nil;
static CFRunLoopSourceRef _source = NULL;

static UITouch *toRemove = nil;
static UITouch *toStationarify = nil;

static void __TSEventFetcherCallback(void *info)
{
  static UIApplication *app = [UIApplication sharedApplication];
  UIEvent *event = [app _touchesEvent];
  
  // to retain objects from being released
  [event _clearTouches];

  NSArray *myAry = _safeTouchAry;
  for (UITouch *aTouch in myAry)
  {
    switch (aTouch.phase) {
    case UITouchPhaseEnded:
    case UITouchPhaseCancelled:
      toRemove = aTouch;
      break;
    case UITouchPhaseBegan:
      toStationarify = aTouch;
      break;
    default:
      break;
    }

    [event _addTouch:aTouch forDelayedDelivery:NO];
  }

  [app sendEvent:event];
}

@implementation TSEventFetcher

+ (void)load
{
  _livingTouchAry = [[NSMutableArray alloc] init];
  _touchAry = [[NSMutableArray alloc] init];
  
  for (NSInteger i = 0; i < 100; i++)
  {
    UITouch *touch = [[UITouch alloc] initTouch];
    [touch setPhaseAndUpdateTimestamp:UITouchPhaseEnded];
    [_touchAry addObject:touch];
  }

  CFRunLoopSourceContext context;
  memset(&context, 0, sizeof(CFRunLoopSourceContext));
  context.perform = __TSEventFetcherCallback;
  
  // content of context is copied
  _source = CFRunLoopSourceCreate(kCFAllocatorDefault, -2, &context);
  CFRunLoopRef loop = CFRunLoopGetMain();
  CFRunLoopAddSource(loop, _source, kCFRunLoopCommonModes);
}

+ (NSInteger)receiveAXEventID:(NSInteger)eventId
           atGlobalCoordinate:(CGPoint)coordinate
               withTouchPhase:(UITouchPhase)phase
                     inWindow:(UIWindow *)window
                       onView:(UIView *)view
{
  BOOL deleted = NO;
  UITouch *touch = nil;
  BOOL needsCopy = NO;

  if (toRemove != nil)
  {
    touch = toRemove;
    toRemove = nil;
    [_livingTouchAry removeObjectIdenticalTo:touch];
    deleted = YES;
    needsCopy = YES;
  }

  if (toStationarify != nil)
  {
    // in case this is changed during the operations
    touch = toStationarify;
    toStationarify = nil;
    if (touch.phase == UITouchPhaseBegan)
      [touch setPhaseAndUpdateTimestamp:UITouchPhaseStationary];
  }

  eventId -= 1;

  // ideally should be phase began when this hit
  // but if by any means other phases come... well lets be forgiving
  touch = _touchAry[eventId];
  BOOL oldState = [_livingTouchAry containsObject:touch];
  BOOL newState = !oldState;
  if (newState)
  {
    if (phase == UITouchPhaseEnded || phase == UITouchPhaseCancelled)
      return deleted;
    touch = [[UITouch alloc] initAtPoint:coordinate inWindow:window onView:view];
    [_livingTouchAry addObject:touch];
    [_touchAry setObject:touch atIndexedSubscript:eventId];
    needsCopy = YES;
  }
  else
  {
    if (touch.phase == UITouchPhaseBegan && phase == UITouchPhaseMoved)
      return deleted;
    [touch setLocationInWindow:coordinate];
  }

  [touch setPhaseAndUpdateTimestamp:phase];
  
  if (needsCopy)
  {
    CFTypeRef delayRelease = CFBridgingRetain(_safeTouchAry);
    _safeTouchAry = [[NSArray alloc] initWithArray:_livingTouchAry copyItems:NO];
    CFBridgingRelease(delayRelease);
  }

  CFRunLoopSourceSignal(_source);
  return deleted;
}

@end