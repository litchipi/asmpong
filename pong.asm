%include 'display.asm'

section .bss
        ball: resb 2

section .text
global _start

draw_wall:
        sub rax, 1

        mov rdx, 1
        mov rsi, WALL_CHAR
        call print

        cmp rax, 1
        jge draw_wall
        ret

draw_screen:
        call clear

        ; Draw top wall
        mov al, 1
        mov bl, 1
        call move_cursor
        mov rax, screen_width
        call draw_wall

        ; Draw bottom wall
        mov al, screen_height
        mov bl, 1
        call move_cursor
        mov rax, screen_width
        call draw_wall

        ; Draw the ball
        mov al, [ ball ]
        mov bl, [ ball + 1 ]
        call move_cursor
        mov rdx, 1
        mov rsi, BALL_CHAR
        call print

        ret

_start:
init_game:
        call reset

        mov byte [ ball ], 5
        mov byte [ ball + 1 ], 15
game_loop:
        call draw_screen

exit_program:
        call reset

        mov al, screen_height
        mov bl, 1
        add al, 2
        call move_cursor

        ; Syscall exit
        mov rax, 60
        mov rdi, 0
        syscall

section .data
        screen_width equ 30
        screen_height equ 10

        BALL_CHAR db 'x'
        WALL_CHAR db "#"
