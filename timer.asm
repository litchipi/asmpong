section .text

; Signal handler for SIGALRM
sighandler:
        push rax
        mov rax, 45
        call print_number
        push rbx
        push rcx
        push rdx

        ; Call the callback function
        ; TODO        Get it from the sigev_value arg

        pop rdx
        pop rcx
        pop rbx
        pop rax
        ret

set_sigev_mask:
        push rbx
        push r8
        mov bl, [ sigev_signo ]

        mov rax, 1
set_sigev_mask_loop:
        dec rbx
        shl rax, 1

        cmp rbx, 1
        jge set_sigev_mask_loop

        pop r8
        pop rbx
        ret

; Start a timer of N secs (N stored in rax)
;  rax stores the number of seconds
;  rbx stores the number of nanoseconds
;  rcx stores the handler
start_timer:
        push r8
        push r9
        push rdx
        push rdi
        push rsi

        mov r8, rax
        mov r9, rbx

        ; timer_create
        mov rax, 222
        mov rdi, [ clockid ]
        mov qword [ sigev_value ], sighandler
        mov rsi, data_sigevent
        mov rdx, timerid
        syscall                      ; Call kernel

        cmp rax, 0
        jl raise_error

        ; timer_settime
        mov rax, 223
        mov rdi, [ timerid ]
        mov rsi, 0
        mov [ it_interval_sec ], r8
        mov [ it_value_sec ], r8
        mov [ it_interval_nsec ], r9
        mov [ it_value_nsec ], r9
        mov rdx, itimerspec
        mov r10, 0
        syscall

        cmp rax, 0
        jl raise_error

        ; rt_sigaction
        call set_sigev_mask
        mov [ sa_mask ], rax

        mov rax, 13
        ; TODO        Figure out these arguments till they are OK
        mov rdi, [ sigev_signo ]
        mov rsi, [ sigaction ]
        mov rdx, 0
        mov r10, 8
        syscall

        cmp rax, 0
        jl raise_error
        call ok

        pop rsi
        pop rdi
        pop rdx
        pop r9
        pop r8
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

; STRUC sa_struct
; ENDSTRUC

; STRUC itimerspec
;         .it_inter_sec db 4
;         .it_inter_nsec db 4
;         .it_value_sec db 4
;         .it_value_nsec db 4
; ENDSTRUC

section .data
        clockid dd 0x1               ; CLOCK_REALTIME (0)
        timerid dd 0                 ; Buffer to store the timer ID

data_sigevent:
        sigev_value dq 0             ; Value to pass to handler
        sigev_signo dd 10            ; SIGALRM (14) or SIGUSR1 (10)
        sigev_notify dd 1            ; SIGEV_SIGNAL (1)
        sigev_padding dq 6 dup(0)

itimerspec:
        it_interval_sec dq 0
        it_interval_nsec dq 0
        it_value_sec dq 0
        it_value_nsec dq 0

sigaction:
        sa_handler dq sighandler
        sa_mask db 128 dup(0)
        sa_flags dd 0
        sa_pad dd 0
        sa_restorer dq 0

section .rodata
        errmsg db "An error occured: ", 0Dh, 0Ah
        errmsg_len equ $ - errmsg
