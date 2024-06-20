section .bss
        char_disp: resb 1

        old_term_cfg resb 60
        new_term_cfg resb 60

        flags resd 1

section .rodata
        errmsg db "An error occured: ", 0Dh, 0Ah
        errmsg_len equ $ - errmsg

section .text

; Prints message on rcx, with length on rdx
print:
        push rax
        push rdi

        mov rax, 1
        mov edi, 1
        syscall

        cmp rax, 0
        jl raise_error

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

enable_raw_mode:
        push rax
        push rbx
        push rcx
        push rdx
        push rsi
        push rdi

        ; Save current config into old_term_cfg
        mov rax, 16
        mov rdi, 0
        mov rsi, IOCTL_TCGETS
        mov rdx, old_term_cfg
        syscall

        cmp rax, 0
        jl raise_error

        ; Copy 60 bytes of data from rsi to rdi
        lea esi, [old_term_cfg]
        lea edi, [new_term_cfg]
        mov ecx, 60
        rep movsb

        ; Modify the configuration of terminal
        lea eax, [new_term_cfg]
        ; Offset to c_lflag
        add eax, 12
        and byte [eax], 0xF5 ; Clear bit 1 and 3 -> disable ICANON and ECHO

        ; Set new settings
        mov rax, 16
        mov rdi, 0
        mov rsi, IOCTL_TCSETS
        lea rdx, [new_term_cfg]
        syscall

        cmp rax, 0
        jl raise_error

        pop rdi
        pop rsi
        pop rdx
        pop rcx
        pop rbx
        pop rax
        ret

set_non_blocking:
        push rax
        push rdi
        push rsi
        push rdx

        ; Get current file descriptor flags
        mov rax, 72 ; fcntl
        mov rdi, 0  ; stdin
        mov rsi, 3  ; F_GETFL
        mov rdx, flags
        syscall

        cmp rax, 0
        jl raise_error

        ; Save original flags
        mov [flags], eax

        ; Set file descriptor to non-blocking mode
        or rax, 0x800 ; Set the O_NONBLOCK bit
        mov rdx, rax
        mov rax, 72 ; fcntl
        mov rdi, 0
        mov rsi, 4 ; F_SETFL
        syscall

        cmp rax, 0
        jl raise_error

        pop rdx
        pop rsi
        pop rdi
        pop rax
        ret

restore_term:
        push rax
        push rbx
        push rcx
        push rdx

        call reset

        ; restore stdin flags (blocking)
        mov rax, 72 ; fcntl
        mov rdi, 0
        mov rsi, 4
        mov rdx, [ flags ]
        syscall

        ; restore terminal settings (canonical + echo)
        mov rax, 16 ; ioctl
        mov rdi, 0
        mov rsi, IOCTL_TCSETS
        lea rdx, [old_term_cfg]
        syscall

        call show_cursor

        pop rdx
        pop rcx
        pop rbx
        pop rax
        ret

; Error code on rax
raise_error:
        mov rdx, errmsg_len
        mov rsi, errmsg
        call print
        call print_negative_number
        call newline

        ; Syscall exit
        mov rdi, rax
        mov rax, 60
        syscall

section .data
        CSI db 0x1b, '['
        NEWLINE db 0Dh, 0Ah
        OK db "Ok", 0Dh, 0Ah

        IOCTL_TCGETS equ 0x5401
        IOCTL_TCSETS equ 0x5402
