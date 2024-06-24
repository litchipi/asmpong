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
        SCREEN_REFRESH_NSEC equ  40000000 ; 40 ms

        SCREEN_DRAW_Y_START equ 4
        SCREEN_WIDTH equ 140
        SCREEN_HEIGHT equ 40

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
        je exit_program

        call react_input
        mov byte [ char_inp ], ' '

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
        call bounce_x
        ; TODO        Test if touches bar or not
        ; Then create reaction based on it
        ret


; Function test if ball touches the right bar
test_touches_right:
        call bounce_x
        ; TODO        Test if touches bar or not
        ; Then create reaction based on it
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

        ; TODO        Write the score for each player

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

        ; Syscall exit
        mov rax, 60
        mov rdi, 0
        syscall
