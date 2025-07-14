#include "screen.h"
#include "terminal.h"
#include <stdbool.h>

#define MAX_INPUT 256

static char input_buffer[MAX_INPUT];
static int input_len = 0;

static int strcmp(const char* s1, const char* s2) {
    while (*s1 && (*s1 == *s2)) {
        s1++;
        s2++;
    }
    return *(const unsigned char*)s1 - *(const unsigned char*)s2;
}

void terminal_put_char(char c) {
    if (c == '\n') {
        print_char('\n');
        input_buffer[input_len] = '\0';
        terminal_handle_command(input_buffer);
        input_len = 0;
    } else if (c == '\b') {
        if (input_len > 0) {
            input_len--;
            print_char('\b');
        }
    } else if (input_len < MAX_INPUT - 1) {
        input_buffer[input_len++] = c;
        print_char(c);
    }
}

void terminal_handle_command(const char* cmd) {
    if (strcmp(cmd, "help") == 0) {
        print_string("Available commands:\n");
        print_string("help - Show this help message\n");
        print_string("clear - Clear the screen\n");
    } else if (strcmp(cmd, "clear") == 0) {
        init_screen(); // defined in screen.c
        redraw_screen();
    } else {
        print_string("Unknown command: ");
        print_string(cmd);
        print_char('\n');
    }
    print_char('>');
}
