COMMON_LIB := lib/common.sh
TARGET_STEP_DIRS = $(sort $(dir $(wildcard steps/declarativesystems/*/)))
TARGET_RES_DIRS = $(sort $(dir $(wildcard resources/declarativesystems/*/)))

scripts: test
	$(foreach TARGET_DIR,$(TARGET_STEP_DIRS),$(call concat_step,$(TARGET_DIR)))
	$(foreach TARGET_DIR,$(TARGET_RES_DIRS),$(call concat_res,$(TARGET_DIR)))

define write_header

	echo "# =====[DO NOT EDIT THIS FILE]=====" > $(1)
endef

define concat_step
	$(call write_header,$(1)onExecute.sh)
	cat $(COMMON_LIB) >> $(1)onExecute.sh
	cat $(1)src/onExecute.sh >> $(1)onExecute.sh
endef

define concat_res
	$(call write_header,$(1)onInput.sh)
	cat $(COMMON_LIB) >> $(1)onInput.sh
	cat $(1)src/onInput.sh >> $(1)onInput.sh
endef

clean:
	rm -f steps/declarativesystems/*/onExecute.sh
	rm -f resources/declarativesystems/*/onInput.sh
	rm -f resources/declarativesystems/*/onOutput.sh

test:
	echo "=== bash syntax ==="
	bash -n lib/common.sh
	find . -iname '*.sh' -print0 | xargs -0L1 bash -n

	echo "=== yaml syntax ==="
	./res/validate_yaml.py
