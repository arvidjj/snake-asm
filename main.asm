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
    snakeSize db 1
    gameSize db 15
    fruit db 0
    fruitX db 27
    fruitY db 9
    score db 0
    screenBase dw 0B800h  ; VGA text mode
    waitTime db 2
    score_string DB 'Puntaje: ', '$'
    
    ; Jugador
	player_score_label_offset equ (screen_width-1d)*2d ;Posicion de la puntuacion 
	player_score db ?
	player_win_score equ 0FFh 
	
    ; snake
	; len X 2 
	currentDir db 2  ; 0: up, 1: down, 2: left, 3: right
	snake_len dw ?
	snake_body dw player_win_score + 3h dup(?)
	snake_previous_last_cell dw ? 
	fruit_body dw ?
	
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

       
	call iniciar_variables   
	call clear_screen
	call draw_square 

    gameloop:
        ;lea bx, score_string
        ;mov dx, 0109
        ;call writestringat
        call asyncinput    ;entrada del jugador
        call mover_snake          ;dibujar actores  
        call draw_snake	
        call EmptyKeyboardBuffer
        call check_col     ;verificar colisiones
        call check_fruit   ;decide si spawnear la fruta o no
        call delay         ;delay
        jmp gameloop

    exit:
    ; Salir
    mov ah, 4Ch
    int 21h
main endp 

iniciar_variables proc near
	mov word ptr [snake_previous_last_cell],screen_width*screen_hight*2d
	
	call iniciar_snake

	ret
iniciar_variables endp	

iniciar_snake proc near
    mov ax, 30       ; 20 (boundary x) + 10 (centro)

    mov bx, 8        ; 0 (boundary y) + 8 (centro)

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

    mov word ptr [snake_len], 8d ;en el arreglo, una porcion ocupa 2 bytes

    ret
iniciar_snake endp


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
    
    cmp al, 'w'     ;w arriba
    je moveup1  
    cmp al, 48h     ;flecha arriba  
    je moveup1          
    
    cmp al, 's'     ;s abajo
    je movedown1                   
    cmp al, 50h     ;flecha abajo
    je movedown1
    
    cmp al, 4Bh     ;a Izquierda
    je moveleft1                      
    cmp al, 'a'     ;flecha Izquierda
    je moveleft1 
    
    cmp al, 'd'     ;d Derecha
    je moveright1 
    cmp al, 4Dh     ;flecha Derecha
    je moveright1
    
    jmp no_input

moveup1:
    cmp currentDir, 1 ;opposing direction
    je no_input
    mov currentDir, 0
    jmp no_input

movedown1:
    cmp currentDir, 0 ;opposing direction
    je no_input
    mov currentDir, 1
    jmp no_input

moveleft1:
    cmp currentDir, 3 ;opposing direction
    je no_input
    mov currentDir, 2
    jmp no_input

moveright1:
    cmp currentDir, 2 ;opposing direction
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
   
mover_snake proc near
	push ax
	push bx
	; se debe eliminar la cola, guardar
	mov bx,snake_len
	sub bx, 2d
    mov ax, snake_body[bx]
	mov [snake_previous_last_cell],ax
	
	mov ax,snake_body[0h]
	call shift_right_array
	; derecha
	cmp byte ptr [currentDir],3
	jz shift_der
	; izquierda
	cmp byte ptr [currentDir],2
	jz shift_izq
	; arriba
	cmp byte ptr [currentDir],0
	jz shift_up
	; abajo
	cmp byte ptr [currentDir],1
	jz shift_down

	
	shift_der:
		add ax,2d
		jmp actualizar_cabeza
	shift_izq:
		sub ax, 2d
		jmp actualizar_cabeza
	shift_up:
		sub ax, screen_width*2d
		jmp actualizar_cabeza
	shift_down:
		add ax, screen_width*2d
		jmp actualizar_cabeza
		
actualizar_cabeza:
	;reemplazar la cabeza con la nueva coordenada
	mov snake_body[0h],ax
	
	pop bx
	pop ax
	ret
mover_snake endp

draw_snake proc near
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
    ;al es el ascii de la cabeza
    head_draw:
	mov ah, 7fh   ;color
	mov bx, snake_body[0d]
	mov es:[bx], ax         
	
	;si solo hay cabeza
	;cmp snake_len,2h
	;jz end_draw_snake                  
	
	;empezar bucle de dibujo del cuerpo
	;snake color(body)
	;mov al, 178d   
	mov al, 219d
	mov ah, 0fh
	
	mov si,2h
	draw_snake_loop:
		mov bx, snake_body[si]
		mov es:[bx], ax
		;siguiente posicion del array (+2 si)   
		;cada segmento contiene 2 bytes
		add si,2h
		cmp si, [snake_len]
		jnz draw_snake_loop
		
end_draw_snake:	
	pop bx
	pop si
	pop ax
	ret
draw_snake endp

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

;actualizar el arreglo de la snake para mover los elementos a la derecha
shift_right_array proc near
	push bx
	push ax
	push si
	
	mov si,[snake_len]
	sub si,2h
	l1:
		mov ax,snake_body[si - 2h]
		mov snake_body[si], ax
		;siguiente segmento
		sub si,2h
		cmp si,0h
		jnz l1
	pop si
	pop ax
	pop bx
	ret
shift_right_array endp   

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

    mov ax, snake_body[0]
    ;Y (fila)
    mov cx, screen_width   ; 80
    xor dx, dx             ; Limpiar DX
    div cx                 ; AX = direccion / 80, DX = direccion % 80
    mov dh, al             ; Guardar Y en DH (Y = AX / 80) 

    ;X (columna)
    mov ax, dx             ; AX ahora contiene el resto de la division anterior
    shr ax, 1              ; Dividir el resto entre 2 para obtener X
    mov dl, al             ; Guardar X en DL (X = resto / 2)

    ;limite izquierdo (columna minima)
    cmp dl, 20
    jl collision

    ;limite derecho (columna maxima)
    cmp dl, 40
    jg collision

    ;limite superior (fila minima)
    cmp dh, 0
    jl collision

    ;limite inferior (fila maxima)
    cmp dh, 30
    jg collision
    
    ;check colision de fruta  
    call readcharat
    call check_snake_col_fruit 

done_col: 
    pop ax
    pop dx
    ret  

collision:
    jmp exit
check_col endp

check_snake_col_fruit proc
    push ax
    push bx

    ;comparar coordenadas de la cabeza con la fruta
    mov ax, snake_body[0d]
    cmp ax, fruit_body
    jne done_check_fruit_col
    
    ;crecer
	mov ax,[snake_previous_last_cell]
	mov si,[snake_len]
	mov snake_body[si],ax
	add [snake_len],2d
	;score
	;inc byte ptr [player_score]
    
    ;si son las mismas aumentar
    call beep_sound
    inc score
    inc snakeSize
    mov fruit, 0
done_check_fruit_col:
    pop bx
    pop ax
    ret
check_snake_col_fruit endp


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
    ; Leer la direccion de memoria en base a coordenadas y retornar el caracter que está allí
    ; Parametros:
    ;   dh: Y (fila)
    ;   dl: X (columna)
    push ax
    push bx
    push di

    mov ah, 0
    mov al, dh     
    mov bh, screen_width  ; 80 columnas
    mul bh                ; Multiplicar fila por 80 columnas (cada columna tiene 2 bytes)

    xor bh, bh            ; Limpiar BH
    mov bl, dl      
    add ax, bx            ; Sumar columna

    shl ax, 1             ; Multiplicar por 2 (cada celda es de 2 bytes)

    mov bx, 0B800h        ; Dirección de segmento de memoria de video
    mov es, bx           
    mov di, ax            ; Dirección efectiva

    mov al, es:[di]       ; Leer valor ASCII en AL

    pop di
    pop bx
    pop ax
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
    cmp fruit, 0
    jne fruit_done
    ;se necesita un proc que genere un numero de
    ;20 a 40
    ;0 a 15   
    call generate_fruit 
    mov fruit, 1
    fruit_done:
    pop dx
    pop cx
    pop bx
    pop ax
    ret
check_fruit endp 

draw_fruit proc
    push ax
    push bx
    push cx
    push dx
    mov al, '*'
    mov ah, 2dh
	mov bx, fruit_body
	mov es:[bx], ax
    done_draw_fruit:
    pop dx
    pop cx
    pop bx
    pop ax
    ret
draw_fruit endp

generate_fruit proc
    mov ax, 25       ; x de la fruta

    mov bx, 3        ; y de la fruta

    mov cx, screen_width
    mul bx           ; ax = screen_width * center row
    add ax, 30       ; ax = offset + center column
    shl ax, 1        ; Each cell is 2 bytes
    mov fruit_body, ax
    
    call draw_fruit
    ret
generate_fruit endp


beep_sound proc
    mov ax, 0E07h  ; BIOS.Teletype BELL
    int 10h
    ret
beep_sound endp

end main
