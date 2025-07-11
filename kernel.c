#include <stdint.h>

static inline void outb(uint16_t port, uint8_t val) {
    __asm__ volatile ("outb %0, %1" : : "a"(val), "Nd"(port));
}

void move_cursor(uint16_t pos) {
    outb(0x3D4, 0x0F);            // Tell VGA we’re setting the low byte
    outb(0x3D5, (uint8_t)(pos & 0xFF));   // Send low byte of cursor pos
    outb(0x3D4, 0x0E);            // Tell VGA we’re setting the high byte
    outb(0x3D5, (uint8_t)((pos >> 8) & 0xFF)); // Send high byte of cursor pos
}

void print_string(char *str, char *memory_position, uint8_t style) {
    for (int i = 0; str[i] != '\0'; i++) {
        memory_position[i * 2] = str[i];
        memory_position[i * 2 + 1] = style;
    }
}

void kernel_main() {
    /*
        This uses VGA
        VGA is 80 by 25
        Video memory from 0xb8000 hold all of the data drawn to the screen
        each letter/position starting from the top left on the screen uses 2 bytes
        one for the ascii character and one for the color
        the position on the screen corresponds to 2 bytes in video memory
        to calculate the memory address to use, you would use   row * 80 + column
    */

    char *video_memory = (char *)0xB8000;
    char *str = "Hello World!";
    uint8_t style = 0x07;

    print_string(str, video_memory, style);

    move_cursor(
        (0 * 80 + 2)
    );

    return;
}

__attribute__((section(".text.start")))
void _start() {
    kernel_main();

    while(1) {}
}