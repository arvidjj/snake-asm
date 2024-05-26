.model small

.data
    message db 'Seleccione un nivel:', 0Dh, 0Ah, '1. Nivel 1', 0Dh, 0Ah, '2. Nivel 2', 0Dh, 0Ah, '3. Nivel 3', 0Dh, 0Ah, 'Su eleccion: $'
    invalid_message db 0Dh, 0Ah, 'Seleccion invalida. Intente nuevamente.', 0Dh, 0Ah, '$'
    nivel1_message db 0Dh, 0Ah, 'Ha seleccionado el Nivel 1.', 0Dh, 0Ah, '$'
    nivel2_message db 0Dh, 0Ah, 'Ha seleccionado el Nivel 2.', 0Dh, 0Ah, '$'
    nivel3_message db 0Dh, 0Ah, 'Ha seleccionado el Nivel 3.', 0Dh, 0Ah, '$'
    selectedLevel db ?

    head db '^',10,10
    wallAscii db '$'
    snakeX db 29
    snakeY db 11
    prevSnakeX db 29
    prevSnakeY db 11
    body db 'O',10,11, 3*15 DUP(0)
    snakeSize db 1
    currentDir db 2  ; 0: up, 1: down, 2: left, 3: right
    gameSize db 15
    fruit db 0
    fruitX db 21
    fruitY db 7
    score db 0
    screenBase dw 0B800h  ; VGA text mode
    waitTime db 6
    snakeBodyX db 100 DUP(0) 
    snakeBodyY db 100 DUP(0) 
    score_string DB 'Puntaje: ', '$'
.stack
    dw 128 dup(0)
.code
main proc
    ; Inicializar segmento de datos
    mov ax, @data
    mov ds, ax

    ; Establecer modo de video a 80x25 modo texto
    mov ax, 0003H
    int 10h

    call show_menu

    call draw_square
    gameloop:
        lea bx, score_string
        mov dx, 0109
        call writestringat
        call asyncinput    ;entrada del jugador
        call draw          ;dibujar actores
        call EmptyKeyboardBuffer
        call check_col     ;verificar colisiones
        call delay         ;delar
        jmp gameloop

    exit:
    ; Salir
    mov ah, 4Ch
    int 21h
main endp

show_menu proc
    ; Mostrar el mensaje de selección de nivel
    lea dx, message
    mov ah, 09h
    int 21h

    ; Leer la selección del usuario
    mov ah, 01h
    int 21h

    ; Convertir el carácter ingresado a un número
    sub al, '0'
    mov selectedLevel, al

    ; Verificar si la selección es válida
    cmp selectedLevel, 1
    jl invalid_selection
    cmp selectedLevel, 3
    jg invalid_selection

    ; La selección es válida, proceder según el nivel seleccionado
    cmp selectedLevel, 1
    je nivel1
    cmp selectedLevel, 2
    je nivel2
    cmp selectedLevel, 3
    je nivel3

    ; Si se ingresa una selección inválida, mostrar un mensaje de error y volver a mostrar el menú
invalid_selection:
    mov ah, 09h
    lea dx, invalid_message
    int 21h
    jmp show_menu

nivel1:
    ; Configuración específica para el Nivel 1
    mov ah, 09h
    lea dx, nivel1_message
    int 21h
    jmp start_game

nivel2:
    ; Configuración específica para el Nivel 2
    mov ah, 09h
    lea dx, nivel2_message
    int 21h
    jmp start_game

nivel3:
    ; Configuración específica para el Nivel 3
    mov ah, 09h
    lea dx, nivel3_message
    int 21h
    jmp start_game

start_game:
    ; Aquí iría cualquier configuración adicional antes de comenzar el juego
    ret
show_menu endp

asyncinput proc
    mov ah, 01h
    int 16h
    jz return
    mov ah, 00h
    int 16h
    return:
    ret
asyncinput endp

input proc
    mov ah, 00h
    int 16h
    mov bl, al
    ret
input endp

update_previous_pos proc
    push ax
    push bx
    push cx
    push dx
    mov al, snakeX
    mov prevSnakeX, al
    mov al, snakeY
    mov prevSnakeY, al
    pop dx
    pop cx
    pop bx
    pop ax
    ret
update_previous_pos endp

draw proc
    call update_previous_pos
    cmp AH, 48h     ; Up arrow
    je moveup
    cmp AH, 50h     ; Down arrow
    je movedown
    cmp AH, 4Bh     ; Left arrow
    je moveleft
    cmp AH, 4Dh     ; Right arrow
    je moveright

    ;si no se presiona ninguna tecla, ir en la direccion actual
    cmp currentDir, 0
    je moveup
    cmp currentDir, 1
    je movedown
    cmp currentDir, 2
    je moveleft
    cmp currentDir, 3
    je moveright

moveup:
    sub snakeY, 1
    mov currentDir, 0
    mov al, '^'
    jmp draw_loop_snake

movedown:
    add snakeY, 1
    mov currentDir, 1
    mov al, 'v'
    jmp draw_loop_snake

moveleft:
    sub snakeX, 1
    mov currentDir, 2
    mov al, '<'
    jmp draw_loop_snake

moveright:
    add snakeX, 1
    mov currentDir, 3
    mov al, '>'
    jmp draw_loop_snake

draw_loop_snake:
    mov dl, snakeX   ; Columna
    mov dh, snakeY   ; Fila
    call draw_char

    mov dl, prevSnakeX
    mov dh, prevSnakeY
    mov al, ' '
    call draw_char

    mov dl, fruitX   ; Columna
    mov dh, fruitY   ; Fila
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
    cmp fruit, 0
    je done_draw_fruit
    mov al, '*'
    mov ah, 02h
    mov bh, 0
    int 10h

    mov ah, 09h
    mov al, al
    mov bl, 2fh         ; fruta
    mov cx, 1
    int 10h
    done_draw_fruit:
    pop dx
    pop cx
    pop bx
    pop ax
    ret
draw_fruit endp

print_score proc
    push ax
    push bx
    push cx
    push dx
    mov dl, 5
    mov dh, 5
    mov ah, 02h
    mov bh, 0
    int 10h

    mov ah, 09h
    mov al, score
    mov bl, 02fh         ; color del personaje
    mov cx, 1
    int 10h

    pop dx
    pop cx
    pop bx
    pop ax
    ret
print_score endp

clear_screen proc
    push ax
    push bx
    push cx
    push dx
    mov AH, 6H
    mov AL, 0
    mov BH, 7         ; Limpiar pantalla
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
    cmp snakeX, 20     ; limite x
    jl collision
    mov al, 40
    cmp snakeX, al
    jg collision
    cmp snakeY, 0      ; limite y
    jl collision
    mov al, 15
    cmp snakeY, al
    jg collision
    
    ;check colision de fruta 
    mov dh, snakeY
    mov dl, snakeX
    call readcharat
    cmp al, '*'
    jne done_col    
    call beep_sound
    inc score
    mov fruit, 0

done_col:
    ret

collision:
    jmp exit
check_col endp

delay proc
    mov ah, 00
    int 1Ah
    mov bx, dx
jmp_delay:
    int 1Ah
    sub dx, bx
    cmp dl, waitTime
    jl jmp_delay
    ret
delay endp

EmptyKeyboardBuffer:
  push ax
more:
  mov ah, 01h
  int 16h
  jz done
  mov ah, 00h
  int 16h
  jmp more
done:
  pop ax
  ret

draw_square proc
    push ax
    push bx
    push cx
    push dx
    mov al, 0
    mov ah, 6
    mov bh, 2fh  ; color
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

readcharat proc
    ;Leer la direccion de memoria en base a coordenadas y retornar el caracter que esta ahi
    ;parametros: 
    ;dh: Y 
    ;dl: X
    mov ah, 0           
    mov al, dh     
    mov bh, 80          
    mul bh              
    
    xor bh, bh          
    mov bl, dl      
    add ax, bx          

    shl ax, 1           

    mov bx, 0B800h     
    mov es, bx          
    mov di, ax          
    mov al, es:[di]     ; Leer valor ASCII en AL
    ret
readcharat endp


writestringat proc
    push dx
    mov ax, dx
    and ax, 0FF00H
    shr ax,1
    shr ax,1
    shr ax,1
    shr ax,1
    shr ax,1
    shr ax,1
    shr ax,1
    shr ax,1
    push bx
    mov bh, 160
    mul bh
    pop bx
    and dx, 0FFH
    shl dx,1
    add ax, dx
    mov di, ax
loop_writestringat:
    mov al, [bx]
    test al, al
    jz exit_writestringat
    mov es:[di], al
    inc di
    inc di
    inc bx
    jmp loop_writestringat
exit_writestringat:
    pop dx
    ret
writestringat endp

check_fruit proc
    push ax
    push bx
    push cx
    push dx
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
