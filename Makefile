ASM = nasm
GCC = i686-elf-GCC
LD = i686-elf-ld
OBJCOPY = i686-elf-objcopy

CFLAGS = -ffreestanding -m32
LDFLAGS = -T linker.ld -nostdlib

all: os.bin

os.bin: boot.bin kernel.bin
	cat boot.bin kernel.bin > os.bin

boot.bin: boot.asm
	$(ASM) -f bin $< -o $@

kernel.bin: kernel.elf
	$(OBJCOPY) -O binary $< $@

kernel.elf: kernel.o linker.ld
	$(LD) $(LDFLAGS) -o $@ kernel.o

kernel.o: kernel.c
	$(GCC) $(CFLAGS) -c $< -o $@

clean:
	rm -f *.o *.bin *.elf os.bin