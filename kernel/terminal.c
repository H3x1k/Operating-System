#include "screen.h"
#include "terminal.h"
#include "ata.h"
#include <stdbool.h>

#ifndef NULL
#define NULL ((void*)0)
#endif

#define MAX_INPUT 256
#define MAX_ARGS 8

static char input_buffer[MAX_INPUT];
static int input_len = 0;

static int strcmp(const char* s1, const char* s2) {
    while (*s1 && (*s1 == *s2)) {
        s1++;
        s2++;
    }
    return *(const unsigned char*)s1 - *(const unsigned char*)s2;
}

static char* strncpy(char* dest, const char* src, unsigned int n) {
    unsigned int i;
    for (i = 0; i < n && src[i] != '\0'; i++) {
        dest[i] = src[i];
    }
    for (; i < n; i++) {
        dest[i] = '\0';
    }
    return dest;
}

static char* strchr(const char* s, int c) {
    while (*s) {
        if (*s == (char)c) {
            return (char*)s;
        }
        s++;
    }
    return 0;
}

static char* strtok(char* str, const char* delim) {
    static char* next;
    if (str) {
        next = str;
    }
    if (!next) {
        return 0;
    }

    // Skip leading delimiters
    char* start = next;
    while (*start && strchr(delim, *start)) {
        start++;
    }
    if (*start == '\0') {
        next = 0;
        return 0;
    }

    // Find the end of the token
    char* end = start;
    while (*end && !strchr(delim, *end)) {
        end++;
    }

    if (*end) {
        *end = '\0';
        next = end + 1;
    } else {
        next = 0;
    }

    return start;
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
     char* args[MAX_ARGS];
    int argc = 0;

    // Make a modifiable copy of the input
    static char buffer[256];
    strncpy(buffer, cmd, sizeof(buffer));
    buffer[sizeof(buffer) - 1] = '\0';

    // Tokenize input by space
    char* token = strtok(buffer, " ");
    while (token && argc < MAX_ARGS) {
        args[argc++] = token;
        token = strtok(NULL, " ");
    }

    if (argc == 0)
        return;

    // --- Command dispatch ---
    if (strcmp(args[0], "echo") == 0) {
        for (int i = 1; i < argc; i++) {
            print_string(args[i]);
            if (i < argc - 1)
                print_char(' ');
        }
        print_char('\n');
    } else if (strcmp(args[0], "wd") == 0) {
        for (int i = 1; i < argc; i++) {
            if (strcmp(args[i], "-s")){

            }
            if (strcmp(args[i], "-c")){
                
            }
        }
        uint8_t buffer[512] = {0};
        int bi = 0;
        for (int i = 1; i < argc; i++) {
            for (int j = 0; args[i][j]; j++)
                buffer[bi++] = args[i][j];
            if (i < argc - 1)
                buffer[bi++] = ' ';
        }
        ata_write_sector(0, buffer);
    } else if (strcmp(args[0], "clear") == 0) {
        init_screen();
        redraw_screen();
    } else if (strcmp(args[0], "help") == 0) {
        print_string("Available commands:\n");
        print_string("  help                             - Show this message\n");
        print_string("  clear                            - Clear the screen\n");
        print_string("  echo [text]                      - Print text\n");
        print_string("  wd -s [sector number] -c [text]  - Write to drive\n");
    } else {
        print_string("Unknown command: ");
        print_string(args[0]);
        print_char('\n');
    }

    print_string("> ");
}
