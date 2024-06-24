%include 'timer.asm'
%include 'terminal.asm'

section .bss
        char_inp: resb 1

section .data
        ball: db INIT_BALL_Y, INIT_BALL_X   ; [ y, x ]
        direction: db 0, 0    ; [ horiz, vert ] -> [ E=1 / W=0, S=1 / N=0 ]

        bar_left: db INIT_BAR_Y
        bar_right: db INIT_BAR_Y

        score_left: db 0
        score_right: db 0

section .rodata
        SCREEN_REFRESH_SEC equ 0
        ;                       _ms_us_ns
        SCREEN_REFRESH_NSEC equ  40000000 ; 40 ms

        SCREEN_DRAW_Y_START equ 4
        SCREEN_WIDTH equ 140
        SCREEN_HEIGHT equ 40
        INIT_BAR_Y equ (SCREEN_HEIGHT / 2) - (BAR_SIZE / 2)
        INIT_BALL_Y equ (SCREEN_HEIGHT / 2)
        INIT_BALL_X equ (SCREEN_WIDTH / 2)

        BAR_SIZE equ 10

        EMPTY_CHAR db " "
        BAR_CHAR db "█"
        BALL_CHAR db '⬤'
        WALL_CHAR dd "─"

        EXIT_CHAR equ 'q'
        USR1_UP_CHAR equ 'z'
        USR1_DOWN_CHAR equ 's'
        USR2_UP_CHAR equ 'p'
        USR2_DOWN_CHAR equ 'm'

        LEFT_MSG db "Player 1:"
        left_msg_len equ $ - LEFT_MSG

        RIGHT_MSG db "Player 2:"
        right_msg_len equ $ - RIGHT_MSG

section .text
global _start

; Function react_input
react_input:
; Left Up
        cmp byte [ char_inp ], USR1_UP_CHAR
        jnz react_usr1_down

        cmp byte [ bar_left ], 1
        jle react_finish

        dec byte [ bar_left ]

; Left Down
react_usr1_down:
        cmp byte [ char_inp ], USR1_DOWN_CHAR
        jnz react_usr2_up

        cmp byte [ bar_left ], ( SCREEN_HEIGHT - BAR_SIZE )
        jge react_finish

        inc byte [ bar_left ]

; Right Up
react_usr2_up:
        cmp byte [ char_inp ], USR2_UP_CHAR
        jnz react_usr2_down

        cmp byte [ bar_right ], 1
        jle react_finish

        dec byte [ bar_right ]

; Right Down
react_usr2_down:
        cmp byte [ char_inp ], USR2_DOWN_CHAR
        jnz react_finish

        cmp byte [ bar_right ], ( SCREEN_HEIGHT - BAR_SIZE )
        jge react_finish

        inc byte [ bar_right ]

react_finish:
        ret


; Ask the program to end, and return normally
ask_exit_program:
        call ask_exit
        jmp get_input_exit

; Function get_input
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
        je ask_exit_program

        call react_input
        mov byte [ char_inp ], ' '

get_input_exit:
        pop rdx
        pop rsi
        pop rdi
        pop rax
        ret


; Bounce the ball on the top and bottom bars
bounce_y:
        push rax
        mov rax, 1
        sub rax, [ direction + 1 ]
        mov byte [ direction + 1 ], al
        pop rax
        ret


; Update the position of the ball based on the direction passed in param
update_position:
        cmp rax, 1
        jl update_position_negative
update_position_positive:
        inc rbx
        ret
update_position_negative:
        dec rbx
        ret


; Update position of the ball based on direction of movement
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


; Bounce the ball on the side bars
bounce_x:
        push rax
        mov rax, 1
        sub rax, [ direction ]
        mov byte [ direction ], al
        pop rax
        ret


; Function test if ball touches the left bar
test_touches_left:
        push rax
        push rbx

        mov al, byte [ ball ]
        cmp al, byte [ bar_left ]
        jl touch_left_right_win

        mov bl, byte [ bar_left ]
        add bl, BAR_SIZE
        cmp al, bl
        jg touch_left_right_win

        call bounce_x
        jmp touch_left_exit

touch_left_right_win:
        inc byte [ score_right ]
        call reset_after_point

touch_left_exit:
        pop rbx
        pop rax
        ret


; Function test if ball touches the right bar
test_touches_right:
        push rax
        push rbx

        mov al, byte [ ball ]
        cmp al, byte [ bar_right ]
        jl touch_right_left_win

        mov bl, byte [ bar_right ]
        add bl, BAR_SIZE
        cmp al, bl
        jg touch_right_left_win

        call bounce_x
        jmp touch_right_exit

touch_right_left_win:
        inc byte [ score_left ]
        call reset_after_point

touch_right_exit:
        pop rbx
        pop rax
        ret


; Detect if ball got on the right edge of the screen
detect_left_edge:
        ; If ball touches left of screen
        cmp byte [ ball + 1 ], 1
        je test_touches_left
        ret


; Detect if ball got on the left edge of the screen
detect_right_edge:
        ; If ball touches right of screen
        cmp byte [ ball + 1 ], (SCREEN_WIDTH - 1)
        je test_touches_right
        ret


; Function update the whole game data
update_game:
        call update_ball_position

        call detect_left_edge
        call detect_right_edge

        ; If ball touches top of screen
        cmp byte [ ball ], 1
        je bounce_y

        ; If ball touches bottom of screen
        cmp byte [ ball ], (SCREEN_HEIGHT - 1)
        je bounce_y

        ret


; Reset the game field after a point was scored
reset_after_point:
        push rax
        push rbx

        mov al, byte [ score_left ]
        add al, byte [ score_right ]
        mov bl, al
        and bl, 0x01
        mov byte [ direction ], bl

        mov bl, al
        and bl, 0x02
        shr bl, 1
        mov byte [ direction + 1 ], bl

        mov byte [ ball ], INIT_BALL_Y
        mov byte [ ball + 1 ], INIT_BALL_X
        mov byte [ bar_left ], INIT_BAR_Y
        mov byte [ bar_right ], INIT_BAR_Y

        pop rbx
        pop rax
        ret


; Erase the previous screen
erase_prev_screen:
        push rax
        push rbx

        ; Clean the previous position of the ball
        mov rax, SCREEN_DRAW_Y_START
        add al, [ ball ]
        mov rbx, 0
        mov bl, [ ball + 1]
        call move_cursor

        mov rdx, 1
        mov rsi, EMPTY_CHAR
        call print

        mov rdx, 1
        mov rsi, EMPTY_CHAR
        mov r8, BAR_SIZE

        mov al, [ bar_left ]
        add rax, SCREEN_DRAW_Y_START
        mov rbx, 1


; Erase the previous bar left, to draw the new one
erase_bar_left:
        call move_cursor
        call print
        inc rax
        dec r8
        cmp r8, 1
        jge erase_bar_left

        mov r8, BAR_SIZE

        mov al, [ bar_right ]
        add rax, SCREEN_DRAW_Y_START
        mov rbx, SCREEN_WIDTH


; Erase the previous bar right, to draw the new one
erase_bar_right:
        call move_cursor
        call print
        inc rax
        dec r8
        cmp r8, 1
        jge erase_bar_right

        pop rbx
        pop rax
        ret


; Draw a horizontal wall
draw_wall:
        dec rax

        mov rdx, 3
        mov rsi, WALL_CHAR
        call print

        cmp rax, 1
        jge draw_wall
        ret


; Draw a "player" bar
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


; Draw the ball
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


; Draw the informations at the top of the screen
draw_top_bar:
        push rax
        push rsi
        push rdi

        call erase_line

        mov rsi, LEFT_MSG
        mov rdx, left_msg_len
        call print

        mov rax, 1
        mov rbx, ( left_msg_len + 2 )
        call move_cursor

        mov rax, 0
        mov al, [ score_left ]
        call print_number

        mov rbx, ( SCREEN_WIDTH - 6)
        mov rax, right_msg_len
        sub rbx, rax
        mov rax, 1
        call move_cursor

        mov rsi, RIGHT_MSG
        mov rdx, right_msg_len
        call print

        mov rax, 1
        mov rbx, ( SCREEN_WIDTH - 4 )
        call move_cursor

        mov rax, 0
        mov al, [ score_right ]
        call print_number

        pop rdi
        pop rsi
        pop rax
        ret


; Draw the whole screen of the game
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


; Function that gets called at every timer update
timer_handler:
        call erase_prev_screen
        mov rax, 1
        mov rbx, 1
        call move_cursor
        call get_input
        call update_game
        call draw_screen
        ret


; Function started when launching the executable
_start:
init_game:
        call clear
        call reset
        call hide_cursor
        call enable_raw_mode
        call set_non_blocking
        mov rax, SCREEN_REFRESH_SEC
        mov rbx, SCREEN_REFRESH_NSEC
        mov rcx, timer_handler
        call start_timer
        call wait_forever

exit_program:
        call restore_term
        call clear

syscall_exit:
        ; Syscall exit
        mov rax, 60
        mov rdi, 0
        syscall
