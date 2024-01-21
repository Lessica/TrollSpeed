#import <UIKit/UIKit.h>
#import "IOKit+SPI.h"

@class UIEventDispatcher;

@interface UIEventFetcher : NSObject
- (void)_receiveHIDEvent:(IOHIDEventRef)arg1;
- (void)setEventFetcherSink:(UIEventDispatcher *)arg1;
@end
