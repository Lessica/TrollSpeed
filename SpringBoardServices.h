#import <Foundation/Foundation.h>

FOUNDATION_EXPORT mach_port_t SBSSpringBoardServerPort();

FOUNDATION_EXPORT void SBFrontmostApplicationDisplayIdentifier(mach_port_t port, char *result);
NSString *SBSCopyFrontmostApplicationDisplayIdentifier();
FOUNDATION_EXPORT void SBGetScreenLockStatus(mach_port_t port, BOOL *lockStatus, BOOL *passcodeEnabled);
FOUNDATION_EXPORT void SBSUndimScreen();

FOUNDATION_EXPORT int SBSLaunchApplicationWithIdentifierAndURLAndLaunchOptions(NSString *bundleIdentifier, NSURL *url, NSDictionary *appOptions, NSDictionary *launchOptions, BOOL suspended);
FOUNDATION_EXPORT int SBSLaunchApplicationWithIdentifierAndLaunchOptions(NSString *bundleIdentifier, NSDictionary *appOptions, NSDictionary *launchOptions, BOOL suspended);
FOUNDATION_EXPORT bool SBSOpenSensitiveURLAndUnlock(CFURLRef url, char flags);

FOUNDATION_EXPORT NSString *const SBSApplicationLaunchOptionUnlockDeviceKey;