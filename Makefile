ARCHS := arm64  # arm64e
TARGET := iphone:clang:16.4:14.0
INSTALL_TARGET_PROCESSES := XXTAssistiveTouch

include $(THEOS)/makefiles/common.mk

APPLICATION_VERSION = 1.8.5
APPLICATION_NAME = XXTAssistiveTouch

XXTAssistiveTouch_USE_MODULES := 0
XXTAssistiveTouch_FILES += $(wildcard *.mm *.m)
XXTAssistiveTouch_FILES += $(wildcard *.swift)
XXTAssistiveTouch_CFLAGS += -fobjc-arc
XXTAssistiveTouch_CFLAGS += -Iinclude
XXTAssistiveTouch_CFLAGS += -include hud-prefix.pch
XXTAssistiveTouch_CCFLAGS += -DNOTIFY_LAUNCHED_HUD=\"ch.xxtou.notification.hud.launched\"
XXTAssistiveTouch_CCFLAGS += -DNOTIFY_DISMISSAL_HUD=\"ch.xxtou.notification.hud.dismissal\"
XXTAssistiveTouch_CCFLAGS += -DNOTIFY_RELOAD_HUD=\"ch.xxtou.notification.hud.reload\"
XXTAssistiveTouch_FRAMEWORKS += CoreGraphics QuartzCore UIKit
XXTAssistiveTouch_PRIVATE_FRAMEWORKS += BackBoardServices GraphicsServices IOKit SpringBoardServices
ifeq ($(TARGET_CODESIGN),ldid)
XXTAssistiveTouch_CODESIGN_FLAGS += -Sent.plist
else
XXTAssistiveTouch_CODESIGN_FLAGS += --entitlements ent.plist $(TARGET_CODESIGN_FLAGS)
endif

include $(THEOS_MAKE_PATH)/application.mk

after-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Payload$(ECHO_END)
	$(ECHO_NOTHING)cp -rp $(THEOS_STAGING_DIR)/Applications/XXTAssistiveTouch.app $(THEOS_STAGING_DIR)/Payload$(ECHO_END)
	$(ECHO_NOTHING)cd $(THEOS_STAGING_DIR); zip -qr TrollSpeed_$(APPLICATION_VERSION).tipa Payload; cd -;$(ECHO_END)
	$(ECHO_NOTHING)mv $(THEOS_STAGING_DIR)/TrollSpeed_$(APPLICATION_VERSION).tipa packages/TrollSpeed_$(APPLICATION_VERSION).tipa $(ECHO_END)