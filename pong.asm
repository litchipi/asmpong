%include 'timer.asm'
%include 'display.asm'

section .data
        ball: db 5, 15        ; [ y, x ]
        direction: db 1, 0    ; [ horiz, vert ] -> [ E=1 / W=0, S=1 / N=0 ]

section .rodata
        SCREEN_REFRESH_SEC equ 0
        SCREEN_REFRESH_NSEC equ 50000000         ; 200 ms

        SCREEN_DRAW_Y_START equ 3
        SCREEN_WIDTH equ 140
        SCREEN_HEIGHT equ 40

        BALL_CHAR db 'x'
        WALL_CHAR db "#"

section .text
global _start

update_position:
        cmp rax, 1
        jl update_position_negative
update_position_positive:
        inc rbx
        ret
update_position_negative:
        dec rbx
        ret

bounce_y:
        push rax
        mov rax, 1
        sub rax, [ direction + 1 ]
        mov byte [ direction + 1 ], al
        pop rax
        ret
update_ball_direction:
        cmp byte [ ball ], 1
        je bounce_y
        cmp byte [ ball ], (SCREEN_HEIGHT - 1)
        je bounce_y
        ret

update_ball_position:
        ; Update x
        mov al, [ direction + 1 ]
        mov bl, [ ball ]
        call update_position
        mov byte [ ball ], bl

        ; Update y
        mov al, [ direction ]
        mov bl, [ ball + 1 ]
        call update_position
        mov byte [ ball + 1], bl
        ret

bounce_x:
        push rax
        mov rax, 1
        sub rax, [ direction ]
        mov byte [ direction ], al
        pop rax
        ret
test_ball_touches_bar:
        ; TODO        Conditionnal if the bar is there
        cmp byte [ ball + 1 ], 1
        je bounce_x
        cmp byte [ ball + 1 ], (SCREEN_WIDTH - 1)
        je bounce_x
        ret

update_game:
        call update_ball_direction
        call test_ball_touches_bar
        call update_ball_position
        ret

draw_wall:
        dec rax

        mov rdx, 1
        mov rsi, WALL_CHAR
        call print

        cmp rax, 1
        jge draw_wall
        ret

draw_screen:
        call clear
        mov rax, 0
        mov al, [ ball ]
        call print_number
        call newline

        mov rax, 0
        mov al, [ ball + 1]
        call print_number
        call newline


        ; Draw top wall
        mov rax, SCREEN_DRAW_Y_START
        mov rbx, 1
        call move_cursor
        mov rax, SCREEN_WIDTH
        call draw_wall

        ; Draw bottom wall
        mov rax, SCREEN_DRAW_Y_START + SCREEN_HEIGHT
        mov rbx, 1
        call move_cursor
        mov rax, SCREEN_WIDTH
        call draw_wall

        ; Draw the ball
        mov rax, 0
        mov rax, SCREEN_DRAW_Y_START
        add al, [ ball ]
        mov rbx, 0
        mov bl, [ ball + 1 ]
        call move_cursor
        mov rdx, 1
        mov rsi, BALL_CHAR
        call print

        ret

timer_handler:
        call update_game
        call draw_screen
        ret

_start:
init_game:
        call reset
        call hide_cursor
        mov rax, SCREEN_REFRESH_SEC
        mov rbx, SCREEN_REFRESH_NSEC
        mov rcx, timer_handler
        call start_timer
        call wait_forever
exit_program:
        call reset
        call clear

        ; Syscall exit
        mov rax, 60
        mov rdi, 0
        syscall
