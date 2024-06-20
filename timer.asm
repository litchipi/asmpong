section .text

wait_forever:
        push rax
        push rdx
        push rsi

        ; Pause syscall, wait for new signals
        mov rax, 34
        syscall

        cmp byte [ ASK_EXIT ], 1
        jl wait_forever

        pop rsi
        pop rdx
        pop rax
        ret

ask_exit:
        mov byte [ ASK_EXIT ], 1
        ret

; Signal handler for SIGALRM
sighandler:
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

        ; rt_sigaction
        mov qword [ sa_handler ], rcx
        mov rax, 13
        mov rdi, [ sigev_signo ]
        mov rsi, sa
        mov rdx, 0
        mov r10, 8
        syscall

        cmp rax, 0
        jl raise_error

        ; timer_create
        mov rax, 222
        mov rdi, [ clockid ]
        mov rsi, [ sigevent ]
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

        pop rsi
        pop rdi
        pop rdx
        pop r9
        pop r8
        ret

sa_restorer_fct:
        mov rax, 15
        syscall

section .data
        clockid dd 0x0               ; CLOCK_REALTIME (0)
        timerid dd 0                 ; Buffer to store the timer ID
        ASK_EXIT db 0

sigevent:
        sigev_value dq 0             ; Value to pass to handler
        sigev_signo dd 14
        sigev_notify dd 1            ; SIGEV_SIGNAL (1)
        sigev_padding dq 6 dup(0)

itimerspec:
        it_interval_sec dq 0
        it_interval_nsec dq 0
        it_value_sec dq 0
        it_value_nsec dq 0

sa:
        sa_handler dq sighandler
        sa_flags dd 0x04000000
        padding dd 0
        sa_restorer dq sa_restorer_fct
        sa_mask dq 0
