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
        push rax
        push rbx
        push rcx

        ; Create a timer
        mov [ sigev_value ], rcx
        mov rax, 222
        mov rdi, [ clockid ]
        mov rsi, [ data_sigevent ]
        mov rdx, [ timerid ]
        syscall                      ; Call kernel

        mov rax, rdx
        call print_number

        ; lea rdi, [clockid]           ; CLOCK_REALTIME (0)
        ; lea rsi, [sigevent]          ; Pointer to sigevent structure
        ; lea rdx, [timerid]           ; Pointer to store timer ID
        ; mov rax, 222                 ; sys_timer_create syscall number

        ; ; Set the timer
        ; mov rdi, [timerid]           ; Timer ID
        ; mov rsi, 0                   ; No flags
        ; lea rdx, [itimerspec]        ; Pointer to itimerspec structure
        ; mov r10, 0                   ; Old itimerspec (optional, not used)
        ; mov rax, 223                 ; sys_timer_settime syscall number
        ; syscall                      ; Call kernel

        pop rcx
        pop rbx
        pop rax
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
        timerid dw 0                 ; Buffer to store the timer ID

data_sigevent:
        sigev_notify dd 1            ; SIGEV_SIGNAL (1)
        sigev_signo dd 14            ; SIGALRM (14)
        sigev_value dd 0
        sigev_notify_function dd sighandler
        sigev_notify_attributes dd 0
        sigev_notify_thread_id dd 0
