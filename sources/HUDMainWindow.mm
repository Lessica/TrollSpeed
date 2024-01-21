#import "HUDMainWindow.h"
#import "HUDRootViewController.h"

@implementation HUDMainWindow

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super _initWithFrame:frame attached:NO])
    {
        self.backgroundColor = [UIColor clearColor];
        [self commonInit];
    }
    return self;
}

+ (BOOL)_isSystemWindow { return YES; }
- (BOOL)_isWindowServerHostingManaged { return NO; }
- (BOOL)_ignoresHitTest { return [HUDRootViewController passthroughMode]; }
// - (BOOL)keepContextInBackground { return YES; }
// - (BOOL)_usesWindowServerHitTesting { return NO; }
- (BOOL)_isSecure { return YES; }
// - (BOOL)_wantsSceneAssociation { return NO; }
// - (BOOL)_alwaysGetsContexts { return YES; }
- (BOOL)_shouldCreateContextAsSecure { return YES; }

@end
