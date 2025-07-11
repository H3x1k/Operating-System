[ORG 0x7C00]    ; BOIS loads bootloader at 0x7c00
[BITS 16]       ; Starts off in 16-bit real mode

start:
    ; Save boot drive
    mov [boot_drive], dl

    ; Set up segments for real mode
    xor ax, ax        ; Segments can't be directly set use 16 bit register
    mov ds, ax       ; Data Segment
    mov es, ax       ; Extra Segment
    mov ss, ax       ; Stack Segment
    mov sp, 0x7C00   ; The stack starts decreases from where the bootloader is loaded 


    ;mov si, disk_success_msg
    ;call print_string

    ; Load kernel here
    call load_kernel
    mov si, disk_success_msg
    call print_string

    ; Set up A20 Line ???

    ; Load GDT
    lgdt [gdt_descriptor]

    ; VGA 80x25 text mode
    mov ah, 0x00
    mov al, 0x03
    int 0x10

    ; Disable interrupts
    cli

    ; Enter protected mode
    mov eax, cr0
    or eax, 1
    mov cr0, eax


    ;mov si, protected_mode_msg
    ;call print_string_vga

    ; Far jump to 32-bit section
    jmp CODE_SEG:protected_mode_entry


load_kernel:       ; Uses Cylinder-Head-Sector addressing
    mov bx, 0x1000         ; Load kernel at 0x1000
    mov dh, 0              ; Head 0
    mov dl, [boot_drive]   ; Drive number (saved from boot)
    mov ch, 0              ; Cylinder 0
    mov cl, 2              ; Start from sector 2 (sector 1 is the bootloader)
    mov al, 1              ; Read 15 sectors (adjust based on kernel size)

    mov ah, 0x02           ; BIOS read sectors function
    int 0x13               ; Call BIOS

    jc disk_error          ; Jump if carry flag set (error)

    ret


disk_error:
    mov si, disk_error_msg
    call print_string
    jmp $




print_string:
    ; Print null-terminated string pointed to by SI
    push ax
    push bx

print_loop:
    lodsb            ; Load byte from [SI] into AL and increment SI
    cmp al, 0        ; Check if null terminator
    je print_done    ; If yes, we're done

    mov ah, 0x0E     ; BIOS teletype function
    mov bh, 0        ; Page number
    mov bl, 0x07     ; Text attribute (white on black)
    int 0x10

    jmp print_loop

print_done:
    pop bx
    pop ax
    ret




[BITS 32]                ; Switch to 32-bit mode

protected_mode_entry:
    ; Set up all segments and stack here
    mov ax, DATA_SEG
    mov ds, ax       ; Data Segment
    mov es, ax       ; Extra Segment
    mov fs, ax       ; General-purpose Segment
    mov gs, ax       ; General-purpose Segment
    mov ss, ax       ; Stack Segment
    mov esp, 0x90000 ; Extended stack pointer 

    ; Jump to C kernel
    jmp CODE_SEG:0x1000       ; Jump to where the kernel is loaded

    jmp $




gdt_start:
    ; Null descriptor (required)
    dd 0x0
    dd 0x0

gdt_code:
    ; Code segment descriptor
    dw 0xFFFF      ; Limit (low 16 bits)
    dw 0x0000      ; Base (low 16 bits)
    db 0x00        ; Base (middle 8 bits)
    db 10011010b   ; Access byte (present, ring 0, executable, readable)
    db 11001111b   ; Flags (4 bits) + Limit (high 4 bits)
    db 0x00        ; Base (high 8 bits)

gdt_data:
    ; Data segment descriptor
    dw 0xFFFF      ; Limit (low 16 bits)
    dw 0x0000      ; Base (low 16 bits)
    db 0x00        ; Base (middle 8 bits)
    db 10010010b   ; Access byte (present, ring 0, writable)
    db 11001111b   ; Flags + Limit
    db 0x00        ; Base (high 8 bits)

gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1   ; Size of GDT
    dd gdt_start                 ; Address of GDT

; Define segment selectors
CODE_SEG equ gdt_code - gdt_start
DATA_SEG equ gdt_data - gdt_start






enable_a20: 




print_string_vga:
    ; Print null-terminated string pointed to by SI
    ; Uses VGA text mode memory at 0xB8000
    push ax
    push bx
    push es
    
    mov ax, 0xB800      ; VGA text mode segment
    mov es, ax          ; Set ES to VGA memory
    mov bx, [cursor_pos] ; Get current cursor position
    
print_vga_loop:
    lodsb               ; Load character from [SI] into AL
    cmp al, 0           ; Check for null terminator
    je print_vga_done   ; If null, we're done
    
    ; Handle newline
    cmp al, 10          ; Line feed (LF)
    je handle_newline
    cmp al, 13          ; Carriage return (CR)
    je handle_newline
    
    ; Print character
    mov [es:bx], al     ; Store character
    inc bx              ; Move to attribute byte
    mov byte [es:bx], 0x07 ; White on black
    inc bx              ; Move to next character position
    
    jmp print_vga_loop
    
handle_newline:
    ; Move to next line (80 characters per line, 2 bytes per character)
    mov ax, bx
    mov dx, 0
    mov cx, 160         ; 80 * 2 = 160 bytes per line
    div cx              ; AX = line number, DX = position in line
    inc ax              ; Next line
    mul cx              ; AX = start of next line
    mov bx, ax
    jmp print_vga_loop
    
print_vga_done:
    mov [cursor_pos], bx ; Save cursor position
    pop es
    pop bx
    pop ax
    ret

cursor_pos dw 0         ; Current cursor position



boot_drive db 0
disk_error_msg db "Disk error!", 0
disk_success_msg db "Disk read", 0
protected_mode_msg db "32b mode", 0

times 510 - ($ - $$) db 0
dw 0xAA55