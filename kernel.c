#include <stdint.h>




void kernel_main() {
    
    char *video_memory = (char *)0xB8000;
    video_memory[0] = 'H';
    video_memory[1] = 0x07; // White on black
    video_memory[2] = 'i';
    video_memory[3] = 0x07;

    while(1);
}



// Entry point that will be at 0x1000
void _start() {
    kernel_main();
    
}