ARCHS = arm64
TARGET = iphone:clang:latest:14.0
PACKAGE_VERSION = 2026.08.18
INSTALL_TARGET_PROCESSES = XYYunVip

TWEAK_NAME = XMLY
XMLY_FILES = Tweak.x
XMLY_FRAMEWORKS = UIKit Foundation
XMLY_PRIVATE_FRAMEWORKS = CoreFoundation
XMLY_CFLAGS = -fobjc-arc

include $(THEOS)/makefiles/common.mk
include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 XYYunVip"
