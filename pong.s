.global _start
.intel_syntax noprefix

_start:
        /* Exit */
        mov rax, 60
        mov rdi, 0
        syscall
