#include <sys/syslimits.h>
#include <unistd.h>

#ifdef XINA_SUPPORT // Only define this for rootful compilations that need support for xina
#define ROOT_PATH(cPath) !access("/var/LIY", F_OK) ? "/var/jb" cPath : cPath
#define ROOT_PATH_NS(path) !access("/var/LIY", F_OK) ? @"/var/jb" path : path
#define ROOT_PATH_NS_VAR !access("/var/LIY", F_OK) ? [@"/var/jb" stringByAppendingPathComponent:path] : path
#define ROOT_PATH_VAR(path) !access("/var/LIY", F_OK) ? ({ \
	char outPath[PATH_MAX]; \
	strlcpy(outPath, "/var/jb", PATH_MAX); \
	strlcat(outPath, path, PATH_MAX); \
	outPath; \
}) : path
#else
#define ROOT_PATH(cPath) THEOS_PACKAGE_INSTALL_PREFIX cPath
#define ROOT_PATH_NS(path) @THEOS_PACKAGE_INSTALL_PREFIX path
#define ROOT_PATH_NS_VAR(path) [@THEOS_PACKAGE_INSTALL_PREFIX stringByAppendingPathComponent:path]
#define ROOT_PATH_VAR(path) sizeof(THEOS_PACKAGE_INSTALL_PREFIX) > 1 ? ({ \
    char outPath[PATH_MAX]; \
    strlcpy(outPath, THEOS_PACKAGE_INSTALL_PREFIX, PATH_MAX); \
	strlcat(outPath, path, PATH_MAX); \
    outPath; \
}) : path
#endif
