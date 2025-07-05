; boot.asm
BITS 16
ORG 0x7C00

start:
    mov si, msg       ; point SI to the message

print_loop:
    lodsb             ; load byte at [SI] into AL and increment SI
    cmp al, 0
    je done           ; if zero byte, done printing
    mov ah, 0x0E      ; BIOS teletype function
    int 0x10          ; print character in AL
    jmp print_loop

done:
    cli
    hlt

msg db 'Hi', 0

; Pad the rest of the 512-byte sector with zeros
times 510-($-$$) db 0
dw 0xAA55           ; Boot signature

