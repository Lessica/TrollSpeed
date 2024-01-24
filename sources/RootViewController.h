//
//  RootViewController.h
//  TrollSpeed
//
//  Created by Lessica on 2024/1/24.
//

#import <UIKit/UIKit.h>
#import "TrollSpeed-Swift.h"

NS_ASSUME_NONNULL_BEGIN

@interface RootViewController : UIViewController <TSSettingsControllerDelegate>
@property (nonatomic, strong) UIView *backgroundView;
+ (void)setShouldToggleHUDAfterLaunch:(BOOL)flag;
- (void)reloadMainButtonState;
@end

NS_ASSUME_NONNULL_END
