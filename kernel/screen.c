#include "screen.h"

#include "io.h"

/*
    This uses VGA
    VGA is 80 by 25
    Video memory from 0xb8000 hold all of the data drawn to the screen
    each letter/position starting from the top left on the screen uses 2 bytes
    one for the ascii character and one for the color
    the position on the screen corresponds to 2 bytes in video memory
    to calculate the memory address to use, you would use   row * 80 + column
*/

/*

-----  ISSUES  -----
- Cursor disapears after scroll (move_cursor needs work)
- Backspace somehow works
- Scolling needs work

*/

#define VGA_WIDTH 80
#define VGA_HEIGHT 25
#define VGA_MEMORY ((uint16_t *)0xB8000)
#define DEFAULT_ATTR 0x07
#define BUFFER_LINES 1000

static uint16_t screen_text_buffer[BUFFER_LINES][VGA_WIDTH];
static int scroll_offset = 0;
static uint16_t cursor_pos = 0;

void init_screen() {
    for (int i = 0; i < BUFFER_LINES; i++) {
        for (int j = 0; j < VGA_WIDTH; j++) {
            screen_text_buffer[i][j] = ((uint16_t)DEFAULT_ATTR << 8) | ' ';
        }
    }
    cursor_pos = 0;
    scroll_offset = 0;
}

void redraw_screen() {
    for (int y = 0; y < VGA_HEIGHT; y++) {
        int buffer_line = scroll_offset + y;
        if (buffer_line < BUFFER_LINES) {
            for (int x = 0; x < VGA_WIDTH; x++) {
                VGA_MEMORY[y * VGA_WIDTH + x] = screen_text_buffer[buffer_line][x];
            }
        }
    }
}

void move_cursor(uint16_t pos) {
    cursor_pos = pos;

    //uint16_t screen_pos = pos - (scroll_offset * VGA_WIDTH);
    //screen_pos = pos;

    //if (screen_pos < 0 || screen_pos >= VGA_WIDTH * VGA_HEIGHT) {
        //return; // Don't update hardware cursor if it's off screen
    //}

    outb(0x3D4, 0x0F);
    outb(0x3D5, (uint8_t)(pos & 0xFF));
    outb(0x3D4, 0x0E);
    outb(0x3D5, (uint8_t)((pos >> 8) & 0xFF));
}

void scroll_up() {
    if (scroll_offset > 0) {
        scroll_offset--;
        redraw_screen();
    }
}

void scroll_down() {
    if (scroll_offset + VGA_HEIGHT < BUFFER_LINES) {
        scroll_offset++;
        redraw_screen();
    }
}

void print_char(char c) {
    int line = cursor_pos / VGA_WIDTH;
    int col = cursor_pos % VGA_WIDTH;

    if (c == '\n') {
        cursor_pos += VGA_WIDTH - col;
    } else if (c == '\b') {
        if (cursor_pos > 0) {
            cursor_pos--;
            int back_line = cursor_pos / VGA_WIDTH;
            int back_col = cursor_pos % VGA_WIDTH;
            screen_text_buffer[back_line][back_col] = ((uint16_t)DEFAULT_ATTR << 8) | ' ';
        }
    } else {
        if (line < BUFFER_LINES) {
            screen_text_buffer[line][col] = ((uint16_t)DEFAULT_ATTR << 8) | c;
            cursor_pos++;
        }
    }

    // Scroll if necessary
    if (cursor_pos >= (scroll_offset + VGA_HEIGHT) * VGA_WIDTH) {
        if (scroll_offset + VGA_HEIGHT < BUFFER_LINES)
            scroll_offset++;
        else
            cursor_pos -= VGA_WIDTH;  // prevent writing off buffer end
        redraw_screen();
    }

    redraw_screen();
    move_cursor(cursor_pos);
}

void print_string(const char *str) {
    while (*str) {
        int line = cursor_pos / VGA_WIDTH;
        int col = cursor_pos % VGA_WIDTH;

        if (*str == '\n') {
            cursor_pos += VGA_WIDTH - col;
        } else {
            if (line < BUFFER_LINES) {
                screen_text_buffer[line][col] = ((uint16_t)DEFAULT_ATTR << 8) | *str;
                cursor_pos++;
            }
        }

        // Wrap to top if overflow (very simple)
        if (cursor_pos >= (scroll_offset + VGA_HEIGHT) * VGA_WIDTH) {
            if (scroll_offset + VGA_HEIGHT < BUFFER_LINES)
                scroll_offset++;
            else
                cursor_pos -= VGA_WIDTH;
            redraw_screen();
        }

        str++;
    }

    redraw_screen();
    move_cursor(cursor_pos);
}