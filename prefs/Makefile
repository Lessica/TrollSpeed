ARCHS := arm64 arm64e
TARGET := iphone:clang:16.5:14.0
INSTALL_TARGET_PROCESSES := Preferences

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME += TrollSpeedPrefs

TrollSpeedPrefs_FILES += TSPrefsRootListController.m

ifeq ($(THEOS_PACKAGE_SCHEME),roothide)
TrollSpeedPrefs_FILES += ../libroot/dyn.c
TrollSpeedPrefs_LIBRARIES += roothide
endif

TrollSpeedPrefs_CFLAGS += -fobjc-arc
TrollSpeedPrefs_CFLAGS += -I../supports/

TrollSpeedPrefs_FRAMEWORKS += UIKit
TrollSpeedPrefs_PRIVATE_FRAMEWORKS += Preferences
TrollSpeedPrefs_INSTALL_PATH += /Library/PreferenceBundles

include $(THEOS_MAKE_PATH)/bundle.mk
