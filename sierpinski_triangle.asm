assume cs:code
data segment
    assume ds:data 

    size equ 32
    x db 0
    y db 0
    i db 0
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
        
    start:
        
        ; loop up to left side of triangle
        mov y, size
        dec y
        for1:
            
            ; loop between borders
            mov i, 0
            for2:    
                
                ; print space char
                mov dl, ' '
                mov ah, 06h
                int 21h
            
            inc i
            mov ah, [i]
            mov bh, [y]
            cmp ah, bh
            jl for2
            
            ; inner loop for internal lines
            mov x, 0
            for3:
                
                ; drawing internal line character or space characters  
                mov ah, [x]
                mov bh, [y]
                and ah, bh
                cmp ah, 0
                jne draw_empty  
                    mov dl, '*'
                    mov ah, 06h
                    int 21h
                    
                    mov dl, ' '
                    mov ah, 06h
                    int 21h
                    
                jmp exit_drawing
                draw_empty:
                    mov dl, ' '
                    mov ah, 06h
                    int 21h
                    
                    mov dl, ' '
                    mov ah, 06h
                    int 21h
                
                exit_drawing:
            inc x
            mov ah, [x]
            add ah, [y]
            cmp ah, size
            jl for3
            
            ; print new line
            mov dl, 10
            mov ah, 06h
            int 21h
            mov dl, 13
            mov ah, 06h
            int 21h    
        dec y
        cmp y, 0        
        jge for1
	
code ends 
end ;code