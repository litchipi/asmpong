%include 'display.asm'

section .bss
        char resb 1

section .text
global _start

_start:
        call set_non_blocking
        call enable_raw_mode
loop:
        call ok

        ; getch
        mov rax, 0
        mov rdi, 0
        mov rsi, char
        mov rdx, 1
        syscall

        cmp rax, 0
        jl raise_error

        jmp loop
