#include <stdint.h>

static inline uint8_t inb(uint16_t port) {
    uint8_t val;
    __asm__ volatile ("inb %1, %0" : "=a"(val) : "Nd"(port));
    return val;
}

static inline void outb(uint16_t port, uint8_t val) {
    __asm__ volatile ("outb %0, %1" : : "a"(val), "Nd"(port));
}

void move_cursor(uint16_t pos) {
    outb(0x3D4, 0x0F);            // Tell VGA we’re setting the low byte
    outb(0x3D5, (uint8_t)(pos & 0xFF));   // Send low byte of cursor pos
    outb(0x3D4, 0x0E);            // Tell VGA we’re setting the high byte
    outb(0x3D5, (uint8_t)((pos >> 8) & 0xFF)); // Send high byte of cursor pos
}

void print_string(const char *str, uint16_t *video_memory, uint8_t style, uint16_t *cursor_pos) {
    for (int i = 0; str[i] != '\0'; i++) {
        if (str[i] == '\n') {
            // Move to next line
            *cursor_pos += 80 - (*cursor_pos % 80);
        } else {
            video_memory[*cursor_pos] = (style << 8) | str[i];
            (*cursor_pos)++;
        }

        if (*cursor_pos >= 80 * 25) {
            *cursor_pos = 0; // Simple wrap (replace with scrolling if needed)
        }
    }
}

char get_scancode() {
    while (1) {
        uint8_t status = inb(0x64);
        if (status & 1) {
            return inb(0x60);
        }
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
    
    char scancode_to_ascii[128] = {
        0,  27, '1','2','3','4','5','6','7','8','9','0','-','=','\b',
        '\t','q','w','e','r','t','y','u','i','o','p','[',']','\n', 0,
        'a','s','d','f','g','h','j','k','l',';','\'','`', 0,'\\',
        'z','x','c','v','b','n','m',',','.','/', 0, '*', 0,' ',
        // fill rest as needed
    };
    
    

    uint16_t *video_memory = (uint16_t *)0xB8000;
    const char *str = "Hello World!\n";
    uint8_t style = 0x07;
    uint16_t cursor_pos = 0;

    print_string(str, video_memory, style, &cursor_pos);
    move_cursor(cursor_pos);

    while (1) {
        char typedChar = get_scancode();  // Get scan code
        char ascii = scancode_to_ascii[(uint8_t)typedChar];  // Convert to ASCII

        if (ascii) {  // Only print if it's a valid character
            char str[2] = { ascii, '\0' };  // Make a proper null-terminated string
            print_string(str, video_memory, style, &cursor_pos);
        }
        move_cursor(cursor_pos);
    }
}

__attribute__((section(".text.start")))
void _start() {
    kernel_main();
}