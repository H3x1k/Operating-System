#include <stdint.h>

#include "screen.h"
#include "keyboard.h"

void kernel_main() {

    init_screen();

    print_string("Hello, World!");

    while(1) {
        char typedChar = get_scancode();  // Get scan code
        char ascii = scancode_to_ascii((uint8_t)typedChar);  // Convert to ASCII
        print_char(ascii);
    }
}

__attribute__((section(".text.start")))
void _start() {
    kernel_main();
}