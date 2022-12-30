; https://www.tutorialspoint.com/assembly_programming/assembly_registers.htm
; http://spike.scu.edu.au/~barry/interrupts.html#ah02
; http://studianet.pl/kursy/proki/podst_asemblera/podst_asem.htm
; http://www.oldlinux.org/Linux.old/docs/interrupts/int-html/int-15.htm
; https://en.wikipedia.org/wiki/INT_16H
; http://www.ctyme.com/intr/cat.htm

assume cs:code
data segment
    assume ds:data 
    star_pos db 0
    snake_pos db 0
    snake_pos_x db 0
    snake_direction db 1
    cursor_pos db 0
    cursor_pos_x db 0
    body db 12 dup(0)      
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
	
	start:
	
		; set values initially
		mov star_pos, 35
		mov snake_pos, 55
		mov snake_pos_x, 5
		
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
				mov snake_direction, 0
				not_w:
                
                ; check if S is pressed
				cmp ah, 1Fh
				jne not_s
				mov snake_direction, 2
				not_s:
                
                ; check if A is pressed
				cmp ah, 1Eh
				jne not_a
				mov snake_direction, 3
				not_a:
                
                ; check if D is pressed
				cmp ah, 20h
				jne not_d
				mov snake_direction, 1
				not_d:
				
				; flush keyboard buffer
                mov ah, 0Ch
                int 21h
                
            is_new_key_false:                
            
            set_new_head_position:
				cmp snake_direction, 0
				jne not_up
				sub snake_pos, 10
				not_up:
                
                cmp snake_direction, 1
				jne not_right
				inc snake_pos
				inc snake_pos_x
				not_right:
    
                cmp snake_direction, 2
				jne not_down
				add snake_pos, 10
				not_down:
				
				cmp snake_direction, 3
				jne not_left
				dec snake_pos
				dec snake_pos_x
				not_left:
				
				cmp snake_pos_x, 11
				jne not_over_right
				mov snake_pos_x, 1
				sub snake_pos, 10
				not_over_right:
				
				cmp snake_pos_x, 0
				jne not_over_left
				mov snake_pos_x, 10
				add snake_pos, 10
				not_over_left:
				
				cmp snake_pos, 100
				jle not_over_bottom
				cmp snake_pos, 110
				jg not_over_bottom
				sub snake_pos, 100
				not_over_bottom:
				
				cmp snake_pos, 244
				jl not_over_top
				cmp snake_pos, 0
				jg not_over_top
				add snake_pos, 100
				not_over_top:
            
            ; loop for each part of body defined in body array
		    mov si, 0
    		loop_over_body_collision:
    		
    			; if si is outer of body
    			cmp si, 11
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
    			cmp si, 11
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
    			cmp si, 11
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
                        cmp si, 11
                        jge exit_loop_over_body_add_body
                        mov dl, body[si]
                        cmp dl, 0
                        jne dont_add_body
                    
                            mov dl, snake_pos
                            mov body[si], dl 
                            
                jmp exit_loop_over_body_add_body 
                dont_add_body:
                
    			; move si to next value
    			inc si
    			jmp loop_over_body_add_body
    			exit_loop_over_body_add_body:

            render:
                mov cursor_pos, 0
                
                ; print score
                mov dl, snake_pos_x
                add dl, '0'
				mov ah, 06h
				int 21h
                
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
                    mov dl, 219
                    mov ah, 06h
                    int 21h
                    jmp render_after
                    
                    render_2:
        		    mov si, 0
            		loop_over_body_render:
            		
            			; if si is outer of body
            			cmp si, 11
            			jge exit_loop_over_body_render
                        
                            ; check if current body part 
                            ; is equal to cursor position
                            ; and draw snake body
                            mov ah, [cursor_pos]
                            mov bh, body[si]                       
                            cmp ah, bh
            			    jne loop_over_body_render_next
            			        
            			        ; or 219
            			        mov dl, 219 
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
                    mov dl, '*'
                    mov ah, 06h
                    int 21h
                    jmp render_after
                                               
                    render_4:
                    mov dl, ','
                    mov ah, 06h
                    int 21h
                
                    render_after:    
                    cmp cursor_pos_x, 10
                    je new_line
                
                cmp cursor_pos, 100
                jl render_process
                
        jmp game_loop
        
        game_over:
		mov ah, 4ch
		int 21h
	
code ends 
end ;code