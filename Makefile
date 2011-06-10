include theos/makefiles/common.mk

SUBPROJECTS = uisettingsbar uicore uitoggles
include $(THEOS_MAKE_PATH)/aggregate.mk
after-stage::
	mv _/System/Library/WeeAppPlugins/UISettingsBar.bundle/UISettingsBar.dylib _/System/Library/WeeAppPlugins/UISettingsBar.bundle/UISettingsBar

