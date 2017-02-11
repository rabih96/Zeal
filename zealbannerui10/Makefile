include $(THEOS)/makefiles/common.mk

TWEAK_NAME = ZealBannerUI10
ZealBannerUI10_FILES = Tweak.xm
ZealBannerUI10_FRAMEWORKS = UIKit CoreGraphics BackBoardServices
ZealBannerUI10_PRIVATE_FRAMEWORKS = CoreDuet AppSupport
ZealBannerUI10_CFLAGS = -fobjc-arc #-x objective-c -fvisibility=hidden
ZealBannerUI10_LIBRARIES = flipswitch substrate

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
