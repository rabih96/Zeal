include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = Zeal
Zeal_FILES = ZealRootListController.m ZealHeaderView.m ZSegmentCell.m
Zeal_INSTALL_PATH = /Library/PreferenceBundles
Zeal_FRAMEWORKS = UIKit
Zeal_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/Zeal.plist$(ECHO_END)
