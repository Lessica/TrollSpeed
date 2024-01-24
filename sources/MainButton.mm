//
//  MainButton.mm
//  TrollSpeed
//
//  Created by Lessica on 2024/1/24.
//

#import "MainButton.h"

@implementation MainButton

- (void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
    if (highlighted)
    {
        [UIView animateWithDuration:0.27 delay:0.0 usingSpringWithDamping:1.0 initialSpringVelocity:1.0 options:(UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionBeginFromCurrentState) animations:^{
            self.transform = CGAffineTransformMakeScale(0.92, 0.92);
        } completion:nil];
    }
    else
    {
        [UIView animateWithDuration:0.27 delay:0.0 usingSpringWithDamping:1.0 initialSpringVelocity:1.0 options:(UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionBeginFromCurrentState) animations:^{
            self.transform = CGAffineTransformIdentity;
        } completion:nil];
    }
}

@end
