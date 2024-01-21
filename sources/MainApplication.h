#import <UIKit/UIKit.h>

static NSString * const kToggleHUDAfterLaunchNotificationName = @"ch.xxtou.hudapp.notification.toggle-hud";
static NSString * const kToggleHUDAfterLaunchNotificationActionKey = @"action";
static NSString * const kToggleHUDAfterLaunchNotificationActionToggleOn = @"toggle-on";
static NSString * const kToggleHUDAfterLaunchNotificationActionToggleOff = @"toggle-off";

@interface MainApplication : UIApplication
@end
