OUTPUT_FORMAT("elf32-i386")
ENTRY(_start)

/* 
    fix wrx sections, this warning comes from the compiler
    "warning: build/kernel.elf has a LOAD segment with RWX permissions"
*/

SECTIONS {
    . = 0x1000;
    
    .text : {
        *(.text.start)
        *(.text)
    }
    
    .data : {
        *(.data)
    }
    
    .bss : {
        *(.bss)
    }
}