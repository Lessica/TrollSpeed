ARCHS := arm64 arm64e
TARGET := iphone:clang:15.6:14.0
INSTALL_TARGET_PROCESSES := Preferences

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME += TrollSpeedPrefs

TrollSpeedPrefs_FILES += TSPrefsRootListController.m
TrollSpeedPrefs_FRAMEWORKS += UIKit
TrollSpeedPrefs_PRIVATE_FRAMEWORKS += Preferences
TrollSpeedPrefs_INSTALL_PATH += /Library/PreferenceBundles
TrollSpeedPrefs_CFLAGS += -fobjc-arc
TrollSpeedPrefs_CFLAGS += -I../supports/

include $(THEOS_MAKE_PATH)/bundle.mk
