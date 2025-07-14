#include <stdint.h>

#include "screen.h"
#include "keyboard.h"
#include "terminal.h"

#include "ata.h"

void kernel_main() {

    init_screen();

    print_string("Hello, World!\n>");

    /* Code to write to hdd
    uint8_t buffer[512] = {0};
    const char* msg = "Hello from OS!";
    for (int i = 0; msg[i]; i++)
        buffer[i] = msg[i];

    ata_write_sector(6, buffer);  // Don't use sector 0 — it's the MBR
    */

    while(1) {
        char typedChar = get_scancode();  // Get scan code
        char ascii = scancode_to_ascii((uint8_t)typedChar);  // Convert to ASCII
        terminal_put_char(ascii);
    }
}

__attribute__((section(".text.start")))
void _start() {
    kernel_main();
}