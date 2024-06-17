%include 'display.asm'

section .bss
        ball: resb 2        ; [ x, y ]
        direction: resb 2   ; [ horiz, vert ] -> [ E=1 / W=0, S=1 / N=0 ]

section .text
global _start

init_game_values:
        mov byte [ ball ], 5
        mov byte [ ball + 1 ], 15

        mov byte [ direction ], 1
        mov byte [ direction + 1], 0
        ret

update_position:
        cmp rax, 1
        jl update_position_negative
update_position_positive:
        inc rbx
        ret
update_position_negative:
        sub rbx, 1
        ret

update_game:
        mov al, [ direction + 1 ]
        mov bl, [ ball ]
        call update_position
        mov byte [ ball ], bl

        mov al, [ direction ]
        mov bl, [ ball + 1 ]
        call update_position
        mov byte [ ball + 1], bl

        ret

draw_wall:
        sub rax, 1

        mov rdx, 1
        mov rsi, WALL_CHAR
        call print

        cmp rax, 1
        jge draw_wall
        ret

draw_screen:
        ; call clear

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
        call init_game_values
        mov r10, 4
game_loop:
        call update_game
        call draw_screen
        sub r10, 1
        cmp r10, 1
        jge game_loop

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
