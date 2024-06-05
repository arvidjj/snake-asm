.model small
.stack 200h
.data
    message db 'Seleccione un nivel:', 0Dh, 0Ah, '1. Nivel 1(Facil)', 0Dh, 0Ah, '2. Nivel 2(Medio)', 0Dh, 0Ah, '3. Nivel 3(Dificil)', 0Dh, 0Ah, 'Su eleccion: $'
    invalid_message db 0Dh, 0Ah, 'Seleccion invalida. Intente nuevamente.', 0Dh, 0Ah, '$'
    nivel1_message db 0Dh, 0Ah, 'Ha seleccionado el Nivel 1.', 0Dh, 0Ah, '$'
    nivel2_message db 0Dh, 0Ah, 'Ha seleccionado el Nivel 2.', 0Dh, 0Ah, '$'
    nivel3_message db 0Dh, 0Ah, 'Ha seleccionado el Nivel 3.', 0Dh, 0Ah, '$'
    selectedLevel db ?  
    
    ;parte del contador
    contador dw 0
    mensaje db 'Puntuacion: $'
    numero db '0000$'
    
    loseMessage db 'Perdiste! $'
    
    ;arreglo de rng para valores aleatorios
    seedArray dw 155, 255, 300, 400, 500, 600, 700, 800, 900, 955, 1000, 1555
    seedArraySize equ 10
    seedPointer dw 0  
    attempts dw 0      ;guarda los intentos de spawnear una fruta
    
    ; Valores iniciarles
    color_level db 2fh  ;color del nivel
    player_score_color equ 9d   ;Color de la puntuacion
    screen_width equ 80d        ;tamanho de la pantalla
    screen_hight equ 25d 

    snakeSize db 1
    fruit db 0      ;boolean to check if fruit is in game
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
    
.code
main proc 
    reset:
    mov ax, @data
    mov ds, ax

    ;modo de video a 80x25 modo texto
    mov ax, 0003H
    int 10h
    
    call show_menu

       
    call iniciar_variables 
    call init_rng_array   ;Iniciar rng array pointer a 0
    call clear_screen     ;innecesario?
    call draw_square 
    call mostrar_puntuacion    
    ;si es dificil, poner obstaculos (doesn't work)
    ;cmp selectedLevel, 3
    ;jne gameloop
    ;call pintar_obstaculos 
    gameloop:
        call asyncinput    ;entrada del jugador
        call mover_snake          ;dibujar actores  
        call draw_snake    
        call EmptyKeyboardBuffer  ;limpiar buffer de teclado
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
    mov fruit, 0  
    mov currentDir, 3
    iniciar_snake:
    mov ax, 30       ; 20 (boundary x) + 10 (centro)

    mov bx, 8        ; 0 (boundary y) + 8 (centro)

    mov cx, screen_width
    mul bx           ; ax = screen_width * fila central
    add ax, 30       ; ax = offset + columna central
    shl ax, 1        ; cada parte del snake son 2 bytes
    
    ;hay que rellenar el arreglo con cada parte del cuerpo del snake
    mov word ptr snake_body[0d], ax
    sub ax, 2d
    mov word ptr snake_body[2d], ax
    sub ax, 2d
    mov word ptr snake_body[4d], ax
    sub ax, 2d
    mov word ptr snake_body[6d], ax

    mov word ptr [snake_len], 8d ;en el arreglo, una porcion ocupa 2 bytes

    ret
iniciar_variables endp  

; incrementar el contador
incrementar_contador proc
    inc contador
    call mostrar_puntuacion ;Mostrar valor
    ret
incrementar_contador endp

; mostrar la puntuacion
mostrar_puntuacion proc
    ; mover el cursor al inicio fila 0, columna 0
    mov ah, 02h
    mov bh, 0   
    mov dh, 0   ; Fila 0
    mov dl, 0   ; Columna 0
    int 10h

    ; limpiar la linea del puntaje
    mov cx, 20  ; numero de caracteres a limpiar
    mov al, ' ' ; espacio en blanco
    mov ah, 09h
    mov bh, 0
    int 10h

    ; mover el cursor al inicio de la linea del puntaje nuevamente
    mov ah, 02h
    mov bh, 0
    mov dh, 0
    mov dl, 0
    int 10h

    ; mostrar el mensaje
    mov dx, offset mensaje
    mov ah, 09h
    int 21h

    ; convertir el valor del contador a cadena de texto
    mov ax, contador
    call convertir_a_cadena

    ; mostrar el numero convertido
    mov dx, offset numero
    mov ah, 09h
    int 21h

    ret
mostrar_puntuacion endp


; procedimiento para convertir un numero de 16 bits a una cadena de texto
convertir_a_cadena proc
    ; AX contiene el numero a convertir
    mov cx, 4 ; Numero de digitos a convertir
    lea si, numero + 3 ; Apuntar al final de la cadena de numeros
conv_loop:
    mov dx, 0
    mov bx, 10
    div bx
    add dl, '0'
    mov [si], dl
    dec si
    loop conv_loop
    ret
convertir_a_cadena endp

show_menu proc
    ; mostrar el mensaje de seleccion de nivel
    lea dx, message
    mov ah, 09h
    int 21h

    ; Leer la seleccion del usuario
    mov ah, 01h
    int 21h

    ; Convertir el caracter ingresado a un numero
    sub al, '0'                             
    mov selectedLevel, al

    ; Verificar si la seleccion es valida
    cmp selectedLevel, 1
    jl invalid_selection
    cmp selectedLevel, 3
    jg invalid_selection

    ;Si La seleccion es valida, proceder segun el nivel seleccionado
    cmp selectedLevel, 1
    je nivel1
    cmp selectedLevel, 2
    je nivel2
    cmp selectedLevel, 3
    je nivel3

    ; Si se ingresa una seleccion invalida, mostrar un mensaje de error y volver a mostrar el menú
invalid_selection:
    mov ah, 09h ; especifica la funcion para escribir cadena
    lea dx, invalid_message
    int 21h
    jmp show_menu

nivel1:
    ; Configuracion especifica para el Nivel 1
    mov ah, 09h
    lea dx, nivel1_message
    int 21h 
    mov color_level, 3fh  ;color de bebe (facil) 
    mov waitTime, 20 ; tiempo de reloj(tiempo en el que se va mover el snake)
    jmp start_game

nivel2:
    ; Configuracion especifica para el Nivel 2
    mov ah, 09h
    lea dx, nivel2_message
    int 21h
    mov color_level, 2fh
    mov waitTime, 10
    jmp start_game

nivel3:
    ; Configuracion especifica para el Nivel 3
    mov ah, 09h
    lea dx, nivel3_message
    int 21h                
    mov color_level, 4fh  ;color infernal >:)     
    mov waitTime, 1
    jmp start_game

start_game:
    
    ret
show_menu endp  

pintar_obstaculos proc   
    push ax
    push bx
    push cx
    push dx
    mov bx, 60d + 4d*screen_width*2d

    mov al, '#'
    mov ah, 2ch   ;color
    mov es:[bx], ax 
    pop dx
    pop cx
    pop bx
    pop ax
    ret
pintar_obstaculos endp    

asyncinput proc 
    push ax
    mov ah, 01h
    int 16h
    jz no_input
    mov ah, 00h
    int 16h
    
    cmp al, 'w'     ;w arriba
    je moveup1  
    cmp ah, 48h     ;flecha arriba  
    je moveup1          
    
    cmp al, 's'     ;s abajo
    je movedown1                   
    cmp ah, 50h     ;flecha abajo
    je movedown1
    
    cmp ah, 4Bh     ;a Izquierda
    je moveleft1                      
    cmp al, 'a'     ;flecha Izquierda
    je moveleft1 
    
    cmp al, 'd'     ;d Derecha
    je moveright1 
    cmp ah, 4Dh     ;flecha Derecha
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
    
    ;eliminar la cola
    mov bx,[snake_previous_last_cell]
    mov al,0h   ;espacio vacio
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
    mov al, 219d    ;ascii de snake
    mov ah, 0fh     ; color branco
    
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
    
    ;se compara la cabeza DEL SNAKE
    mov ax, snake_body[0]
    ;Y (fila)
    mov cx, screen_width   ; 80
    xor dx, dx             ; limpiar DX
    div cx                 ; AX = direccion / 80, DX = direccion % 80
    mov dh, al             ; guardar Y en dh

    ;X (columna)
    mov ax, dx             ; AX ahora contiene el resto de la division anterior
    shr ax, 1              ; dividir el resto entre 2 para obtener X
    mov dl, al             ; guardar X en dl

    ;limite izquierdo (columna minima)
    cmp dl, 20
    jl collision_die

    ;limite derecho (columna maxima)
    cmp dl, 40
    jg collision_die

    ;limite superior (fila minima)
    cmp dh, 0
    jl collision_die

    ;limite inferior (fila maxima)
    cmp dh, 30
    jg collision_die
    
    ;check colision de fruta  
    call readcharat     ;NECESARIO
    call check_snake_col_fruit
    ;check colision consigo mismo  
    call check_snake_col_himself

done_col: 
    pop ax
    pop dx
    ret  

collision_die: 
    ;primero pintar la colision de rojo
    mov al, 184d
    mov ah, 05h   ;color
    mov bx, snake_body[0d]
    mov es:[bx], ax 
    ;luego hacer otra cosa
    ; limpiar la linea del puntaje
    mov cx, 20  ; numero de caracteres a limpiar
    mov al, ' ' ; espacio en blanco
    mov ah, 09h
    mov bh, 0
    int 10h

    ; mover el cursor al inicio de la linea del puntaje nuevamente
    mov ah, 02h
    mov bh, 0
    mov dh, 5
    mov dl, 25
    int 10h

    ; mostrar el mensaje de que perdio el juego
    mov dx, offset loseMessage
    mov ah, 09h
    int 21h
    
    ;reiniciar
    mov waitTime, 40 ; se reinicia el tiempo  
    call delay; le digo al delay que espere 
    call clear_screen ;limpio la pantalla
    jmp reset                       
check_col endp       

check_snake_col_himself proc
    ;solo se checkea si el caracter que se encuentra en la direccion de memoria la cual
    ;se va a mover la cabeza es del cuerpo de la serpiente
    push ax
    push bx  
    mov ax, snake_body[0]
    call read_char_at_addr
    cmp al, 219d 
    je collision_die
    pop bx
    pop ax
    ret
check_snake_col_himself endp

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
    int 1Ah   ;interrupcion 1ah, leer timer del sistema
    mov bx, dx
jmp_delay:
    int 1Ah  ; obtener el contador actual del sistema
    sub dx, bx ; resto el valor de bx y dx para obtener el tiempo que paso
    cmp dl, waitTime ;comparo el byte menos significativo
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

;procedimiento sacado del laboratorio, es muy rapido
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
    ; leer la direccion de memoria en base a coordenadas y retornar el caracter que está allí
    ; parametros:
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

check_fruit proc
    push ax
    push bx
    push cx  
    push dx 
    cmp fruit, 0 
    jg fruit_done ;si la fruta ya existe, skip
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

;iniciar puntero a 0
init_rng_array proc
    mov seedPointer, 0
    ret
init_rng_array endp   

;avanzar el puntero, esto puede ser llamado cada tic o cada spawn ( decision del programador)   
;inspirado en doom
get_next_random proc
    push bx
    push si

    ;obtener lo que esta apuntando el punteor ahroa y guardar en ax para retornar
    mov si, seedPointer
    mov ax, seedArray[si]

    ;avanzar el puntero
    add si, 2
    cmp si, seedArraySize * 2
    jl no_wrap
    ;wrap al llegar al final
    mov si, 0
no_wrap:
    mov seedPointer, si

    pop si
    pop bx
    ret
get_next_random endp

generate_fruit proc     
    mov attempts, 0
    new_position:
    cmp attempts, 100
    je failsafe_draw
    
    call get_next_random

    ; esta formula se asegura de que x caiga en las boundaries del juego    
    ;20 a 40
    xor dx, dx
    mov bx, 21  ; range_size (41 - 20 + 1)
    div bx      ; ax / bx, resultado in AX, lo que sobra in DX
    add dx, 20  ; add min_value (20)
    mov bx, dx  ; guardar la posicion X en bx 

    call get_next_random

    ; esta formula se asegura de que y caiga en las boundaries del juego 
    ;0 a 15
    xor dx, dx
    push bx
    mov bx, 16  ; range_size (16 - 0 + 1)
    div bx      ; ax / bx, resultado in AX, guardar la posicion Y en dx(lo que sobra)   
    pop bx      ; BX tiene X
    
    ;hallar direccion de memoria del video donde pintar la fruta (formula sacada de internet)
    mov ax, dx
    mov cx, screen_width
    mul cx      ; multiplicar Y por ancho de pantalla (DX * 80), se guarda en AX
    add ax, bx  ; agregar la posicion x (AX + BX)
    shl ax, 1   ; multiplicar por 2 debido a caracter/color de modo texto (AX * 2)
    mov fruit_body, ax  ; guardar el caluclo en fruit_body
    
    ;checkear si la serpiente esta en esa posicion, si no volver a probar 100 veces, si no se pudo, moverse
    add attempts, 1
    call read_char_at_addr
    cmp al, 219d     ;snake body ascii compare
    je new_position 
    
    call draw_fruit 
    
    failsafe_draw:
    

    ret
generate_fruit endp

draw_fruit proc
    push ax
    push bx
    push cx
    push dx
    mov al, '*' 
    cmp selectedLevel, 1
    je blue_f  
    cmp selectedLevel, 2
    je green_f    
    cmp selectedLevel, 3
    je red_f
    
    blue_f:
    mov ah, 3dh 
    jmp draw_f_f
    green_f:
    mov ah, 2dh 
    jmp draw_f_f
    red_f:
    mov ah, 4dh 
    jmp draw_f_f
    
    draw_f_f:
    mov bx, fruit_body
    mov es:[bx], ax
    pop dx
    pop cx
    pop bx
    pop ax
    ret
draw_fruit endp

; Esto servira para los obstaculos
; Leer el caracter ASCII en la direccion de memoria de video especificada
; Parametros:
;   ax: Direccion de memoria de video
; Resultado:
;   al: Caracter ASCII leido de la memoria de video
read_char_at_addr proc
    push bx
    push di

    mov bx, 0B800h        ; segmento de memoria de video en modo texto VGA
    mov es, bx
    mov di, ax            ; direccion efectiva

    ; leer el caracter ASCII en AL
    mov al, es:[di]

    pop di
    pop bx
    ret
read_char_at_addr endp

beep_sound proc
    mov ax, 0E07h  ; coloco el beep en ax
    int 10h ;hago la interrupcion para realizar el beep                           
    call incrementar_contador ; incrementamos el contador despues de comer
    ret
beep_sound endp

end main
