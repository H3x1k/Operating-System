#include "keyboard.h"

#include "io.h"

static char scancode_to_ascii_array[128] = {
    0,  27, '1','2','3','4','5','6','7','8','9','0','-','=','\b',  // 0x00 - 0x0F
    '\t','q','w','e','r','t','y','u','i','o','p','[',']','\n', 0,  // 0x10 - 0x1F
    'a','s','d','f','g','h','j','k','l',';','\'','`', 0, '\\',     // 0x20 - 0x2F
    'z','x','c','v','b','n','m',',','.','/', 0, '*', 0, ' ',       // 0x30 - 0x3D
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,                // 0x3E - 0x4D
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0                 // 0x4E - 0x5D
};

char get_scancode() {
    while (1) {
        uint8_t status = inb(0x64);
        if (status & 1) {
            uint8_t code = inb(0x60);
            if ((code & 0x80) == 0)  // only return make codes (press)
                return code;
        }
    }
}

char scancode_to_ascii(uint8_t scancode) {
    //if (scancode < sizeof(scancode_to_ascii_array))
        return scancode_to_ascii_array[scancode];
    //return 0;
}