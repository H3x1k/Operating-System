#include "ata.h"

#define ATA_DATA       0x1F0
#define ATA_SECCOUNT0  0x1F2
#define ATA_LBA0       0x1F3
#define ATA_LBA1       0x1F4
#define ATA_LBA2       0x1F5
#define ATA_DRIVE      0x1F6
#define ATA_COMMAND    0x1F7
#define ATA_STATUS     0x1F7

#define ATA_CMD_WRITE  0x30
#define ATA_CMD_FLUSH  0xE7

static inline void io_wait() {
    for (volatile int i = 0; i < 1000; ++i);
}

static inline void outb(uint16_t port, uint8_t val) {
    asm volatile ("outb %0, %1" : : "a"(val), "Nd"(port));
}

static inline void outw(uint16_t port, uint16_t val) {
    asm volatile ("outw %0, %1" : : "a"(val), "Nd"(port));
}

static inline uint8_t inb(uint16_t port) {
    uint8_t ret;
    asm volatile ("inb %1, %0" : "=a"(ret) : "Nd"(port));
    return ret;
}

void ata_write_sector(uint32_t lba, uint8_t* buffer) {
    outb(ATA_SECCOUNT0, 1);                  // 1 sector
    outb(ATA_LBA0, lba & 0xFF);
    outb(ATA_LBA1, (lba >> 8) & 0xFF);
    outb(ATA_LBA2, (lba >> 16) & 0xFF);
    outb(ATA_DRIVE, 0xE0 | ((lba >> 24) & 0x0F));
    outb(ATA_COMMAND, ATA_CMD_WRITE);

    // Wait for drive to be ready
    while (!(inb(ATA_STATUS) & 0x08));

    // Write 256 words (512 bytes)
    for (int i = 0; i < 256; i++) {
        uint16_t word = ((uint16_t*)buffer)[i];
        outw(ATA_DATA, word);
    }

    // Flush cache
    outb(ATA_COMMAND, ATA_CMD_FLUSH);
    while (inb(ATA_STATUS) & 0x80); // Wait until BSY clears
}
