#ifndef SCREEN_H
#define SCREEN_H

#include <stdint.h>

void init_screen();
void redraw_screen();
void print_char(char c);
void print_string(const char *str);
void scroll_up();
void scroll_down();
void move_cursor(uint16_t pos);

#endif