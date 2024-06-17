ARCHS := arm64  # arm64e
TARGET := iphone:clang:15.6:14.0
INSTALL_TARGET_PROCESSES := TrollSpeed
ENT_PLIST := $(PWD)/supports/entitlements.plist
LAUNCHD_PLIST := $(PWD)/layout/Library/LaunchDaemons/ch.xxtou.hudservices.plist

include $(THEOS)/makefiles/common.mk

GIT_TAG_SHORT := $(shell git describe --tags --always --abbrev=0)
APPLICATION_NAME := TrollSpeed

TrollSpeed_USE_MODULES := 0
TrollSpeed_FILES += $(wildcard sources/*.mm sources/*.m)
TrollSpeed_FILES += $(wildcard sources/KIF/*.mm sources/KIF/*.m)
TrollSpeed_FILES += $(wildcard sources/*.swift)
TrollSpeed_FILES += $(wildcard sources/SPLarkController/*.swift)
TrollSpeed_FILES += $(wildcard sources/SnapshotSafeView/*.swift)

# App Intents will be built from Xcode.
# TrollSpeed_FILES += $(wildcard sources/Intents/*.swift)

TrollSpeed_CFLAGS += -fobjc-arc
TrollSpeed_CFLAGS += -Iheaders
TrollSpeed_CFLAGS += -Isources
TrollSpeed_CFLAGS += -Isources/KIF
TrollSpeed_CFLAGS += -include supports/hudapp-prefix.pch
MainApplication.mm_CCFLAGS += -std=c++14

TrollSpeed_SWIFT_BRIDGING_HEADER += supports/hudapp-bridging-header.h

TrollSpeed_LDFLAGS += -Flibraries

TrollSpeed_FRAMEWORKS += CoreGraphics CoreServices QuartzCore IOKit UIKit
TrollSpeed_PRIVATE_FRAMEWORKS += BackBoardServices GraphicsServices SpringBoardServices
TrollSpeed_CODESIGN_FLAGS += -Ssupports/entitlements.plist

include $(THEOS_MAKE_PATH)/application.mk

SUBPROJECTS += prefs
ifneq ($(FINALPACKAGE),1)
SUBPROJECTS += memory_pressure
endif

include $(THEOS_MAKE_PATH)/aggregate.mk

before-all::
	$(ECHO_NOTHING)defaults write $(LAUNCHD_PLIST) ProgramArguments -array "$(THEOS_PACKAGE_INSTALL_PREFIX)/Applications/TrollSpeed.app/TrollSpeed" "-hud" || true$(ECHO_END)
	$(ECHO_NOTHING)plutil -convert xml1 $(LAUNCHD_PLIST)$(ECHO_END)
	$(ECHO_NOTHING)chmod 0644 $(LAUNCHD_PLIST)$(ECHO_END)

before-package::
	$(ECHO_NOTHING)mv -f $(THEOS_STAGING_DIR)/usr/local/bin/memory_pressure $(THEOS_STAGING_DIR)/Applications/TrollSpeed.app || true$(ECHO_END)
	$(ECHO_NOTHING)rmdir $(THEOS_STAGING_DIR)/usr/local/bin $(THEOS_STAGING_DIR)/usr/local $(THEOS_STAGING_DIR)/usr || true$(ECHO_END)

after-package::
	$(ECHO_NOTHING)mkdir -p packages $(THEOS_STAGING_DIR)/Payload$(ECHO_END)
	$(ECHO_NOTHING)cp -rp $(THEOS_STAGING_DIR)$(THEOS_PACKAGE_INSTALL_PREFIX)/Applications/TrollSpeed.app $(THEOS_STAGING_DIR)/Payload$(ECHO_END)
	$(ECHO_NOTHING)defaults delete $(THEOS_STAGING_DIR)/Payload/TrollSpeed.app/Info.plist CFBundleIconName || true$(ECHO_END)
	$(ECHO_NOTHING)defaults write $(THEOS_STAGING_DIR)/Payload/TrollSpeed.app/Info.plist CFBundleVersion -string $(shell openssl rand -hex 4)$(ECHO_END)
	$(ECHO_NOTHING)plutil -convert xml1 $(THEOS_STAGING_DIR)/Payload/TrollSpeed.app/Info.plist$(ECHO_END)
	$(ECHO_NOTHING)chmod 0644 $(THEOS_STAGING_DIR)/Payload/TrollSpeed.app/Info.plist$(ECHO_END)
	$(ECHO_NOTHING)cd $(THEOS_STAGING_DIR); zip -qr TrollSpeed_${GIT_TAG_SHORT}.tipa Payload; cd -;$(ECHO_END)
	$(ECHO_NOTHING)mv $(THEOS_STAGING_DIR)/TrollSpeed_${GIT_TAG_SHORT}.tipa packages/TrollSpeed_${GIT_TAG_SHORT}.tipa$(ECHO_END)
