section .bss
        char_disp: resb 8

section .text
global _start

; Prints message on rcx, with length on rdx
print:
        push rax
        push rdi

        mov rax, 1
        mov edi, 1
        syscall

        pop rdi
        pop rax
        ret

style:
        push rdx
        push rsi
        push rax

        mov rdx, 2
        mov rsi, CSI
        call print

        mov rdx, 1
        add rax, 48
        mov qword [ char_disp ], rax
        mov rsi, char_disp
        call print

        mov qword [ char_disp ], 'm'
        mov rsi, char_disp
        call print

        pop rax
        pop rsi
        pop rdx
        ret

; Move the cursor to X at rax, and Y to rbx
move_cursor:
        mov rdx, 1
        mov rcx, CSI
        call print

        add rax, 49
        mov rcx, rax
        call print

        mov rcx, COLUMN
        call print

        add rbx, 49
        mov rcx, rbx
        call print

        mov rcx, LET_H
        call print

        ret

_start:
        ; mov rdx, len
        ; mov rcx, msg
        ; call print

        mov rax, 7
        call style

        mov rdx, len
        mov rsi, msg
        call print

        mov rax, 0
        call style

        mov rdx, len
        mov rsi, msg
        call print

        mov rax, 1
        mov rbx, 0
        int 80h

section .data
        msg db "Hello world!", 0Dh, 0Ah
        len equ $ - msg

        CSI db 0x1b, '['
        COLUMN db ";"
        LET_H db "H"
        LETTER_m db "m"
        LET_1 db "1"
