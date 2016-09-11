include $(THEOS)/makefiles/common.mk

TWEAK_NAME = ZealUIKit
ZealUIKit_FILES = Tweak.xm
ZealUIKit_FRAMEWORKS = UIKit
ZealUIKit_LIBRARIES = objcipc

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 backboardd"
