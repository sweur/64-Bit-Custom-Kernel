
[org 0x8000]
[bits 64]
jmp kernel_start
CODE64_SEG equ 8
lidt [idt_descriptor]

idt_start:
    times 256*16 db 0
idt_end:

keyboard_handler:
    ; (later: we'll read the actual key here)

    mov al, 0x20
    out 0x20, al        ; tell the PIC "interrupt handled"

    iretq

idt_descriptor:
    dw idt_end - idt_start - 1
    dd idt_start

kernel_start:
    mov rsi, message
.serial_loop:
    mov al, [rsi]
    cmp al, 0
    je .vga_output
    mov dx, 0x3F8
    out dx, al
    inc rsi
    jmp .serial_loop

.vga_output:
    mov rdi, 0xB8000
    mov ah, 0x0F
    mov al, ' '
    mov rcx, 80*25
.clear_loop:
    mov [rdi], al
    mov [rdi+1], ah
    add rdi, 2
    loop .clear_loop

    mov rdi, 0xB8000        ; VGA text buffer: each char = 2 bytes (ascii, color)
    mov rsi, message
    mov ah, 0x0F            ; color byte: white text on black background

.print_loop:
    mov al, [rsi]           ; load next character
    cmp al, 0
    je .halt
    mov [rdi], al            ; write the character byte
    mov [rdi+1], ah          ; write the color byte
    add rdi, 2
    inc rsi
    jmp .print_loop

.halt:
    cli
.hang:
    hlt                      ; halt CPU until next interrupt (we disabled them, so: forever)
    jmp .hang

message: db "Hello from my own 64-bit kernel!", 0
