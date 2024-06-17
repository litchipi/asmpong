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

; Prints each digits of a number in ASCII
; Number in rax
; TODO   FIXME        IMPORTANT        Fix big number display
print_number:
        mov r8, 0
print_number_loop:
        add r8, 1
        mov edx, 0

        mov ecx, 0x10
        div ecx

        push rdx
        cmp eax, 10
        jge print_number_loop
        mov edx, 1
print_number_loop_end:
        pop rax
        add eax, 48
        mov qword [ char_disp ], rax
        mov esi, char_disp
        call print
        sub r8, 1
        cmp r8, 1
        jge print_number_loop_end
        mov rdx, 2
        mov rsi, NEWLINE
        call print
        ret


; Sets the style of next messages using ANSI codes
; TODO IMPORTANT            Make codes > 10 possible with better numbering management
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
        mov rdx, 2
        mov rsi, CSI
        call print

        mov rdx, 1
        add rbx, 48
        mov qword [ char_disp ], rbx
        mov rsi, char_disp
        call print

        mov qword [ char_disp ], ';'
        mov rsi, char_disp
        call print

        add rax, 48
        mov qword [ char_disp ], rax
        mov rsi, char_disp
        call print

        mov qword [ char_disp ], 'H'
        mov rsi, char_disp
        call print

        ret

section .data
        CSI db 0x1b, '['
        NEWLINE db 0Dh, 0Ah
