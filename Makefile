ASM = nasm
GCC = i686-elf-GCC
LD = i686-elf-ld
OBJCOPY = i686-elf-objcopy
DD = dd

CFLAGS = -ffreestanding -m32
LDFLAGS = -T linker.ld -nostdlib



all: os.bin

os.bin: boot.bin padded_kernel.bin
	cat boot.bin padded_kernel.bin > os.bin

boot.bin: boot.asm
	$(ASM) -f bin $< -o $@

padded_kernel.bin: kernel.bin
	$(eval KERNEL_SIZE := $(shell stat -c %s kernel.bin))
	$(eval SECTOR_COUNT := $(shell echo $$(( ($(KERNEL_SIZE) + 511) / 512 ))))
	@echo Kernel size: $(KERNEL_SIZE)
	@echo Sector count: $(SECTOR_COUNT)
	cp kernel.bin padded_kernel.bin
	truncate -s $$(( $(SECTOR_COUNT) * 512 )) padded_kernel.bin

kernel.bin: kernel.elf
	$(OBJCOPY) -O binary $< $@

kernel.elf: kernel.o linker.ld
	$(LD) $(LDFLAGS) -o $@ kernel.o

kernel.o: kernel.c
	$(GCC) $(CFLAGS) -c $< -o $@

run: os.bin
	qemu-system-x86_64 -drive format=raw,file=os.bin

clean:
	rm -f *.o *.bin *.elf os.bin