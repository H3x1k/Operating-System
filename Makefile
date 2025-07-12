ASM = nasm
GCC = i686-elf-GCC
LD = i686-elf-ld
OBJCOPY = i686-elf-objcopy
DD = dd

CFLAGS = -ffreestanding -m32 -Iinclude
LDFLAGS = -T linker.ld -nostdlib

BOOT_SRC = boot/boot.asm
KERNEL_SRC = kernel/kernel.c
SCREEN_SRC = kernel/screen.c
KEYBOARD_SRC = kernel/keyboard.c

BUILD_DIR = build

BOOT_BIN = $(BUILD_DIR)/boot.bin

KERNEL_O = $(BUILD_DIR)/kernel.o
KERNEL_ELF = $(BUILD_DIR)/kernel.elf
KERNEL_BIN = $(BUILD_DIR)/kernel.bin
PADDED_KERNEL_BIN = $(BUILD_DIR)/padded_kernel.bin

SCREEN_O = $(BUILD_DIR)/screen.o

KEYBOARD_O = $(BUILD_DIR)/keyboard.o

KERNEL_OBJS = $(KERNEL_O) $(SCREEN_O) $(KEYBOARD_O)

OS_BIN = $(BUILD_DIR)/os.bin

all: $(OS_BIN)

# Make sure build dir exists
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)


$(BOOT_BIN): $(BOOT_SRC) | $(BUILD_DIR)
	$(ASM) -f bin $< -o $@


$(KERNEL_O): $(KERNEL_SRC) | $(BUILD_DIR)
	$(GCC) $(CFLAGS) -c $< -o $@

$(KERNEL_ELF): $(KERNEL_OBJS) linker.ld | $(BUILD_DIR)
	$(LD) $(LDFLAGS) -o $@ $(KERNEL_OBJS)

$(KERNEL_BIN): $(KERNEL_ELF) | $(BUILD_DIR)
	$(OBJCOPY) -O binary $< $@

$(PADDED_KERNEL_BIN): $(KERNEL_BIN) | $(BUILD_DIR)
	$(eval KERNEL_SIZE := $(shell stat -c %s $<))
	$(eval SECTOR_COUNT := $(shell echo $$(( ($(KERNEL_SIZE) + 511) / 512 ))))
	@echo Kernel size: $(KERNEL_SIZE)
	@echo Sector count: $(SECTOR_COUNT)
	cp $< $@
	truncate -s $$(( $(SECTOR_COUNT) * 512 )) $@


$(SCREEN_O): $(SCREEN_SRC) | $(BUILD_DIR)
	$(GCC) $(CFLAGS) -c $< -o $@

$(KEYBOARD_O) : $(KEYBOARD_SRC) | $(BUILD_DIR)
	$(GCC) $(CFLAGS) -c $< -o $@


$(OS_BIN): $(BOOT_BIN) $(PADDED_KERNEL_BIN) | $(BUILD_DIR)
	cat $^ > $@


run: $(OS_BIN)
	qemu-system-x86_64 -drive format=raw,file=$<

clean:
	rm -rf $(BUILD_DIR)

.PHONY: all clean run