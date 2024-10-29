#include <stdint.h>
#include <stddef.h>
#include <dispatch/dispatch.h>
#include <dlfcn.h>
#include <sys/param.h>
#include <stdlib.h>
#include <string.h>

#include <libroot.h>

#if THEOS_PACKAGE_SCHEME_ROOTHIDE
#include <roothide.h>
#endif

static const char *(*dyn_get_root_prefix)(void) = NULL;
static const char *(*dyn_get_jbroot_prefix)(void) = NULL;
static const char *(*dyn_get_boot_uuid)(void) = NULL;
static char *(*dyn_jbrootpath)(const char *path, char *resolvedPath) = NULL;
static char *(*dyn_rootfspath)(const char *path, char *resolvedPath) = NULL;

#if TARGET_OS_SIMULATOR

static const char *libroot_get_root_prefix_fallback(void)
{
	return IPHONE_SIMULATOR_ROOT;
}

static const char *libroot_get_jbroot_prefix_fallback(void)
{
	return IPHONE_SIMULATOR_ROOT;
}

#else

#if THEOS_PACKAGE_SCHEME_ROOTHIDE

static const char *libroot_get_root_prefix_fallback(void)
{
	char *resolved = (char *)rootfs("/");
	int len = strlen(resolved);
	if (len > 1 && resolved[len - 1] == '/') {
		resolved[len - 1] = '\0';
	}
	return resolved;
}

static const char *libroot_get_jbroot_prefix_fallback(void)
{
	char *resolved = (char *)jbroot("/");
	int len = strlen(resolved);
	if (len > 1 && resolved[len - 1] == '/') {
		resolved[len - 1] = '\0';
	}
	return resolved;
}

#else

#if IPHONEOS_ARM64

static const char *libroot_get_root_prefix_fallback(void)
{
	return "";
}

static const char *libroot_get_jbroot_prefix_fallback(void)
{
	return "/var/jb";
}

#else

static const char *libroot_get_root_prefix_fallback(void)
{
	return "";
}

static const char *libroot_get_jbroot_prefix_fallback(void)
{
	if (access("/var/LIY", F_OK) == 0) {
		// Legacy support for XinaA15 1.x (For those two people still using it)
		// Technically this should be deprecated, but with the libroot solution it's not the hardest thing in the world to maintain
		// So I decided to leave it in
		return "/var/jb";
	}
	else {
		return "";
	}
}

#endif
#endif
#endif

static const char *libroot_get_boot_uuid_fallback(void)
{
	return "00000000-0000-0000-0000-000000000000";
}

static char *libroot_rootfspath_fallback(const char *path, char *resolvedPath)
{
	if (!path) return NULL;
	if (!resolvedPath) resolvedPath = malloc(PATH_MAX);

	const char *prefix = libroot_dyn_get_root_prefix();
	const char *jbRootPrefix = libroot_dyn_get_jbroot_prefix();
	size_t jbRootPrefixLen = strlen(jbRootPrefix);

	if (path[0] == '/') {
		// This function has two different purposes
		// If what we have is a subpath of the jailbreak root, strip the jailbreak root prefix
		// Else, add the rootfs prefix
		if (!strncmp(path, jbRootPrefix, jbRootPrefixLen)) {
			strlcpy(resolvedPath, &path[jbRootPrefixLen], PATH_MAX);
		}
		else {
			strlcpy(resolvedPath, prefix, PATH_MAX);
			strlcat(resolvedPath, path, PATH_MAX);
		}
	}
	else {
		// Don't modify relative paths
		strlcpy(resolvedPath, path, PATH_MAX);
	}

	return resolvedPath;
}

static char *libroot_jbrootpath_fallback(const char *path, char *resolvedPath)
{
	if (!path) return NULL;
	if (!resolvedPath) resolvedPath = malloc(PATH_MAX);

	const char *prefix = libroot_dyn_get_jbroot_prefix();
	bool skipRedirection = path[0] != '/'; // Don't redirect relative paths

#ifndef IPHONEOS_ARM64
	// Special case
	// On XinaA15 v1: Don't redirect /var/mobile paths to /var/jb/var/mobile
	if (!skipRedirection) {
		if (access("/var/LIY", F_OK) == 0) {
			skipRedirection = strncmp(path, "/var/mobile", 11) == 0;
		}
	}
#endif

	if (!skipRedirection) {
		strlcpy(resolvedPath, prefix, PATH_MAX);
		strlcat(resolvedPath, path, PATH_MAX);
	}
	else {
		strlcpy(resolvedPath, path, PATH_MAX);
	}

	return resolvedPath;
}

static void libroot_load(void)
{
	static dispatch_once_t onceToken;
	dispatch_once (&onceToken, ^{
		void *handle = dlopen("@rpath/libroot.dylib", RTLD_NOW);
		if (handle) {
			dyn_get_root_prefix   = dlsym(handle, "libroot_get_root_prefix");
			dyn_get_jbroot_prefix = dlsym(handle, "libroot_get_jbroot_prefix");
			dyn_get_boot_uuid     = dlsym(handle, "libroot_get_boot_uuid");
			dyn_jbrootpath        = dlsym(handle, "libroot_jbrootpath");
			dyn_rootfspath        = dlsym(handle, "libroot_rootfspath");
		}
		if (!dyn_get_root_prefix)     dyn_get_root_prefix = libroot_get_root_prefix_fallback;
		if (!dyn_get_jbroot_prefix) dyn_get_jbroot_prefix = libroot_get_jbroot_prefix_fallback;
		if (!dyn_get_boot_uuid)         dyn_get_boot_uuid = libroot_get_boot_uuid_fallback;
		if (!dyn_jbrootpath)               dyn_jbrootpath = libroot_jbrootpath_fallback;
		if (!dyn_rootfspath)               dyn_rootfspath = libroot_rootfspath_fallback;
	});
}

const char *libroot_dyn_get_root_prefix(void)
{
	libroot_load();
	return dyn_get_root_prefix();
}

const char *libroot_dyn_get_jbroot_prefix(void)
{
	libroot_load();
	return dyn_get_jbroot_prefix();
}

const char *libroot_dyn_get_boot_uuid(void)
{
	libroot_load();
	return dyn_get_boot_uuid();
}

char *libroot_dyn_rootfspath(const char *path, char *resolvedPath)
{
	libroot_load();
	return dyn_rootfspath(path, resolvedPath);
}

char *libroot_dyn_jbrootpath(const char *path, char *resolvedPath)
{
	libroot_load();
	return dyn_jbrootpath(path, resolvedPath);
}