#

echo "Assembling bootloader..."
nasm -f bin boot.asm -o boot.bin

echo "Creating blank disk image..."
dd if=/dev/zero of=disk.img bs=1M count=64

echo "Writing bootloader to disk image..."
dd if=boot.bin of=disk.img conv=notrunc bs=512 count=1

echo "Converting to VDI..."
VBoxManage convertfromraw disk.img disk.vdi --format VDI

echo "Done!"
