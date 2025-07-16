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
# DONE

# Another method is to use a filesystem
# or multiboot header

ASM = nasm
GCC = i686-elf-GCC
LD = i686-elf-ld
OBJCOPY = i686-elf-objcopy
DD = dd

CFLAGS = -ffreestanding -m32 -Iinclude
LDFLAGS = -T linker.ld -nostdlib

BUILD_DIR = build

BOOT_SRC = boot/boot.asm
BOOT_BIN = $(BUILD_DIR)/boot.bin

KERNEL_SRCS := $(wildcard kernel/*.c)
KERNEL_OBJS := $(patsubst kernel/%.c, build/%.o, $(KERNEL_SRCS))

KERNEL_ELF = $(BUILD_DIR)/kernel.elf
KERNEL_BIN = $(BUILD_DIR)/kernel.bin
PADDED_KERNEL_BIN = $(BUILD_DIR)/padded_kernel.bin

OS_BIN = $(BUILD_DIR)/os.bin

all: $(OS_BIN)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(BOOT_BIN): $(BOOT_SRC) | $(BUILD_DIR)
	$(ASM) -f bin $< -o $@


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
	printf "\\$(shell printf '%03o' $$(( $(SECTOR_COUNT) & 0xFF )))\\$(shell printf '%03o' $$(( ($(SECTOR_COUNT) >> 8) & 0xFF )))" | dd of=$(PADDED_KERNEL_BIN) bs=1 count=2 conv=notrunc
	truncate -s $$(( $(SECTOR_COUNT) * 512 )) $@

build/%.o: kernel/%.c | $(BUILD_DIR)
	$(GCC) $(CFLAGS) -c $< -o $@

$(OS_BIN): $(BOOT_BIN) $(PADDED_KERNEL_BIN) | $(BUILD_DIR)
	cat $^ > $@

run: $(OS_BIN)
	qemu-system-x86_64 -drive format=raw,file=$<

clean:
	rm -rf $(BUILD_DIR)

.PHONY: all clean run