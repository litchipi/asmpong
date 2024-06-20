%include 'timer.asm'
%include 'terminal.asm'

section .bss
        char_inp: resb 1

section .data
        ball: db 5, 15        ; [ y, x ]
        direction: db 1, 0    ; [ horiz, vert ] -> [ E=1 / W=0, S=1 / N=0 ]
        bar_left: db 1
        bar_right: db 5

section .rodata
        SCREEN_REFRESH_SEC equ 0
        ;                       _ms_us_ns
        SCREEN_REFRESH_NSEC equ  20000000 ; 20 ms

        SCREEN_DRAW_Y_START equ 4
        SCREEN_WIDTH equ 140
        SCREEN_HEIGHT equ 40

        BAR_SIZE equ 6

        EMPTY_CHAR db " "
        BAR_CHAR db "█"
        BALL_CHAR db '⬤'
        WALL_CHAR dd "─"

        EXIT_CHAR equ 'q'
        USR1_UP_CHAR equ 'z'
        USR1_DOWN_CHAR equ 's'
        USR2_UP_CHAR equ 'p'
        USR2_DOWN_CHAR equ 'm'

section .text
global _start

usr1_up:
        dec byte [ bar_left ]
        ret

usr1_down:
        inc byte [ bar_left ]
        ret

usr2_up:
        dec byte [ bar_right ]
        ret

usr2_down:
        inc byte [ bar_right ]
        ret

react_input:
        cmp byte [ char_inp ], USR1_UP_CHAR
        je usr1_up

        cmp byte [ char_inp ], USR1_DOWN_CHAR
        je usr1_down

        cmp byte [ char_inp ], USR2_UP_CHAR
        je usr2_up

        cmp byte [ char_inp ], USR2_DOWN_CHAR
        je usr2_down
        ret

get_input:
        push rax
        push rdi
        push rsi
        push rdx

        ; Read on stdinp
        mov rax, 0
        mov rdi, 0
        mov rsi, char_inp
        mov rdx, 1
        syscall

        cmp byte [ char_inp ], EXIT_CHAR
        je exit_program

        call react_input
        mov byte [ char_inp ], ' '

        pop rdx
        pop rsi
        pop rdi
        pop rax
        ret

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

bounce_x:
        push rax
        mov rax, 1
        sub rax, [ direction ]
        mov byte [ direction ], al
        pop rax
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

test_touches_left:
        call bounce_x
        ; TODO        Test if touches bar or not
        ; Then create reaction based on it
        ret

test_touches_right:
        call bounce_x
        ; TODO        Test if touches bar or not
        ; Then create reaction based on it
        ret

update_game:
        call update_ball_position

        ; If ball touches top of screen
        push detect_left_edge
        cmp byte [ ball ], 1
        je bounce_y
        pop rax

        ; If ball touches bottom of screen
        push detect_left_edge
        cmp byte [ ball ], (SCREEN_HEIGHT - 1)
        je bounce_y
        pop rax

detect_left_edge:
        ; If ball touches left of screen
        push detect_right_edge
        cmp byte [ ball + 1 ], 1
        je test_touches_left
        pop rax

detect_right_edge:
        ; If ball touches right of screen
        cmp byte [ ball + 1 ], (SCREEN_WIDTH - 1)
        je test_touches_right
        ret

draw_wall:
        dec rax

        mov rdx, 3
        mov rsi, WALL_CHAR
        call print

        cmp rax, 1
        jge draw_wall
        ret

draw_bar:
        push r8
        push rdx
        push rsi

        mov rdx, 3
        mov rsi, BAR_CHAR
        mov r8, BAR_SIZE
draw_bar_loop:
        call move_cursor
        call print

        inc rax
        dec r8
        cmp r8, 1
        jge draw_bar_loop

        pop rsi
        pop rdx
        pop r8
        ret

draw_ball:
        push rax
        push rdx
        push rsi

        mov rax, 0
        mov rax, SCREEN_DRAW_Y_START
        add al, [ ball ]
        mov rbx, 0
        mov bl, [ ball + 1 ]
        call move_cursor

        mov rdx, 4
        mov rsi, BALL_CHAR
        call print

        pop rsi
        pop rdx
        pop rax
        ret

draw_top_bar:
        push rax

        mov rax, 0
        mov al, [ ball ]
        call erase_line
        call print_number
        call newline

        mov rax, 0
        mov al, [ ball + 1]
        call erase_line
        call print_number
        call newline

        mov rdx, 1
        mov rsi, char_inp
        call print
        call newline

        pop rax
        ret

draw_screen:
        call draw_top_bar

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
        call draw_ball

        ; Draw the left bar
        mov al, [ bar_left ]
        add rax, SCREEN_DRAW_Y_START
        mov rbx, 1 ;[ bar_left ]
        call draw_bar

        ; Draw the right bar
        mov al, [ bar_right ]
        add rax, SCREEN_DRAW_Y_START
        mov rbx, SCREEN_WIDTH
        call draw_bar

        ret

erase_prev_screen:
        mov rax, 0
        mov rax, SCREEN_DRAW_Y_START
        add al, [ ball ]
        mov rbx, 0
        mov bl, [ ball + 1 ]
        call move_cursor
        mov rdx, 1
        mov rsi, EMPTY_CHAR
        call print
        ret

timer_handler:
        call erase_prev_screen
        mov rax, 1
        mov rbx, 1
        call move_cursor
        call get_input
        call update_game
        call draw_screen
        ret

_start:
init_game:
        call clear
        call reset
        call hide_cursor
        call enable_raw_mode
        mov rax, SCREEN_REFRESH_SEC
        mov rbx, SCREEN_REFRESH_NSEC
        mov rcx, timer_handler
        call start_timer
        call wait_forever

exit_program:
        call restore_term
        call clear

        ; Syscall exit
        mov rax, 60
        mov rdi, 0
        syscall
