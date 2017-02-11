export THEOS_DEVICE_IP=localhost
export THEOS_DEVICE_PORT=2222
#SYSROOT = $(THEOS)/sdks/iPhoneOS10.1.sdk

#export PACKAGE_VERSION = 1.0.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Zeal
Zeal_FILES = Tweak.xm UILabel+Bold.mm ZealAlert.mm UIAlertView+Blocks.m
Zeal_CFLAGS = -w -fobjc-arc -fvisibility=hidden
Zeal_FRAMEWORKS = UIKit Foundation QuartzCore AudioToolbox CoreGraphics #UserNotifications
Zeal_PRIVATE_FRAMEWORKS = CoreDuet BulletinBoard NotificationsUI GraphicsServices BackBoardServices IOKit 
Zeal_LIBRARIES = flipswitch activator

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 backboardd"
SUBPROJECTS += zeal
SUBPROJECTS += zealbannerui
#SUBPROJECTS += zealbannerui10
include $(THEOS_MAKE_PATH)/aggregate.mk
