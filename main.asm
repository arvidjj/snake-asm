.model small
.stack 100h

.data
    gameSpeed db 40    ;velocidad del juego
    snakeAscii db '>' ; ascii of snake
    wallAscii db '$'
    snakeX db 10      ; Snake X
    snakeY db 5       ; Snake Y
    currentDir db 2  ; 0: up, 
                          ; 1: down, 
                          ; 2: left, 
                          ; 3: right,  
    wallSize db 5
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
    
    call draw_walls
    ;main game loop, bucle del juego
    gameloop:
        call asyncinput 
        
        call check_col 
        call remove_draw
        call draw
        call EmptyKeyboardBuffer         
        call delay
     
        jmp gameloop

    ; terminar
    mov ah, 0
    int 16h
    
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
    
draw_walls proc

draw_walls endp

    
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
    mov snakeAscii, '^'
    jmp clear 
    
    movedown:
    add snakeY, 1   
    mov currentDir, 1  
    mov snakeAscii, 'v'
    jmp clear  
      
    moveleft:
    sub snakex, 1
    mov currentDir, 2
    mov snakeAscii, '<'
    jmp clear    
    
    moveright:
    add snakex, 1
    mov currentDir, 3 
    mov snakeAscii, '>'
    jmp clear
    
        ;limpiar pantalla
    clear:
    ;mov ax, 3
    ;int 10h
        ;dl = columna
        ; dh = fila
draw_snake:
    ; Draw the snake at the new position   
    mov dl, snakeX   ; Column
    mov dh, snakeY   ; Row
    call draw_char
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
    mov al, snakeAscii
    mov bl, 0Ch         ; red 
    mov cx, 1
    int 10h

    pop dx
    pop cx
    pop bx
    pop ax
    ret
draw_char endp
remove_draw proc
    mov dl, snakeX   ; Column
    mov dh, snakeY   ; Row
    
    push ax
    push bx
    push cx
    push dx

    mov ah, 02h
    mov bh, 0
    int 10h

    mov ah, 09h
    mov al, ' '
    mov bl, 0Ch         ; red 
    mov cx, 1
    int 10h

    pop dx
    pop cx
    pop bx
    pop ax
    ret
remove_draw endp

 
 check_col proc
        ;checkear colisiones, if snake collides with something

    ret
    
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
  
end main
