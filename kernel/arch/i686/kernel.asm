[bits 32]
global _start

extern kmain

CODE_SEG equ 0x08
DATA_SEG equ 0x10

_start:
    mov ax, DATA_SEG
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    ; setting up stack
    mov ebp, 0x00200000
    mov esp, ebp

    ; fast a20 enable
    ;in al, 0x92
    ;or al, 2
    ;out 0x92, al

    ; enabling the a20 line
    call check_a20

    cmp eax, 0
    je start_kernel

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

    call check_a20
    cmp eax, 0

    jne error

    jmp start_kernel

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


start_kernel:

    ; set up pic stuff

    ; disable interrupts until we set up our idt
    cli

    ; call our beautiful beautiful C code
    call kmain

    jmp $

; make this print something informative to the screen
error:
    ; call extern term_print routine
    hlt

times 512 - ($ - $$) db 0