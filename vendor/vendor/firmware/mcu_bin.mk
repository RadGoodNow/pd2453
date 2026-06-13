$(warning "MCU_BIN: BBK_PRODUCT_MODEL=$(BBK_PRODUCT_MODEL)")

LOCAL_PATH := $(call my-dir)
#$(shell mkdir  -p  $(TARGET_OUT_VENDOR)/firmware/)
#include $(CLEAR_VARS)
#LOCAL_MODULE       := mcu_bin
#LOCAL_MODULE_TAGS  := optional
#LOCAL_MODULE_CLASS := ETC
#LOCAL_SRC_FILES    := $(LOCAL_MODULE)
#LOCAL_MODULE_PATH  := $(TARGET_OUT_VENDOR)/firmware
#LOCAL_POST_INSTALL_CMD := $(foreach firmware, $(wildcard $(LOCAL_PATH)/*.bin), cp -f $(firmware) $(TARGET_OUT_VENDOR)/firmware/ ;)
#include $(BUILD_PREBUILT)

#$(foreach firmware, $(wildcard $(LOCAL_PATH)/*.bin), $(shell  cp -f $(firmware) $(TARGET_OUT_VENDOR)/firmware/))

ac_etc_list := $(shell cd $(LOCAL_PATH);find.sh)
ac_etc_files += $(foreach file,$(ac_etc_list),$(LOCAL_PATH)/$(file):vendor/firmware/$(file)$(space))
PRODUCT_COPY_FILES := $(ac_etc_files) $(PRODUCT_COPY_FILES)
