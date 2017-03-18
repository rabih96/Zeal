SYSROOT = $(THEOS)/sdks/iPhoneOS9.3.sdk

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = ZealBannerUI
ZealBannerUI_FILES = Tweak.xm
ZealBannerUI_FRAMEWORKS = UIKit CoreGraphics BackBoardServices
ZealBannerUI_PRIVATE_FRAMEWORKS = CoreDuet NotificationsUI ChatKit AppSupport
ZealBannerUI_CFLAGS = -fobjc-arc #-x objective-c -fvisibility=hidden
ZealBannerUI_LIBRARIES = flipswitch substrate

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 backboardd"
