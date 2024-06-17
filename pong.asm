%include 'display.asm'

section .bss
        char_disp: resb 8

section .text
global _start

_start:
        mov rax, 11000
        call print_number
        ; ; Reverse
        ; mov rax, 7
        ; call style

        ; ; Print Hello world!
        ; mov rdx, len
        ; mov rsi, msg
        ; call print

        ; ; Move the cursor to 9;2
        ; mov rax, 9
        ; mov rbx, 2
        ; call move_cursor

        ; ; Reset the style
        ; mov rax, 0
        ; call style

        ; ; Print again hello world!
        ; mov rdx, len
        ; mov rsi, msg
        ; call print

        ; Syscall exit
        mov rax, 60
        mov rdi, 0
        syscall

section .data
        msg db "Hello world!", 0Dh, 0Ah
        len equ $ - msg
