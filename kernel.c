// This tells the compiler the function should use 32-bit instructions
void __attribute__((cdecl)) kernel_main();

void kernel_main() {
    // Your kernel code here
    volatile char *video_memory = (volatile char *)0xB8000;
    video_memory[0] = 'H';
    video_memory[1] = 0x07; // White on black
    video_memory[2] = 'i';
    video_memory[3] = 0x07;
    
    while(1) {} // Hang
}

// Entry point that will be at 0x1000
void _start() {
    kernel_main();
}