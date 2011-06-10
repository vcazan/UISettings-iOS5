include theos/makefiles/common.mk

LIBRARY_NAME = UISettingsBar
UISettingsBar_FILES = UISettingsBar.mm
UISettingsBar_INSTALL_PATH = /System/Library/WeeAppPlugins/UISettingsBar.bundle
UISettingsBar_FRAMEWORKS = UIKit CoreGraphics

include $(THEOS_MAKE_PATH)/library.mk

after-stage::
	mv _/System/Library/WeeAppPlugins/UISettingsBar.bundle/UISettingsBar.dylib _/System/Library/WeeAppPlugins/UISettingsBar.bundle/UISettingsBar
