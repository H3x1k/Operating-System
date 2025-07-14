# Make sure the read sectors register in load_kernel in boot.asm
# does read the amount of sectors the kernel takes up
# If the read sectors register goes over the kernel sector size
# then you will get a disk error

# One thing you can do to make the sector loading automatic
# is to at build time find the size of the kernel and 
# set the first to bytes to that size and have the bootloader
# read the first sector, read the first two bytes from
# memory and then load the given number of sectors
# and jump to the loaded memory address + 0x02
# this would require the linker file to be changed too

# Another method is to use a filesystem
# or multiboot header

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
ATA_SRC = kernel/ata.c

BUILD_DIR = build

BOOT_BIN = $(BUILD_DIR)/boot.bin

KERNEL_O = $(BUILD_DIR)/kernel.o
KERNEL_ELF = $(BUILD_DIR)/kernel.elf
KERNEL_BIN = $(BUILD_DIR)/kernel.bin
PADDED_KERNEL_BIN = $(BUILD_DIR)/padded_kernel.bin

SCREEN_O = $(BUILD_DIR)/screen.o

KEYBOARD_O = $(BUILD_DIR)/keyboard.o

ATA_O = $(BUILD_DIR)/ata.o

KERNEL_OBJS = $(KERNEL_O) $(SCREEN_O) $(KEYBOARD_O) $(ATA_O)

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

$(ATA_O) : $(ATA_SRC) | $(BUILD_DIR)
	$(GCC) $(CFLAGS) -c $< -o $@


$(OS_BIN): $(BOOT_BIN) $(PADDED_KERNEL_BIN) | $(BUILD_DIR)
	cat $^ > $@


run: $(OS_BIN)
	qemu-system-x86_64 -drive format=raw,file=$<

clean:
	rm -rf $(BUILD_DIR)

.PHONY: all clean run