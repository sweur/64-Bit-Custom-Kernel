[bits 32]
global kernel_main

kernel_main:
    mov edi, 0xB8000
    mov esi, msg
    mov ah, 0x0F
.loop:
    mov al, [esi]
    cmp al, 0
    je .vga_done
    mov [edi], al
    mov [edi+1], ah
    add edi, 2
    inc esi
    jmp .loop
.vga_done:
    ; also confirm via serial, for headless verification
    mov esi, msg
.serial_loop:
    mov al, [esi]
    cmp al, 0
    je .done
    mov dx, 0x3F8
    out dx, al
    inc esi
    jmp .serial_loop
.done:
    ret

msg: db "Hello from GRUB-booted kernel!", 0
