//
//  TSEventFetcher.h
//  TrollSpeed
//
//  Created by Lessica on 2024/1/24.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TSEventFetcher : NSObject
+ (NSInteger)receiveAXEventID:(NSInteger)pointId
           atGlobalCoordinate:(CGPoint)point
               withTouchPhase:(UITouchPhase)phase
                     inWindow:(UIWindow *)window
                       onView:(UIView *)view;
@end

NS_ASSUME_NONNULL_END
