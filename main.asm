.model small
.stack 100h

.data
    gameSpeed db 40    ;velocidad del juego
    snakeAscii db '>' ; ascii of snake UNUSED!
    wallAscii db '$'
    snakeX db 29      ; Snake X
    snakeY db 11       ; Snake Y
    snakeSize db 1
    currentDir db 2  ; 0: up, 
                          ; 1: down, 
                          ; 2: left, 
                          ; 3: right,  
    gameSize db 15
    
    fruit db 0
    fruitX db 21
    fruitY db 7
    score db 0
    
    screenBase dw 0B800h  ; VGA text mode        
    wait_time db 5

.code
main proc
    ; data
    mov ax, @data
    mov ds, ax

    ; Set video mode to 80x25 text mode
    mov ax, 03h
    int 10h
    
    ;main menu
    menu: 

    ;main game loop, bucle del juego
    gameloop:      
        call asyncinput             ;input del jugador
        
        call draw                   ;dibujar actores          
        call EmptyKeyboardBuffer
        call check_col              ;checkear colisiones
        call delay                  ;delay del jeghuo (velocidad)
        
        jmp gameloop
    
    exit:
    ; Exit 
    mov ah, 4Ch
    int 21h
main endp


asyncinput proc         ;input async, reads from buffer but doesn't stop run
    mov ah, 01h ; checks if a key is pressed
    int 16h
    jz return
    mov ah, 00h ; get the keystroke
    int 16h
    return:
    ret      
    ;borrar esto de arriba si no funciona
    
    mov     ah, 01h
    int     16h
    jz      no_key
check_for_more_keys:
    mov     ah, 00h
    int     16h

    push    ax
    mov     ah, 01h
    int     16h
    jz      no_more_keys
    pop     ax
    jmp     check_for_more_keys

no_more_keys:
    pop     ax

    mov     currentDir, ah
no_key:
    ret 
asyncinput endp   
    
input:              ;normal input, stops run  
    MOV ah, 00h   
    INT 16H     
    MOV bl, al      ; se guarda el valor en bl 
    ret   
    
;dibujar snake y otros
draw proc
            ;actualizar posiciones de los actores
    cmp AH, 48h     ;up arrow
    je moveup  
    cmp AH, 50h     ;down arrow    
    je movedown
    cmp AH, 4Bh     ;left arrow
    je moveleft     
    cmp AH, 4Dh     ;right arrow
    je moveright 
    
            ;if no key was pressed, go current direction
    cmp currentDir, 0     ;up arrow
    je moveup  
    cmp currentDir, 1     ;down arrow    
    je movedown
    cmp currentDir, 2     ;left arrow
    je moveleft     
    cmp currentDir, 3     ;right arrow
    je moveright 
    
    moveup:
    sub snakeY, 1 
    mov currentDir, 0  
    mov al, '^'
    jmp clear 
    
    movedown:
    add snakeY, 1   
    mov currentDir, 1  
    mov al, 'v'
    jmp clear  
      
    moveleft:
    sub snakex, 1
    mov currentDir, 2
    mov al, '<'
    jmp clear    
    
    moveright:
    add snakex, 1
    mov currentDir, 3 
    mov al, '>'
    jmp clear
    
    ;limpiar pantalla
    clear:
    call clear_screen
    
draw_snake:   
   ; Draw the snake at the new position
   ;dl = columna
   ; dh = fila   
    call draw_square
    mov dl, snakeX   ; Column
    mov dh, snakeY   ; Row
    call draw_char
    mov dl, fruitX   ; Column
    mov dh, fruitY   ; Row
    call check_fruit    
    ret
draw endp

draw_char proc
    push ax
    push bx
    push cx
    push dx

    mov ah, 02h
    mov bh, 0
    int 10h

    mov ah, 09h
    mov al, al
    mov bl, 2fh         ; color del personaje 
    mov cx, 1
    int 10h

    pop dx
    pop cx
    pop bx
    pop ax
    ret
draw_char endp 
draw_fruit proc
    push ax
    push bx
    push cx
    push dx
    mov al, '*'
    mov ah, 02h
    mov bh, 0
    int 10h

    mov ah, 09h
    mov al, al
    mov bl, 2fh         ;fruta 
    mov cx, 1
    int 10h

    pop dx
    pop cx
    pop bx
    pop ax
    ret
draw_fruit endp  

;limpiar la pantalla   
;funcion sacada del laboratorio, es la version ams rapida que encontre
clear_screen proc
    push ax
    push bx
    push cx
    push dx
    mov AH, 6H 
    mov AL, 0    
    mov BH, 7         ;clear screen 
    mov CX, 0
    mov DL, 79
    mov DH, 24
    int 10H
    pop dx
    pop cx
    pop bx
    pop ax
    ret
clear_screen endp

 
check_col proc
    cmp snakeX, 20     ;left boundary (32 + 1)
    jl collision    
    mov al, 40
    ;add al, gameSize
    cmp snakeX, al
    jg collision
    cmp snakeY, 0      ;top boundary (5 + 1)
    jl collision
    mov al, 15
    ;add al, gameSize
    cmp snakeY, al
    jg collision
              
    mov al, fruitX          
    cmp snakeX, al
    jne done_col
    mov al, fruitY          
    cmp snakeY, al
    
    jne done_col
    ;Ate the fruit
    call beep_sound
    inc score
    mov fruit, 0
    
    done_col:
    ret

    collision:
    jmp exit
check_col endp
    
delay proc 
delaying:  
    MOV     CX, 0FH
    MOV     DX, 4240H
    MOV     AH, 86H
    INT     15H
    ret 
          
EmptyKeyboardBuffer:
  push ax
more:
  mov  ah, 01h        ; BIOS.ReadKeyboardStatus
  int  16h            ; -> AX ZF
  jz   done          ; No key waiting aka buffer is empty
  mov  ah, 00h        ; BIOS.ReadKeyboardCharacter
  int  16h            ; -> AX
  jmp  more          ; Go see if more keys are waiting
done:
  pop  ax
  ret
        
draw_walls proc
    mov al, 0          ; Current size of the wall being drawn
    mov cx, 15
    mov dl, 32         ; Initial wall X      
    mov dh, 5          ; Initial wall Y

draw_top:
    push cx     
    call draw_wall  
    inc dl
    inc al
    pop cx 
    cmp al, gameSize  
    jne draw_top
    
    mov dl, 32
    mov dh, 5
    mov al, 0
    add dh, gameSize   ; Adjust position 
draw_bottom:
    push cx     
    call draw_wall  
    inc dl
    inc al
    pop cx 
    cmp al, gameSize  
    jne draw_bottom  
    
    mov dl, 32
    mov dh, 5
    mov al, 0
draw_left_right:           
    push cx     
    call draw_wall
    
    add dl, gameSize
    call draw_wall
    sub dl, gameSize
      
    inc dh
    inc al
    pop cx 
    cmp al, gameSize  
    jne draw_left_right

done_walls:
    ret
draw_walls endp
draw_wall proc
    push ax
    push bx
    push cx
    push dx

    mov ah, 02h
    mov bh, 0
    int 10h

    mov ah, 09h
    mov al, wallAscii
    mov bl, 1Eh         ; amarillo fondo azul 
    mov cx, 1
    int 10h

    pop dx
    pop cx
    pop bx
    pop ax
    ret
draw_wall endp 

draw_square proc
    push ax
    push bx
    push cx
    push dx
    mov al, 0             
    mov ah, 6   

    mov bh, 2fh  ;color
    mov ch, 0
    mov cl, 20
    mov dh, 15
    mov dl, 40
    int 10h
    pop dx
    pop cx
    pop bx
    pop ax           
    ret            
draw_square endp

check_fruit proc
    push ax
    push bx
    push cx
    push dx
    cmp fruit, 1
    je fruit_done
    
    mov fruitX, 22
    mov fruitY, 12
    call draw_fruit
    mov fruit, 1
    
    fruit_done:
    pop dx
    pop cx
    pop bx
    pop ax           
    ret
check_fruit endp  

beep_sound proc
    mov ax, 0E07h  ; BIOS.Teletype BELL
    int 10h            
    ret            
beep_sound endp

end main
