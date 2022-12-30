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
    
    star_pos db 0
    snake_pos db 0
    snake_pos_x db 0
    snake_direction db 1
    
    cursor_pos db 0
    cursor_pos_x db 0
    
    body db 75 dup(0)
    
    score_0 db 0
    score_1 db 0 
    
    max_body_length equ 74
    body_character equ 1
    head_character equ 2
    tile_character equ ','
    star_character equ 3
    border_character equ 205     
data ends

code segment
    
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
	
	; AH = function that write character with attributes
	; CX = how many times write character 1000 hex = 4096 decimal
	; AL = character to write
	; BL = background color 
	; upper bits stands for background e.g. 0
	; lower  bits for foreground e.g. 2
	; 02h = black background, green foreground
    mov ah, 09h
    mov cx, 1000h
    mov al, ' '
    mov bl, 0ah
    int 10h
	
	; hide cursor
	; AH = 1 set text-mode cursor shape
	; CX = 8 scan lines character of cursor
    mov  ah, 01h
    mov  cx, 2607h
    int  10h
      
	start:
	
		; set values initially
		mov star_pos, 35
		mov snake_pos, 55
		mov snake_pos_x, 10
		
        game_loop:
            check_key:
                ; sleep for 20ms (20816 microseconds -> 0c680h)
                mov cx, 01h
                mov dx, 0c680h
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
				jmp game_over
				not_exit:
				
				; check if W is pressed
				cmp ah, 11h
				jne not_w
				; check if currently snake isnt turned down
				; snake shouldnt collide with themself
				; just by turning 180 degree
				cmp snake_direction, 2
				je not_w
				mov snake_direction, 0
				not_w:
                
                ; check if S is pressed
				cmp ah, 1Fh
				jne not_s
				cmp snake_direction, 0
				je not_s
				mov snake_direction, 2
				not_s:
                
                ; check if A is pressed
				cmp ah, 1Eh
				jne not_a
				cmp snake_direction, 1
				je not_a
				mov snake_direction, 3
				not_a:
                
                ; check if D is pressed
				cmp ah, 20h
				jne not_d
				cmp snake_direction, 3
				je not_d
				mov snake_direction, 1
				not_d:
				
				; flush keyboard buffer
                mov ah, 0Ch
                int 21h
                
            is_new_key_false:                
            
            set_new_head_position:
				cmp snake_direction, 0
				jne not_up
				sub snake_pos, 15
				not_up:
                
                cmp snake_direction, 1
				jne not_right
				inc snake_pos
				inc snake_pos_x
				not_right:
    
                cmp snake_direction, 2
				jne not_down    
				add snake_pos, 15
				not_down:
				
				cmp snake_direction, 3
				jne not_left
				dec snake_pos
				dec snake_pos_x
				not_left:
				
				cmp snake_pos_x, 16
				jne not_over_right
				mov snake_pos_x, 1
				sub snake_pos, 15
				not_over_right:
				
				cmp snake_pos_x, 0
				jne not_over_left
				mov snake_pos_x, 15
				add snake_pos, 15
				not_over_left:
				
				cmp snake_pos, 225
				jle not_over_bottom
				cmp snake_pos, 240
				jg not_over_bottom
				sub snake_pos, 225
				not_over_bottom:
				
				cmp snake_pos, 240
				jl not_over_top
				cmp snake_pos, 0
				jg not_over_top
				add snake_pos, 225
				not_over_top:
            
            ; loop for each part of body defined in body array
		    mov si, 0
    		loop_over_body_collision:
    		
    			; if si is outer of body
    			cmp si, max_body_length
    			jge exit_loop_over_body_collision
                
                mov ah, [snake_pos]
                mov bh, body[si]                       
                cmp ah, bh 
                jne not_collided
    			jmp game_over
    			
    			not_collided:
    			inc si
    			jmp loop_over_body_collision
    			exit_loop_over_body_collision:
            
		    mov si, 0
    		loop_over_body_shift:
    		
    			; if si is outer of body
    			cmp si, max_body_length
    			jge exit_loop_over_body_shift
                
                inc si
    			mov ah, body[si]
    			dec si
    			mov body[si], ah
    			
    			; move si to next value
    			inc si
    			jmp loop_over_body_shift
    			exit_loop_over_body_shift:

            
            ; insert new body part (twice if star has been collected)
            mov si, 0
    		loop_over_body_add_body:
    		
    			; if si is outer of body
    			cmp si, max_body_length
    			jge exit_loop_over_body_add_body
                
                mov dl, body[si]
                cmp dl, 0
                jne dont_add_body
                    mov dl, snake_pos
                    mov body[si], dl
                    
                    ; check if head is euqal to star position
                    ; and insert body once again
                    mov ah, [snake_pos]
                    mov bh, [star_pos]                       
                    cmp ah, bh 
                    jne exit_loop_over_body_add_body
                    
                        inc si
                        cmp si, max_body_length
                        jge exit_loop_over_body_add_body
                        mov dl, body[si]
                        cmp dl, 0
                        jne dont_add_body
                    
                            mov dl, snake_pos
                            mov body[si], dl
                            
                            ; get random value
                            push dx
                            mov  ax, dx
                            xor  dx, dx
                            mov  cx, 225    
                            div  cx
                            inc dl
                            mov star_pos, dl
                            pop dx 
                            
                            ; add score
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
                
                jmp exit_loop_over_body_add_body 
                dont_add_body:
                
    			; move si to next value
    			inc si
    			jmp loop_over_body_add_body
    			exit_loop_over_body_add_body:

            render:
                mov cursor_pos, 0
                
                ; set cursor at x=dl=0, y=dh=15
                mov dl, 00h
                mov dh, 15
                mov ah, 2h
                mov bh, 0
                int 10h
                
                ; draw border bottom
				mov dl, 10
				mov ah, 06h
				int 21h
				mov dl, 13
				int 21h
				mov cx, 15
				draw_grass_bottom:
				dec cx
				    mov dl, border_character
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
				mov cx, 15
				draw_grass_top:
				    dec cx
				    mov dl, border_character
				    int 21h
				jnz draw_grass_top

                ; set cursor at x=dl=0, y=dh=0
                mov dl, 00h
                mov dh, 00h
                mov ah, 2h
                mov bh, 0
                int 10h
                
                new_line:
                mov dl, 10
                mov ah, 06h
                int 21h
                mov dl, 13
                int 21h
                mov cursor_pos_x, 0
                
                render_process:
                    inc cursor_pos
                    inc cursor_pos_x

                    mov ah, [cursor_pos]
                    mov bh, [snake_pos]                       
                    cmp ah, bh 
                    jne render_2
                    mov dl, head_character
                    mov ah, 06h
                    int 21h
                    jmp render_after
                    
                    render_2:
        		    mov si, 0
            		loop_over_body_render:
            		
            			; if si is outer of body
            			cmp si, max_body_length
            			jge exit_loop_over_body_render
                        
                            ; check if current body part 
                            ; is equal to cursor position
                            ; and draw snake body
                            mov ah, [cursor_pos]
                            mov bh, body[si]                       
                            cmp ah, bh
            			    jne loop_over_body_render_next
            			        
            			        mov dl, body_character 
                                mov ah, 06h
                                int 21h
            			        jmp render_after
            			        
            			; move si to next value
            			loop_over_body_render_next:
            			inc si
            			jmp loop_over_body_render
            			exit_loop_over_body_render:
                    
                    render_3:
                    mov ah, [cursor_pos]
                    mov bh, [star_pos]                       
                    cmp ah, bh 
                    jne render_4 
                    mov dl, star_character
                    mov ah, 06h
                    int 21h
                    jmp render_after
                                               
                    render_4:
                    cmp cursor_pos, 225
                    ja render_after
                    mov dl, tile_character
                    mov ah, 06h
                    int 21h
                
                    render_after:    
                    cmp cursor_pos_x, 15
                    je new_line
                
                cmp cursor_pos, 225
                jb render_process
                
        jmp game_loop
        
        game_over:
		mov ah, 4ch
		int 21h
	
code ends 
end ;code