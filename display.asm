section .bss
        char_disp: resb 1

section .text

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

; Prints each digits of a number in ASCII (arg in rax)
print_number:
        push r8
        push rdx
        push rcx
        push rsi
        push rax

        mov r8, 0
        cmp rax, 10
        jl print_number_loop_end
print_number_loop:
        inc r8
        mov rdx, 0

        mov ecx, 10
        div ecx

        push rdx
        cmp eax, 10
        jge print_number_loop
print_number_loop_end:
        inc r8
        push rax
print_number_ascii_print_loop:
        pop rdx

        add rdx, 48
        mov byte [ char_disp ], dl
        mov rsi, char_disp
        mov rdx, 1
        call print

        dec r8
        cmp r8, 1
        jge print_number_ascii_print_loop

        pop rax
        pop rsi
        pop rcx
        pop rdx
        pop r8

        ret

print_negative_number:
        push rdx
        push rsi
        push rbx

        mov rdx, 1
        mov byte [ char_disp ], '-'
        mov rsi, char_disp
        call print

        mov rbx, 0xffffffffffffffff
        sub rbx, rax
        mov rax, rbx
        inc rax
        call print_number

        pop rbx
        pop rsi
        pop rdx
        ret

; Sets the style of next messages using ANSI codes
; See https://en.wikipedia.org/wiki/ANSI_escape_code (SGR section)
; In rax, got the number of the style to apply
style:
        push rdx
        push rsi

        mov rdx, 2
        mov rsi, CSI
        call print

        call print_number

        mov byte [ char_disp ], 'm'
        mov rsi, char_disp
        call print

        pop rsi
        pop rdx
        ret

; Move the cursor to X at rax, and Y to rbx
move_cursor:
        push rdx
        push rsi
        push rax

        mov rdx, 2
        mov rsi, CSI
        call print

        call print_number

        mov byte [ char_disp ], ';'
        mov rsi, char_disp
        call print

        mov rax, rbx
        call print_number

        mov byte [ char_disp ], 'H'
        mov rsi, char_disp
        call print

        pop rax
        pop rsi
        pop rdx
        ret

hide_cursor:
        push rdx
        push rsi

        mov rdx, 2
        mov rsi, CSI
        call print

        mov rax, 1
        mov byte [ char_disp ], '?'
        mov rsi, char_disp
        call print

        mov rax, 25
        call print_number

        mov byte [ char_disp ], 'l'
        mov rsi, char_disp
        call print

        pop rsi
        pop rdx
        ret

show_cursor:
        push rdx
        push rsi

        mov rdx, 2
        mov rsi, CSI
        call print

        mov rax, 1
        mov byte [ char_disp ], '?'
        mov rsi, char_disp
        call print

        mov rax, 25
        call print_number

        mov byte [ char_disp ], 'h'
        mov rsi, char_disp
        call print

        pop rsi
        pop rdx
        ret

; Reset the style of the terminal
reset:
        push rax
        mov rax, 0
        call style
        pop rax
        ret

; Clears the screen of the terminal
clear:
        push rax
        push rbx
        push rdx
        push rsi

        mov rax, 1
        mov rbx, 1
        call move_cursor

        mov rdx, 2
        mov rsi, CSI
        call print

        mov rax, 2
        call print_number

        mov byte [ char_disp ], 'J'
        mov rsi, char_disp
        call print

        pop rsi
        pop rdx
        pop rbx
        pop rax
        ret

erase_line:
        push rax
        push rbx
        push rdx
        push rsi

        mov rdx, 2
        mov rsi, CSI
        call print

        mov rax, 2
        call print_number

        mov byte [ char_disp ], 'K'
        mov rsi, char_disp
        call print

        pop rsi
        pop rdx
        pop rbx
        pop rax

        ret

newline:
        push rdx
        push rsi

        mov rdx, 2
        mov rsi, NEWLINE
        call print

        pop rsi
        pop rdx
        ret

ok:
        push rdx
        push rsi

        mov rdx, 4
        mov rsi, OK
        call print

        pop rsi
        pop rdx
        ret

section .data
        CSI db 0x1b, '['
        NEWLINE db 0Dh, 0Ah
        OK db "Ok", 0Dh, 0Ah
