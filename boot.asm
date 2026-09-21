; ============================================================
; boot.asm — MBR bootloader
; BIOS loads this at physical address 0x7C00 and jumps to it.
; Job: load the kernel off disk, then climb from 16-bit real mode
; all the way up to 64-bit long mode, then jump into the kernel.
; ============================================================

[org 0x7C00]
[bits 16]

start:
    cli                     ; disable interrupts while we mess with segments
    xor ax, ax
    mov ds, ax              ; DS = 0
    mov es, ax              ; ES = 0
    mov ss, ax              ; SS = 0
    mov sp, 0x7C00          ; stack grows down from just below us
    sti

    mov [BOOT_DRIVE], dl    ; BIOS puts the boot drive number in DL — save it

    mov si, msg_start
    call print16

    ; ---- Load the kernel from disk into memory at 0x8000 ----
    ; The kernel is written right after this boot sector on disk,
    ; starting at sector 2 (sector 1 is this bootloader).
    mov bx, 0x8000          ; load destination: ES:BX = 0x0000:0x8000
    mov dh, 32               ; number of sectors to read (32 * 512 = 16KB, plenty for now)
    mov dl, [BOOT_DRIVE]
    call disk_load

    mov si, msg_loaded
    call print16

    ; ---- Enable the A20 line ----
    ; Old x86 wrapped memory addresses above 1MB by default (a legacy quirk).
    ; We need full addressing, so we turn that off via the fast A20 method.
    in al, 0x92
    or al, 2
    out 0x92, al

    ; ---- Load a 32-bit GDT and enter protected mode ----
    lgdt [gdt32_descriptor]
    mov eax, cr0
    or eax, 1                ; set PE (Protection Enable) bit
    mov cr0, eax

    jmp CODE32_SEG:protected_mode_start  ; far jump flushes the CPU pipeline & loads CS

[bits 32]
protected_mode_start:
    mov ax, DATA32_SEG
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, 0x90000

    ; ---- Set up paging for long mode ----
    ; Long mode REQUIRES paging to be on. We build a minimal identity map
    ; (virtual address == physical address) covering the first 2MB using
    ; one PML4 entry -> one PDPT entry -> one PD entry with the "huge page" bit,
    ; so we don't need a full 4KB page table at all.

    ; Zero out the page table area (0x1000 - 0x4000) first
    mov edi, 0x1000
    mov cr3, edi
    xor eax, eax
    mov ecx, 4096
    rep stosd
    mov edi, cr3

    mov dword [edi], 0x2000 | 3
    add edi, 0x1000
    mov dword [edi], 0x3000 | 3
    add edi, 0x1000
    mov dword [edi], 0x0 | 0x83

    mov eax, cr4
    or eax, 1 << 5           ; PAE bit
    mov cr4, eax

    mov ecx, 0xC0000080      ; EFER MSR number
    rdmsr
    or eax, 1 << 8           ; LME bit
    wrmsr

    mov eax, cr0
    or eax, 1 << 31          ; PG bit
    mov cr0, eax

    lgdt [gdt64_descriptor]
    jmp CODE64_SEG:long_mode_start

[bits 64]
long_mode_start:
    mov ax, DATA64_SEG
    mov ds, ax
    mov es, ax
    mov ss, ax

    ; Kernel was loaded at 0x8000
    jmp 0x8000

; ============================================================
; disk_load — reads DH sectors from drive DL into ES:BX
; (16-bit real mode BIOS disk service, CHS addressing)
; ============================================================
[bits 16]
disk_load:
    push dx
    mov ah, 0x02        ; BIOS "read sectors" function
    mov al, dh          ; number of sectors to read
    mov ch, 0x00         ; cylinder 0
    mov dh, 0x00         ; head 0
    mov cl, 0x02         ; start reading from sector 2 (sector 1 = this bootloader)
    int 0x13
    jc disk_error        ; carry flag set = BIOS reported an error
    pop dx
    cmp al, dh
    jne disk_error
    ret

disk_error:
    mov si, msg_disk_err
    call print16
    jmp $

print16:
    pusha
.loop:
    lodsb
    or al, al
    jz .done
    mov ah, 0x0E
    int 0x10
    jmp .loop
.done:
    popa
    ret

BOOT_DRIVE: db 0
msg_start:    db "Booting...", 13, 10, 0
msg_loaded:   db "Kernel loaded, entering protected mode...", 13, 10, 0
msg_disk_err: db "Disk read error!", 13, 10, 0

; ============================================================
; GDTs — Global Descriptor Tables. The CPU needs one of these
; to know what memory segments exist before it'll run 32-bit
; or 64-bit code. In flat setups like this, each segment just
; covers the whole address space.
; ============================================================
align 8
gdt32_start:
    dq 0x0000000000000000              ; null descriptor (required)
CODE32_SEG equ $ - gdt32_start
    dw 0xFFFF, 0x0000
    db 0x00, 10011010b, 11001111b, 0x00
DATA32_SEG equ $ - gdt32_start
    dw 0xFFFF, 0x0000
    db 0x00, 10010010b, 11001111b, 0x00
gdt32_end:

gdt32_descriptor:
    dw gdt32_end - gdt32_start - 1
    dd gdt32_start

align 8
gdt64_start:
    dq 0x0000000000000000
CODE64_SEG equ $ - gdt64_start
    dw 0, 0
    db 0, 10011010b, 00100000b, 0    ; L-bit (long mode) set, no size/gran needed
DATA64_SEG equ $ - gdt64_start
    dw 0, 0
    db 0, 10010010b, 0, 0
gdt64_end:

gdt64_descriptor:
    dw gdt64_end - gdt64_start - 1
    dd gdt64_start

; ---- Boot sector padding + magic number ----
; A boot sector MUST be exactly 512 bytes and end in 0xAA55,
; or the BIOS won't recognize it as bootable.
times 510-($-$$) db 0
dw 0xAA55
