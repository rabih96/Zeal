include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Zeal
Zeal_FILES = Tweak.xm MBACustomAlert.mm UILabel+Bold.mm
Zeal_CFLAGS = -w -fobjc-arc -fvisibility=hidden #-x objective-c
Zeal_FRAMEWORKS = UIKit Foundation QuartzCore AudioToolbox CoreGraphics
Zeal_PRIVATE_FRAMEWORKS = CoreDuet BulletinBoard NotificationsUI GraphicsServices BackBoardServices
Zeal_LIBRARIES = flipswitch activator

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 backboardd"
SUBPROJECTS += zeal
SUBPROJECTS += zealbannerui
include $(THEOS_MAKE_PATH)/aggregate.mk
