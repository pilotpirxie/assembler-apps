; https://www.tutorialspoint.com/assembly_programming/assembly_registers.htm
; http://spike.scu.edu.au/~barry/interrupts.html#ah02
; http://studianet.pl/kursy/proki/podst_asemblera/podst_asem.htm
; http://www.oldlinux.org/Linux.old/docs/interrupts/int-html/int-15.htm
; https://en.wikipedia.org/wiki/INT_16H
; http://www.ctyme.com/intr/cat.htm
assume cs:code

; data segment
data segment
	assume ds:data
	score_0 db 0
    score_1 db 0
    bird_x db 2
    bird_y db 0
    pipe_x db 11
    pipe_y db 0
    cursor_x db 0
    cursor_y db 0
data ends

; code segment
code segment
    start:

		; set data segment pointer
		push ax
		mov ax, data
		mov ds, ax
		pop ax
        
		; text mode 80x25, 16 colors, 8 pages  
        ; ah=xxh al=03h -> ax=xx03h
        ; int 10h = video card intterupt
        mov ah, 00h
        mov al, 03h
        int 10h
		
        game_loop:

            ; compare if pipe_x is greater than 0 
            cmp pipe_x, 0
            ja pipe_x_gt_zero
                
                ; set pipe_x 11
                mov pipe_x, 11
                
                ; increment score by 1
                inc score_0
                cmp score_0, 9       
                jbe dont_icrement_tens
                    ; if ones place is >= 9
                    ; increment decimal by one
                    ; so number jump from 9 
                    ; to 1,0 [score_1, score_0]  
                    mov score_0, 0
                    inc score_1
                dont_icrement_tens:

                cmp pipe_y, 5
                jb pipe_y_gt_5
                    mov pipe_y, 0
                    jmp pipe_x_gt_zero
                pipe_y_gt_5:
                    inc pipe_y
                
                 
            pipe_x_gt_zero: 
            
            ; move pipe position by 1 unit horizontally left
            dec pipe_x
			
            check_key:
                ; sleep for 250ms (250000 microseconds -> 3D090h)
                mov cx, 03h
                mov dx, 05150h
                mov ah, 86h
                int 15h
                
                ; check if any data is in keyboard buffer
                mov ah, 0Bh
                int 21h
                cmp al, 0h   
                je is_new_key_false
				
            is_new_key_true:
                ; if there is some data in keyboard buffer
                ; get keystroke and save ASCII character in AL, AH = scan code
                mov ah, 0
                int 16h
                
				; check if esc is pressed
				cmp ah, 01h
				jne not_exit
				mov ah, 4ch
				int 21h
				not_exit:
				
                ; move bird position by 1 unit verically up
                sub bird_y, 2
                
				; flush keyboard buffer
                mov ah, 0Ch
                int 21h
                
            is_new_key_false:
                ; move bird position by 1 unit verically down
                inc bird_y

			check_collision:
				; collision with ground
				mov ah, 13
				mov bh, [bird_x]                       
				cmp ah, bh 
				jb render
				; check if bird is between pipes
				mov ah, [pipe_x]
				mov bh, [bird_x]                       
				cmp ah, bh 
				jne render
				mov ah, [bird_y]
				mov bh, [pipe_y]
				add bh, 4
				cmp ah, bh
				je render
				inc bh
				cmp ah, bh
				je render
				sub bh, 2                       
				cmp ah, bh
				je render
			
			game_over:
				mov ah, 4ch
				int 21h
			
            render:
                
				; draw grass bottom
				mov dl, 10
				mov ah, 06h
				int 21h
				mov dl, 13
				int 21h
				mov cx, 10
				draw_grass_bottom:
				    dec cx
				    mov dl, '='
				    int 21h
				jnz draw_grass_bottom
				
				; write new line
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
				
                ; set cursor at x=dl=0, y=dh=0
                mov dl, 00h
                mov dh, 00h
                mov ah, 2h
                mov bh, 0
                int 10h
				
				; draw grass top
				mov cx, 10
				    draw_grass_top:
				    dec cx
				    mov dl, '='
				    int 21h
				jnz draw_grass_top
               
				mov dh, 00h
				int 10h
				
                ; outer loop (y-axis)
                mov cursor_y, 0
                render_y:
                    inc cursor_y
                    
                    ; write new line
                    mov dl, 10
                    mov ah, 06h
                    int 21h
                    mov dl, 13
                    int 21h
                    
                    ; inner loop (x-axis)
                    mov cursor_x, 0
                    render_x:
                        inc cursor_x
                        
                        ; render bird 
                        render_1:
                        mov ah, [cursor_x]
                        mov bh, [bird_x]                       
                        cmp ah, bh 
                        jne render_2
                        mov ah, [cursor_y]
                        mov bh, [bird_y]                       
                        cmp ah, bh 
                        jne render_2
                        mov dl, '>'
                        mov ah, 06h
                        int 21h
                        jmp render_x_end
                        
                        ; render pipe
                        render_2:
                        mov ah, [cursor_x]
                        mov bh, [pipe_x]				
                        cmp ah, bh 
                        jne render_3
                        mov ah, [cursor_y]
                        mov bh, [pipe_y]
						add bh, 4
                        cmp ah, bh
                        je render_3
                        inc bh                       
                        cmp ah, bh
                        je render_3
                        sub bh, 2                       
                        cmp ah, bh
                        je render_3
                        mov dl, 'I'
                        mov ah, 06h
                        int 21h
                        jmp render_x_end
                        
                        ; render empty space
                        render_3:
                        mov dl, ' '
                        mov ah, 06h
                        int 21h
                        jmp render_x_end
                        
                    render_x_end:    
                    cmp cursor_x, 10
                    jb render_x
                
                render_y_end:
                cmp cursor_y, 12    
                jb render_y
                
                ; repeat game loop
                jmp game_loop
			jmp game_over
code ends
end ;code 