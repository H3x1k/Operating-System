#include <stdint.h>

#include "screen.h"
#include "keyboard.h"

void kernel_main() {

    print_string("Hello, World!");

    while(1) {
        char typedChar = get_scancode();  // Get scan code
        char ascii = scancode_to_ascii((uint8_t)typedChar);  // Convert to ASCII

        if (ascii) {  // Only print if it's a valid character
            char str[2] = { ascii, '\0' };  // Make a proper null-terminated string
            print_string(str);
        }
    }
}

__attribute__((section(".text.start")))
void _start() {
    kernel_main();
}