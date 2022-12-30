; https://www.tutorialspoint.com/assembly_programming/assembly_registers.htm
; http://spike.scu.edu.au/~barry/interrupts.html#ah02
; http://studianet.pl/kursy/proki/podst_asemblera/podst_asem.htm
; http://www.oldlinux.org/Linux.old/docs/interrupts/int-html/int-15.htm
; https://en.wikipedia.org/wiki/INT_16H
; http://www.ctyme.com/intr/cat.htm
; https://en.wikipedia.org/wiki/INT_10H
; http://members.tripod.com/vitaly_filatov/ng/asm/asm_023.1.html
; https://www.computerhope.com/color.htm
; https://stackoverflow.com/questions/17855817/generating-a-random-number-within-range-of-0-9-in-x86-8086-assembly

assume cs:code
data segment
    assume ds:data 
    
    player_pos_x db 0
    player_pos_y equ 14
    
    enemy_max equ 24
    enemy_x db 25 dup(0)
    enemy_y db 25 dup(0)
    
    cursor_x db 0
    cursor_y db 0
    
    bullet_max equ 9
    bullet_x db 10 dup(0)
    bullet_y db 10 dup(0)
    
    current_bullet_ptr dw 0
    current_bullet_x db 0
    current_bullet_y db 0
    
    current_enemy_ptr dw 0
    current_enemy_x db 0
    current_enemy_y db 0
    
    score_0 db 0
    score_1 db 0 
    
    cycle_counter db 0   
data ends

code segment
    
    ; set ds pointer
    push ax
    mov ax, data
    mov ds, ax
    pop ax
    
    ; text mode (80x25 16 colors)
    mov ah, 00h
    mov al, 03h
    int 10h
    
    ; hide cursor
    mov ah, 01h
    mov cx, 2607h
    int 10h
    
    ; set colors
    mov ah, 09h
    mov cx, 1000h
    mov al, ' '
    mov bl, 0bh
    int 10h
             
    start:
        
        ; initialize values
        mov player_pos_x, 12
        mov cycle_counter, 8
        
        game_loop:
            ; increment cycle_counter
            inc cycle_counter
            
            check_key:
                
                ; sleep (25816 microsends)
                mov cx, 01h
                mov dx, 64d8h
                mov ah, 86h
                int 15h
                
                ; check keyboard buffer
                mov ah, 0Bh
                int 21h
                cmp al, 00h
                je is_new_key_false
                
            is_new_key_true:
                
                ; get keystroke
                mov ah, 00h
                int 16h
                
                ; check if esc pressed
                cmp ah, 01h
                jne not_exit
                jmp game_over
                not_exit:
                
                ; check if A was pressed
                cmp ah, 1Eh
                jne not_a
                dec player_pos_x
                not_a:          
                
                ; check if D was pressed
                cmp ah, 20h
                jne not_d
                inc player_pos_x
                not_d:
                
                ; check if Spacebar was pressed          
                cmp al, 32
                jne not_spacebar
                    ; instantiate bullet
                    mov si, 0
                    loop_over_bullet_2:
                         
                        inc si
                        cmp si, bullet_max
                        jge exit_loop_over_bullet_2
                        
                        mov ah, bullet_y[si]
                        cmp ah, 0
                        jne loop_over_bullet_2
                    
                        ; instantiate new bullet
                        mov ah, player_pos_y
                        mov bullet_y[si], ah 
                        mov ah, player_pos_x     
                        mov bullet_x[si], ah
                        
                    exit_loop_over_bullet_2:
                not_spacebar:
                
                ; flush keyboard buffer
                mov ah, 0Ch
                int 21h
                
            is_new_key_false:
             
            ; for each bullet, move it up
            mov si, 0
            loop_over_bullet:     
                inc si
                
                ; if si is outer of bullets array
                cmp si, bullet_max
                jl dont_exit_loop_over_bullet
                jmp exit_loop_over_bullet
                dont_exit_loop_over_bullet:
                
                ; if bullet is not set (y = 0)
                mov dl, bullet_y[si]
                cmp dl, 0
                je loop_over_bullet
                
                ; decrement bullet y position (move toward the top screen)
                dec dl
                mov bullet_y[si], dl 
                
                cmp dl, 0
                jg dont_destroy_bullets
                    mov bullet_x[si], 0
                    mov bullet_y[si], 0
                    jmp loop_over_bullet
                dont_destroy_bullets:
                
                ; set coordinates of current bullet_x and bullet_y
                mov ah, bullet_x[si]
                mov current_bullet_x, ah
                mov ah, bullet_y[si]
                mov current_bullet_y, ah
                
                ; check if enemy and bullet collide
                ; move bullet loop pointer to temp variable        
                mov current_bullet_ptr, si

                ; for each enemy
                mov si, 0
                inner_loop_over_enemies:
                    inc si
                    
                    ; if si is outer of enemies array
                    cmp si, enemy_max
                    jge exit_inner_loop_over_enemies
                    
                    ; set coordinates of enemy
                    mov ah, enemy_x[si]
                    mov current_enemy_x, ah
                    mov ah, enemy_y[si]
                    mov current_enemy_y, ah
                    
                    ; check if enemy and bullet have the same position
                    mov ah, [current_bullet_x]
                    mov bh, [current_enemy_x]
                    cmp ah, bh
                    jne inner_loop_over_enemies
                    mov ah, [current_bullet_y]
                    mov bh, [current_enemy_y]
                    cmp ah, bh
                    jne inner_loop_over_enemies
                    
                    ; destroy enemy
                    mov enemy_x[si], 0
                    mov enemy_y[si], 0
                    
                    ; save enemy loop pointer in temp variable
                    ; get pointer of bullet
                    ; destroy bullet
                    ; get pointer of enemy
                    mov current_enemy_ptr, si
                    mov si, [current_bullet_ptr]
                    mov bullet_x[si], 0
                    mov bullet_y[si], 0
                    mov si, [current_enemy_ptr]
                    
                    ; add score
                    add score_0, 1
                    
                    jmp inner_loop_over_enemies
                    exit_inner_loop_over_enemies:
                
                ; get si from temp variable    
                mov si, [current_bullet_ptr] 
            jmp loop_over_bullet    
            exit_loop_over_bullet:
            
            
            ; if cycle_counter is equal to 5 or 10
            ; for each enemy, move it down
            cmp cycle_counter, 5
            je move_down_enemy 
            cmp cycle_counter, 10
            je move_down_enemy
            jmp exit_loop_over_enemies
            
            move_down_enemy:
                mov si, 0
                loop_over_enemies:
                    inc si
                    
                    ; if si is outer of enemies array
                    cmp si, enemy_max
                    jge exit_loop_over_enemies
                    
                    mov dl, enemy_y[si]
                    cmp dl, 15
                    jl dont_destroy_enemy
                    mov enemy_y[si], 0
                    mov enemy_x[si], 0
                    jmp game_over
                    dont_destroy_enemy:
                    
                    ; if enemy is not set (y = 0 / above the screen)
                    cmp dl, 0
                    je loop_over_enemies                
                    
                    ; incremenet y (move down the screen)
                    inc dl
                    mov enemy_y[si], dl
                
                jmp loop_over_enemies                     
                exit_loop_over_enemies:
                                  
            ; check if cycle_counter is equal to 10
            cmp cycle_counter, 10
            jl dont_spawn
                
                ; get random value
                mov ah, 00h; interrupts to get system time        
                int 1ah
   
                mov ax, dx
                xor dx, dx
                mov cx, 16
                div cx
                add dl, 4
                
                
                ; for each element of a enemies array
                mov si, 0
                loop_over_enemies_2:
                    inc si
                    
                    ; if si is greater or equal enemy array size
                    cmp si, enemy_max
                    jge exit_loop_over_enemies_2
                    
                    ; check if current array field is empty
                    mov ah, enemy_y[si]
                    cmp ah, 0
                    jne loop_over_enemies_2
                    
                    ; instantiate new enemy
                    mov enemy_y[si], 1     
                    mov enemy_x[si], dl
                    
                exit_loop_over_enemies_2:    
                
                ; reset cycle_counter
                mov cycle_counter, 0
                          
            dont_spawn:
            
            ; compare score
            cmp score_0, 9
            jl dont_increment_tens
                mov score_0, 0
                inc score_1
            dont_increment_tens:
            
            ; draw screen                                      
            render:
                
                ; draw bottom border
                mov dl, 10
                mov ah, 06h
                int 21h
                mov dl, 13
                int 21h
                mov cx, 25
                draw_border_bottom:
                dec cx
                    mov dl, '='
                    int 21h
                jnz draw_border_bottom
                
                ; new line
                mov dl, 10
                mov ah, 06h
                int 21h
                mov dl, 13
                int 21h
                
                ; print score
                mov dl, score_1
                add dl, '0'
                mov ah, 06h
                int 21h
                mov dl, score_0
                add dl, '0'
                int 21h
                
                ; set cursor at x=0 y=0
                mov dl, 00h
                mov dh, 00h
                mov ah, 02h
                mov bh, 00h
                int 10h
                
                ; draw top border
                mov dl, 10
                mov ah, 06h
                int 21h
                mov dl, 13
                int 21h
                mov cx, 25
                draw_border_top:
                dec cx
                    mov dl, '='
                    int 21h
                jnz draw_border_top
                
                ; for each y
                mov cursor_y, 0
                draw_y:
                    inc cursor_y
                    
                    ; if y is equal or greater than 15
                    ; quit the loop 
                    ; and start next game cycle
                    cmp cursor_y, 15
                    jl dont_exit_draw_y
                    jmp exit_draw_y
                    dont_exit_draw_y:
                    
                    ; draw new line
                    new_line:
                    mov dl, 10
                    mov ah, 06h
                    int 21h
                    mov dl, 13
                    int 21h
                    
                    ; for each x
                    mov cursor_x, 0
                    draw_x:
                        inc cursor_x
                        
                        ; if x is equal or greater than 25
                        ; quit the loop
                        ; and start drawing next line
                        cmp cursor_x, 25
                        jl dont_exit_draw_x
                        jmp exit_draw_x
                        dont_exit_draw_x:
                            
                            ; draw player
                            render_1:
                                mov ah, cursor_x
                                mov bh, player_pos_x
                                cmp ah, bh
                                jne render_2
                                mov ah, cursor_y
                                mov bh, player_pos_y
                                cmp ah, bh
                                jne render_2
                                mov dl, 30
                                mov ah, 06h
                                int 21h
                            jmp exit_render
                            
                            ; draw enemies
                            render_2:
                                mov si, 0
                                loop_over_enemies_render:
                                    inc si
                                    
                                    ; if si is equal or greater enemy array size
                                    cmp si, enemy_max
                                    jge exit_loop_over_enemies_render
                                    
                                    ; check if current array field is not empty
                                    mov ah, enemy_y[si]
                                    cmp ah, 0
                                    je loop_over_enemies_render
                                    
                                    ; compare enemy coordinates
                                    mov ah, enemy_x[si]
                                    mov bh, [cursor_x]
                                    cmp ah, bh
                                    jne loop_over_enemies_render
                                    mov ah, enemy_y[si]
                                    mov bh, [cursor_y]
                                    cmp ah, bh
                                    jne loop_over_enemies_render  
                                    mov dl, 02h
                                    mov ah, 06h
                                    int 21h
                                    jmp exit_render
                                    
                                jmp loop_over_enemies_render    
                                exit_loop_over_enemies_render:    
                            
                            
                            ; draw bullets
                            render_3:
                                mov si, 0
                                loop_over_bullets_render:
                                    inc si
                                    
                                    ; if si is equal or greater enemy array size
                                    cmp si, bullet_max
                                    jge exit_loop_over_bullets_render
                                    
                                    ; check if current array field is not empty
                                    mov ah, bullet_y[si]
                                    cmp ah, 0
                                    je loop_over_bullets_render
                                    
                                    ; compare bullet coordinates
                                    mov ah, bullet_x[si]
                                    mov bh, [cursor_x]
                                    cmp ah, bh
                                    jne loop_over_bullets_render
                                    mov ah, bullet_y[si]
                                    mov bh, [cursor_y]
                                    cmp ah, bh
                                    jne loop_over_bullets_render  
                                    mov dl, 15
                                    mov ah, 06h
                                    int 21h
                                    jmp exit_render
                                    
                                jmp loop_over_enemies_render    
                                exit_loop_over_bullets_render:    
                            
                            
                            render_4:
                            mov dl, ' '
                            mov ah, 06h
                            int 21h
                            
                            exit_render:
                    
                    jmp draw_x    
                    exit_draw_x:
                    
                jmp draw_y    
                exit_draw_y:
                jmp game_loop        
            
    game_over:
        mov ah, 4ch
        int 21h
                
	
code ends 
end ;code