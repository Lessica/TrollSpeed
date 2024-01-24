//
//  MainApplication.h
//  TrollSpeed
//
//  Created by Lessica on 2024/1/24.
//

#import <UIKit/UIKit.h>

static NSString * const kToggleHUDAfterLaunchNotificationName = @"ch.xxtou.hudapp.notification.toggle-hud";
static NSString * const kToggleHUDAfterLaunchNotificationActionKey = @"action";
static NSString * const kToggleHUDAfterLaunchNotificationActionToggleOn = @"toggle-on";
static NSString * const kToggleHUDAfterLaunchNotificationActionToggleOff = @"toggle-off";

NS_ASSUME_NONNULL_BEGIN

@interface MainApplication : UIApplication
@end

NS_ASSUME_NONNULL_END
