#include "keyboard.h"

static char scancode_to_ascii_array[128] = {
    0,  27, '1','2','3','4','5','6','7','8','9','0','-','=','\b',
    '\t','q','w','e','r','t','y','u','i','o','p','[',']','\n', 0,
    'a','s','d','f','g','h','j','k','l',';','\'','`', 0,'\\',
    'z','x','c','v','b','n','m',',','.','/', 0, '*', 0,' ',
    // fill rest as needed
};

static inline uint8_t inb(uint16_t port) {
    uint8_t val;
    __asm__ volatile ("inb %1, %0" : "=a"(val) : "Nd"(port));
    return val;
}

char get_scancode() {
    while (1) {
        uint8_t status = inb(0x64);
        if (status & 1) {
            return inb(0x60);
        }
    }
}

char scancode_to_ascii(uint8_t scancode) {
    return scancode_to_ascii_array[(uint8_t)scancode];
}