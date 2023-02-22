ARCHS := arm64  # arm64e
TARGET := iphone:clang:15.4.1:14.0
INSTALL_TARGET_PROCESSES := XXTAssistiveTouch

TARGET_CC := /Library/Developer/Toolchains/Hikari_Swift-LLVM14.0.0git.xctoolchain/usr/bin/clang
TARGET_CXX := /Library/Developer/Toolchains/Hikari_Swift-LLVM14.0.0git.xctoolchain/usr/bin/clang++
TARGET_LD := /Library/Developer/Toolchains/Hikari_Swift-LLVM14.0.0git.xctoolchain/usr/bin/clang++

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = XXTAssistiveTouch

XXTAssistiveTouch_USE_MODULES := 0
XXTAssistiveTouch_FILES += $(wildcard *.mm *.m)
XXTAssistiveTouch_FILES += $(wildcard *.swift)
XXTAssistiveTouch_CFLAGS += -fobjc-arc
XXTAssistiveTouch_CFLAGS += -Iinclude
XXTAssistiveTouch_CFLAGS += -include hud-prefix.pch
XXTAssistiveTouch_CCFLAGS += -std=c++14
XXTAssistiveTouch_CCFLAGS += -DNOTIFY_LAUNCHED_HUD=\"ch.xxtou.notification.hud.launched\"
XXTAssistiveTouch_CCFLAGS += -DNOTIFY_DISMISSAL_HUD=\"ch.xxtou.notification.hud.dismissal\"
XXTAssistiveTouch_CCFLAGS += -DNOTIFY_RELOAD_HUD=\"ch.xxtou.notification.hud.reload\"
# XXTAssistiveTouch_CCFLAGS += -mllvm -enable-splitobf
XXTAssistiveTouch_CCFLAGS += -mllvm -enable-cffobf
# XXTAssistiveTouch_CCFLAGS += -mllvm -enable-bcfobf
XXTAssistiveTouch_CCFLAGS += -mllvm -enable-strcry
XXTAssistiveTouch_CCFLAGS += -mllvm -enable-indibran
XXTAssistiveTouch_CCFLAGS += -mllvm -enable-funcwra
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
	$(ECHO_NOTHING)cd $(THEOS_STAGING_DIR); zip -qr XXTAssistiveTouch.tipa Payload; cd -;$(ECHO_END)