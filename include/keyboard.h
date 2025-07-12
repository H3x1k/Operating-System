#ifndef KEYBOARD_H
#define KEYBOARD_H

#include <stdint.h>

char get_scancode();
char scancode_to_ascii(uint8_t scancode);

#endif