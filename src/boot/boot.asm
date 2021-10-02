; This file is part of Simplix.
; It is part of the bootloader that starts the system.

; Currently, this file:
; - Sets the GDT
; - Enters protected mode
; - Enables the A20 line

org 0x7c00
[bits 16]

; defining our gdt offsets
CODE_SEG equ gdt_code - gdt_start
DATA_SEG equ gdt_data - gdt_start

_start:
    jmp short start
    nop

; bios boot partition
times 33 db 0

start:
    jmp 0:start2

start2:
    cli ; clear interrupts

    ;todo: add checking for wrong bootdrives

    ; load the segment into gpr ax
    mov ax, 0x00
    ; load the data and extra segment with ax (0x7c0)
    mov ds, ax
    mov es, ax

    ; set the stack segment to 0
    ;mov ax, 0x00
    ;mov ss, ax

    ; set the stack pointer to 7c00h
    mov sp, 0x7c00

    sti ; re-enable interrupts

.load_protected:
    cli
    lgdt [gdt_desc]

    ; enabling protection enable bit in cr0
    mov eax, cr0
    or eax, 0x1
    mov cr0, eax

    ; jump to our 32 bit code
    jmp CODE_SEG:load32

%include "./src/boot/gdt.asm"

[bits 32]
load32:
    mov ax, DATA_SEG
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    ; setting up stack
    mov ebp, 0x00200000
    mov esp, ebp

    call check_a20

    cmp eax, 0
    je .loop

.enable_a20:
    cli

    call .a20_wait
    mov al, 0xad
    out 0x64, al

    call .a20_wait
    mov al, 0xd0
    out 0x64, al

    call .a20_wait2
    in al, 0x60
    push eax

    call .a20_wait
    mov al, 0xd1
    out 0x64, al

    call .a20_wait
    pop eax
    or al, 2
    out 0x60, al

    call .a20_wait
    mov  al,0xAE
    out  0x64,al
 
    call .a20_wait
    sti

    jmp .loop

.loop:
    jmp $

.a20_wait:
    in      al,0x64
    test    al,2
    jnz     .a20_wait
    ret

.a20_wait2:
    in      al,0x64
    test    al,1
    jz      .a20_wait2
    ret

check_a20:
    pushad

    ; test whether stuff gets written to the same address
    mov edi, 0x112345
    mov esi, 0x012345
    mov [esi], esi
    mov [edi], edi
    cmpsd
    popad

    ; if not equal, A20 is enabled, return 0
    jne .a20_on

    ; else, a20 is enabled, return 1
    mov eax, 1
    ret
.a20_on:
    mov eax, 0
    ret


times 510 - ($ - $$) db 0
dw 0xaa55

buffer: