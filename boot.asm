; boot.asm

[ORG 0x7C00]
[BITS 16]

global _start

_start:
    cli 
    lgdt [gdt_desc]
    mov eax, cr0
    or eax, 1
    mov cr0, eax
    jmp CODE_SEG:protected_mode

gdt_start:
    null_desc:
        dd 0
        dd 0
    code_desc:
        dw 0xFFFF             ; limit low
        dw 0x0000             ; base low
        db 0x00               ; base middle
        db 0x9A               ; access byte
        db 0xCF               ; granularity
        db 0x00               ; base high
    data_desc:
        dw 0xFFFF             ; limit low
        dw 0x0000             ; base low
        db 0x00               ; base middle
        db 0x92               ; access byte
        db 0xCF               ; granularity
        db 0x00               ; base high
gdt_end:

gdt_desc:
    dw gdt_end - gdt_start - 1 ; size
    dd gdt_start               ; start

CODE_SEG equ 0x08
DATA_SEG equ 0x10

disk_load:
    pusha
.load_sector:
    mov eax, edi           ; current address
    push ecx
    call lba_to_chs

    mov ah, 0x02           ; function: read sectors
    mov al, 1              ; sectors to read
    mov ch, byte [track]
    mov cl, byte [sector]
    mov dh, byte [head]
    mov dl, 0x00           ; boot device
    mov bx, di             ; offset in ES:BX
    shr edi, 4
    mov es, di
    shl edi, 4

    int 0x13
    jc disk_error

    add edi, 512
    loop .load_sector
    pop ecx
    popa
    ret

disk_error:
    hlt
    jmp disk_error

lba_to_chs:
    ; Very simple LBA→CHS conversion for CHS-mode disks
    ; Assumes 18 sectors/track, 2 heads, 80 cylinders (standard 1.44MB)
    xor dx, dx
    mov ax, cx             ; sector number
    mov si, 18             ; sectors per track
    div si
    mov [track], al
    inc ah
    mov [sector], ah
    xor dx, dx
    mov ax, dx
    mov si, 2              ; heads
    div si
    mov [head], al
    ret

track db 0
sector db 0
head db 0


hang:
    jmp hang

[BITS 32]
protected_mode:
    mov ax, DATA_SEG
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    mov esp, 0x90000
    mov ebp, esp      ; Optional but helpful in C

    ; Load kernel from disk
    mov esi, 0x100000      ; Load address for kernel
    mov edi, esi

    mov ecx, 10            ; Number of sectors to read
    call disk_load

    ; Jump to kernel
    jmp 0x100000


times 510 - ($ - $$) db 0
dw 0xAA55