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
        iret

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

        call ok

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
;         .handler db 4
;         .sa_flags db 4
;         .sa_restorer db 4
;         .sa_mask db 4
; ENDSTRUC

; STRUC itimerspec
;         .it_inter_sec db 4
;         .it_inter_nsec db 4
;         .it_value_sec db 4
;         .it_value_nsec db 4
; ENDSTRUC

section .bss
        timerid resd 1

section .data
        clockid dd 0x1               ; CLOCK_REALTIME (0)
        ; timerid dd 0                 ; Buffer to store the timer ID

data_sigevent:
        sigev_value dq 0             ; Value to pass to handler
        sigev_signo dd 10            ; SIGALRM (14) or SIGUSR1 (10)
        sigev_notify dd 1            ; SIGEV_SIGNAL (1)
        padding dq 0, 0, 0, 0, 0, 0
        data_sigevent_len equ $ - data_sigevent

itimerspec:
        it_interval_sec dq 0
        it_interval_nsec dq 0
        it_value_sec dq 0
        it_value_nsec dq 0

section .rodata
        errmsg db "An error occured: ", 0Dh, 0Ah
        errmsg_len equ $ - errmsg
