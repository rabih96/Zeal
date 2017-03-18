#SYSROOT = $(THEOS)/sdks/iPhoneOS10.1.sdk

export PACKAGE_VERSION = 1.0.1

ifdef SIMULATOR
TARGET = simulator:clang
ARCHS = x86_64
else
TARGET = iphone:latest
ARCHS = arm64
THEOS_DEVICE_IP=192.168.1.65
THEOS_DEVICE_PORT=22
endif

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Zeal
Zeal_FILES = Tweak.xm UILabel+Bold.mm ZealAlert.xm
Zeal_CFLAGS = -fobjc-arc #-w -fvisibility=hidden
Zeal_FRAMEWORKS = UIKit Foundation QuartzCore AudioToolbox CoreGraphics #UserNotifications
Zeal_PRIVATE_FRAMEWORKS = CoreDuet BulletinBoard NotificationsUI GraphicsServices BackBoardServices FrontBoardServices
Zeal_LIBRARIES = flipswitch activator

ifdef SIMULATOR
Zeal_INSTALL_PATH = /opt/simject
endif

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += zeal
SUBPROJECTS += zealbannerui

include $(THEOS_MAKE_PATH)/aggregate.mk

after-Zeal-all::
	ldid -S $(THEOS_OBJ_DIR)/$(THEOS_CURRENT_INSTANCE)$(TARGET_LIB_EXT)

after-install::
	install.exec "killall -9 backboardd"
