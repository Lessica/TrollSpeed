#import <Foundation/Foundation.h>

OBJC_EXTERN BOOL IsHUDEnabled(void);
OBJC_EXTERN void SetHUDEnabled(BOOL isEnabled);

#if DEBUG && SPAWN_AS_ROOT
OBJC_EXTERN void SimulateMemoryPressure(void);
#endif
