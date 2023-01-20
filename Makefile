ARCHS := arm64 arm64e
TARGET := iphone:clang:14.5:13.0
INSTALL_TARGET_PROCESSES := XXTAssistiveTouch

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = XXTAssistiveTouch

XXTAssistiveTouch_USE_MODULES := 0
XXTAssistiveTouch_FILES += $(wildcard *.mm)
XXTAssistiveTouch_CFLAGS += -fobjc-arc
XXTAssistiveTouch_CFLAGS += -Iinclude
XXTAssistiveTouch_CFLAGS += -include hud-prefix.pch
XXTAssistiveTouch_CCFLAGS += -std=c++14
XXTAssistiveTouch_CCFLAGS += -DNOTIFY_LAUNCHED_HUD=\"ch.xxtou.notification.launched.hud\"
XXTAssistiveTouch_CCFLAGS += -DNOTIFY_DISMISSAL_HUD=\"ch.xxtou.notification.dismissal.hud\"
XXTAssistiveTouch_FRAMEWORKS += CoreGraphics QuartzCore UIKit
XXTAssistiveTouch_PRIVATE_FRAMEWORKS += AppSupport BackBoardServices GraphicsServices IOKit SpringBoardServices
ifeq ($(TARGET_CODESIGN),ldid)
XXTAssistiveTouch_CODESIGN_FLAGS += -Sent.plist
else
XXTAssistiveTouch_CODESIGN_FLAGS += --entitlements ent.plist $(TARGET_CODESIGN_FLAGS)
endif

include $(THEOS_MAKE_PATH)/application.mk

after-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Payload$(ECHO_END)
	$(ECHO_NOTHING)cp -rp $(THEOS_STAGING_DIR)/Applications/XXTAssistiveTouch.app $(THEOS_STAGING_DIR)/Payload$(ECHO_END)
	$(ECHO_NOTHING)cd $(THEOS_STAGING_DIR); zip -qr XXTAssistiveTouch.tipa Payload; cd -;$(ECHO_END)