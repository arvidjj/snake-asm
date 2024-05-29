.model small
.stack 200h
.data
    message db 'Seleccione un nivel:', 0Dh, 0Ah, '1. Nivel 1', 0Dh, 0Ah, '2. Nivel 2', 0Dh, 0Ah, '3. Nivel 3', 0Dh, 0Ah, 'Su eleccion: $'
    invalid_message db 0Dh, 0Ah, 'Seleccion invalida. Intente nuevamente.', 0Dh, 0Ah, '$'
    nivel1_message db 0Dh, 0Ah, 'Ha seleccionado el Nivel 1.', 0Dh, 0Ah, '$'
    nivel2_message db 0Dh, 0Ah, 'Ha seleccionado el Nivel 2.', 0Dh, 0Ah, '$'
    nivel3_message db 0Dh, 0Ah, 'Ha seleccionado el Nivel 3.', 0Dh, 0Ah, '$'
    selectedLevel db ?
    
    ; Valores iniciarles
	color_level equ 2fh  ;color del nivel
	player_score_color equ 9d   ;Color de la puntuacion
	screen_width equ 80d        ;tamanho de la pantalla
	screen_hight equ 25d 

    head db '^',10,10
    wallAscii db '$'
    snakeX db 29
    snakeY db 11
    prevSnakeX db 29
    prevSnakeY db 11
    snakeSize db 1
    currentDir db 2  ; 0: up, 1: down, 2: left, 3: right
    gameSize db 15
    fruit db 0
    fruitX db 27
    fruitY db 9
    score db 0
    screenBase dw 0B800h  ; VGA text mode
    waitTime db 6
    score_string DB 'Puntaje: ', '$'
    
    ; snake
	; len X 2
	snake_len dw ?
	snake_body dw player_win_score + 3h dup(?)
	snake_previous_last_cell dw ? 
	snake_direction db ?
	
	RIGHT equ 4Dh
	LEFT equ 4Bh
	UP equ 48h
	DOWN equ 50h
.code
main proc
    ; Inicializar segmento de datos
    mov ax, @data
    mov ds, ax

    ; Establecer modo de video a 80x25 modo texto
    mov ax, 0003H
    int 10h

    call show_menu

       
	call INIT_GAME   
	call clear_screen
	call draw_square
    gameloop:
        ;lea bx, score_string
        ;mov dx, 0109
        ;call writestringat
        call asyncinput    ;entrada del jugador
        call draw          ;dibujar actores  
        call PRINT_SNAKE	
        call EmptyKeyboardBuffer
        call check_col     ;verificar colisiones
        call delay         ;delar
        jmp gameloop

    exit:
    ; Salir
    mov ah, 4Ch
    int 21h
main endp 

INIT_GAME proc near
	mov byte ptr [snake_direction],RIGHT
	mov word ptr [snake_previous_last_cell],screen_width*screen_hight*2d
	
	call INIT_SNAKE_BODY

	ret
INIT_GAME endp	

INIT_SNAKE_BODY proc near
    mov ax, 20       ; Left boundary column
    add ax, 10       ; Center column = 30

    mov bx, 0        ; Top boundary row
    add bx, 8        ; Center row = 8

    mov cx, screen_width
    mul bx           ; ax = screen_width * center row
    add ax, 30       ; ax = offset + center column
    shl ax, 1        ; Each cell is 2 bytes

    mov word ptr snake_body[0d], ax
    sub ax, 2d
    mov word ptr snake_body[2d], ax
    sub ax, 2d
    mov word ptr snake_body[4d], ax
    sub ax, 2d
    mov word ptr snake_body[6d], ax

    mov word ptr [snake_len], 6d ;en el arreglo, una porcion ocupa 2 bytes

    ret
INIT_SNAKE_BODY endp


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
    push ax
    mov ah, 01h
    int 16h
    jz no_input
    mov ah, 00h
    int 16h
    cmp al, 'w'     ; Arriba
    je moveup1
    cmp al, 's'     ; Abajo
    je movedown1
    cmp al, 'a'     ; Izquierda
    je moveleft1
    cmp al, 'd'     ; Derecha
    je moveright1
    jmp no_input

moveup1:
    cmp currentDir, 1 ; No permitir moverse en dirección opuesta
    je no_input
    mov currentDir, 0
    jmp no_input

movedown1:
    cmp currentDir, 0 ; No permitir moverse en dirección opuesta
    je no_input
    mov currentDir, 1
    jmp no_input

moveleft1:
    cmp currentDir, 3 ; No permitir moverse en dirección opuesta
    je no_input
    mov currentDir, 2
    jmp no_input

moveright1:
    cmp currentDir, 2 ; No permitir moverse en dirección opuesta
    je no_input
    mov currentDir, 3
    jmp no_input

no_input: 
    pop ax
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
   
draw proc near
	push ax
	push bx
	; save snake_previous_last_cell(for backgroud repairing)
	mov bx,snake_len
	mov ax,snake_body[bx - 2d]
	mov [snake_previous_last_cell],ax
	
	mov ax,snake_body[0h]
	call SHR_ARRAY
	; RIGHT
	cmp byte ptr [currentDir],3
	jz MOVE_RIGHT
	; LEFT
	cmp byte ptr [currentDir],2
	jz MOVE_LEFT
	; UP
	cmp byte ptr [currentDir],0
	jz MOVE_UP
	; DOWN
	cmp byte ptr [currentDir],1
	jz MOVE_DOWN

	
	MOVE_RIGHT:
		add ax,2d
		jmp MOVE_TO_DIRECTION
	MOVE_LEFT:
		sub ax, 2d
		jmp MOVE_TO_DIRECTION
	MOVE_UP:
		sub ax, screen_width*2d
		jmp MOVE_TO_DIRECTION
	MOVE_DOWN:
		add ax, screen_width*2d
		jmp MOVE_TO_DIRECTION
		
MOVE_TO_DIRECTION:
	;add the new head cell
	mov snake_body[0h],ax
	
	pop bx
	pop ax
	ret
draw endp

PRINT_SNAKE proc near
	push ax
	push si
	push bx               
	
	mov bx,[snake_previous_last_cell]
	mov al,0h
	mov ah,color_level  ;repintar la cola con verde (fondo)
	mov es:[bx],ax
	
	;print head
	cmp currentDir, 0
    je moveup
    cmp currentDir, 1
    je movedown
    cmp currentDir, 2
    je moveleft
    cmp currentDir, 3  
    je moveright   
    moveup:
    mov al, '^'
    jmp head_draw

    movedown:
    mov al, 'v'
    jmp head_draw

    moveleft:
    mov al, '<'
    jmp head_draw

    moveright:
    mov al, '>'
    jmp head_draw  
    
    head_draw:
	mov ah, 0fh
	mov bx, snake_body[0d]
	mov es:[bx], ax
	;if the snake has no body(only head) - jump to the end of the function
	cmp snake_len,2h
	jz END_PRINT_SNAKE
	;print the rest if the snake
	;snake color(body)
	mov al, 176D
	mov ah, 10h
	
	mov si,2h
	PRINT_SNAKE_LOOP:
		mov bx, snake_body[si]
		mov es:[bx], ax
		;next iteration	
		add si,2h
		cmp si, [snake_len]
		jnz PRINT_SNAKE_LOOP
		
END_PRINT_SNAKE:	
	pop bx
	pop si
	pop ax
	ret
PRINT_SNAKE endp



draw_loop_snake:
    mov dl, fruitX   ; Columna
    mov dh, fruitY   ; Fila
    call check_fruit
    ret



generate_fruit proc
    ; Generar nuevas coordenadas para la fruta
    mov ax, 40 ; ancho del juego
    call random
    mov fruitX, al

    mov ax, 15 ; alto del juego
    call random
    mov fruitY, al

    ; Dibujar la nueva fruta
    call draw_fruit
    ret
generate_fruit endp

random proc
    ; Generar número aleatorio entre 0 y AX
    ; Suponiendo que AX contiene el máximo valor deseado
    xor dx, dx
    mov bx, 1234h
    mov cx, 5678h
    mul bx
    add ax, cx
    div bx
    ret
random endp

draw_char proc
    push ax
    push bx
    push cx
    push dx

    mov ah, 02h
    mov bh, 0
    int 10h

    mov ah, 09h
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

; the last cell overrided
SHR_ARRAY proc near
	push bx
	push ax
	push si
	
	mov si,[snake_len]
	sub si,2h
	L1:
		mov ax,snake_body[si - 2h]
		mov snake_body[si], ax
		;next iteration
		sub si,2h
		cmp si,0h
		jnz L1
	pop si
	pop ax
	pop bx
	ret
SHR_ARRAY endp   

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
    ;mov ax, 03h
	;int 10h 
    pop dx
    pop cx
    pop bx
    pop ax
    ret
clear_screen endp

check_col proc     
    push ax
    push dx  
      ; Obtener la dirección de la cabeza de la serpiente
    mov ax, snake_body[0h] 
    mov bx, ax

    ; Calcular Y (fila)
    mov cx, screen_width   ; 160 bytes por fila (80 columnas * 2 bytes por celda)
    xor dx, dx    ; Limpiar DX
    div cx        ; AX = dirección / 160, DX = dirección % 160
    mov dh, al    ; Guardar Y en DH (Y = AX / 160)

    ; Calcular X (columna)
    mov ax, dx    ; AX ahora contiene el resto de la división anterior
    shr ax, 1     ; Dividir el resto entre 2 para obtener X
    mov dl, al    ; Guardar X en DL (X = resto / 2)

    ; Comparar con el límite izquierdo (columna mínima)
    cmp dl, 20
    jl collision

    ; Comparar con el límite derecho (columna máxima)
    cmp dl, 40
    jg collision

    ; Comparar con el límite superior (fila mínima)
    cmp dh, 0
    jl collision

    ; Comparar con el límite inferior (fila máxima)
    cmp dh, 30
    jg collision
    
    ;check colision de fruta 
    mov dh, snakeY
    mov dl, snakeX
    call readcharat
    cmp al, '*'
    jne done_col    
    call beep_sound
    inc score
    inc snakeSize
    mov fruit, 0

done_col: 
    pop ax
    pop dx
    ret

collision:
    jmp exit
check_col endp  

; for now, N and S(E and W is fine)
CHECK_SNAKE_IN_BORDERS proc near
	push ax
	mov ax,snake_body[0h]
	;S
	cmp ax,screen_width*screen_hight*2h
	jb CHECK_SNAKE_IN_BORDERS_VALID

	call exit
	
CHECK_SNAKE_IN_BORDERS_VALID:	
	pop ax
	ret
CHECK_SNAKE_IN_BORDERS endp

delay proc         
    push ax
    push bx
    push dx
    mov ah, 00
    int 1Ah
    mov bx, dx
jmp_delay:
    int 1Ah
    sub dx, bx
    cmp dl, waitTime
    jl jmp_delay 
    pop ax
    pop bx
    pop dx
    ret
delay endp

EmptyKeyboardBuffer:
  push ax
  mov ah,0Ch
  int 21h	
  pop ax
  ret

draw_square proc
    push ax
    push bx
    push cx
    push dx
    mov al, 0
    mov ah, 6
    mov bh, color_level  ; color
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
    push ax
    push bx
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
    pop ax
    pop bx
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
