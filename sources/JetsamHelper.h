//
//  JetsamHelper.h
//  TrollSpeed
//
//  Created by Lessica on 2024/1/24.
//

#ifdef __cplusplus
extern "C" {
#endif
#import "libproc.h"
#import "kern_memorystatus.h"
#ifdef __cplusplus
}
#endif

static inline __unused
void BypassJetsamByProcess(pid_t me, BOOL critical) {
    int rc; memorystatus_priority_properties_t props = { JETSAM_PRIORITY_CRITICAL, 0 };
    rc = memorystatus_control(MEMORYSTATUS_CMD_SET_PRIORITY_PROPERTIES, me, 0, &props, sizeof(props));
    if (critical && rc < 0) { perror ("memorystatus_control"); exit(rc); }
    rc = memorystatus_control(MEMORYSTATUS_CMD_SET_JETSAM_HIGH_WATER_MARK, me, -1, NULL, 0);
    if (critical && rc < 0) { perror ("memorystatus_control"); exit(rc); }
    rc = memorystatus_control(MEMORYSTATUS_CMD_SET_JETSAM_TASK_LIMIT, me, 0, NULL, 0);
    if (critical && rc < 0) { perror ("memorystatus_control"); exit(rc); }
    rc = memorystatus_control(MEMORYSTATUS_CMD_SET_PROCESS_IS_MANAGED, me, 0, NULL, 0);
    if (critical && rc < 0) { perror ("memorystatus_control"); exit(rc); }
    rc = memorystatus_control(MEMORYSTATUS_CMD_SET_PROCESS_IS_FREEZABLE, me, 0, NULL, 0);
    if (critical && rc < 0) { perror ("memorystatus_control"); exit(rc); }
    rc = proc_track_dirty(me, 0);
    if (critical && rc != 0) { perror("proc_track_dirty"); exit(rc); }
    log_debug(OS_LOG_DEFAULT, "Oh, My Jetsam: %d", me);
}
