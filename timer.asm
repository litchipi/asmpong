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

        ; Create a timer
        mov [ sigev_value ], rcx
        mov rax, 222
        mov rdi, [ clockid ]
        mov rsi, [ data_sigevent ]
        mov rdx, [ timerid ]
        syscall                      ; Call kernel

        mov rax, 223
        mov rdi, rdx
        mov rsi, 0
        mov [ it_interval_sec ], r8
        mov [ it_value_sec ], r8
        mov [ it_interval_nsec ], r9
        mov [ it_value_nsec ], r9
        mov rdx, [ itimerspec ]
        mov rdx, 0
        syscall

        mov rax, timerid
        call print_number

        pop rsi
        pop rdi
        pop rdx
        pop r9
        pop r8
        ret

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

section .data
        clockid dd 0x0               ; CLOCK_REALTIME (0)
        timerid dd 0                 ; Buffer to store the timer ID

data_sigevent:
        sigev_notify dd 1            ; SIGEV_SIGNAL (1)
        sigev_signo dd 14            ; SIGALRM (14)
        sigev_value dd 0
        sigev_notify_function dd sighandler
        sigev_notify_attributes dd 0
        sigev_notify_thread_id dd 0

itimerspec:
        it_interval_sec dq 0
        it_interval_nsec dq 0
        it_value_sec dq 0
        it_value_nsec dq 0
