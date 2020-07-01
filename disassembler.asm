org 0x8000

; Global Initialisations
%define WIDTH 320
%define HEIGHT 200
%define CUSTOM_IMAGE_SIZE 20 ; 20x20 images only
%define BG_COLOR 0x00
%define BULLET_LENGTH 0x05


GRAPHIC_MEM_A dw 0xA000 ; wont work as macro

; init 320x200 with 256 colors video mode
mov ah, 0x00
mov al, 0x13
int 0x10

mov es, word [GRAPHIC_MEM_A]

call fill_screen
mega_loop:
    pusha

; delay
    MOV     CX, 0x00 ;0FH
    MOV     DX, 4240H
    MOV     AH, 86H
    INT     15H

; change entire screen color
; clears the entire VGA memory space
    ; xor di, di
    ; mov cx, WIDTH*HEIGHT
    ; mov al, 0x0
    ; rep stosb

; draw boundries
xor di,di
mov cx, HEIGHT-1
loopyp:
    add di, WIDTH
    mov [es:di], al
    loop loopyp

mov cx, WIDTH-1
mov al, 0x01
CLD
rep stosb

mov cx, HEIGHT-1
loopyn:
    sub di, WIDTH
    mov [es:di], al
    loop loopyn

mov cx, WIDTH-1
mov al, 0x01
STD
rep stosb
; remove bullets
mov al, BG_COLOR
call draw_bullets

; remove ship
mov di, BG_COLOR
call draw_ship


; check ks
mov ah, 0x01
int 16h
JNZ ks_avail
JMP ks_na
ks_avail:
    mov ah, 0x00
    int 16h
    cmp al, 'w' ; stop moving
    JZ move_up
    cmp al, 'a' ; stop moving
    JZ move_left
    cmp al, 's' ; stop moving
    JZ move_down
    cmp al, 'd' ; stop moving
    JZ move_right
    JMP ks_na
    move_down:
        inc byte [player+Player.ship_y]
        JMP ks_na
    move_left:
        dec byte [player+Player.ship_x]
        JMP ks_na
    move_up:
        dec byte [player+Player.ship_y]
        JMP ks_na
    move_right:
        inc byte [player+Player.ship_x]
        JMP ks_na
ks_na:
mov di, 0xFFFF
call draw_ship


; mov si, [player + Player.bullet_index]
;sub [player + Player.bullet_xy], word WIDTH
mov si, [player + Player.bullet_index]
cmp si, 0
JZ nope

;move bullets
mov si, 0
draw_bullets_loop1:
    cmp [player + Player.bullet_xy + si], word WIDTH * BULLET_LENGTH* 2
    JGE draw_bullets_sub

    mov di, [player + Player.bullet_index]
    mov di, [player + Player.bullet_xy + di - 2]
    mov [player + Player.bullet_xy +si], di
    sub word [player + Player.bullet_index], 2
    cmp word [player + Player.bullet_index], 0
    JZ nope
    cmp [player + Player.bullet_xy + si], word WIDTH * BULLET_LENGTH* 2
    JL draw_bullets_loop1

draw_bullets_sub: 
    sub [player + Player.bullet_xy + si], word WIDTH * BULLET_LENGTH* 2
    add word si, 2
    cmp si, [player + Player.bullet_index]
    JL draw_bullets_loop1

nope:

mov al, 0x04
call draw_bullets

popa
JMP mega_loop

draw_ship:
    push di
    xor di, di
    add di, [player + Player.ship_x]
    mov ax, [player + Player.ship_y]
    imul ax, WIDTH
    add di, ax
    push di
    
    ; add fire!!
    add di, CUSTOM_IMAGE_SIZE/2
    mov si, [player + Player.bullet_index]
    mov word [player + Player.bullet_xy + si], di
    add word [player + Player.bullet_index], 2
    
    pop di

    mov cx, 400
    mov si, test_image
    mov dx, 0
    CLD
    loop_:
        pop ax
        push ax
        CMP ax, BG_COLOR
        JZ dont_load
        lodsb ; load byte from [si] to al, inc si
        dont_load:

cmp dx, CUSTOM_IMAGE_SIZE ; works for 20x20 images
        JL same_row
        add di, WIDTH
        sub di, dx
        xor dx, dx
    same_row:
        CLD
        inc dx
        stosb ; save byte from al to [di], inc di

        ;mov [es:di], byte 0x04 ; works the same as above
        ;inc di ; --do--
        loop loop_
    pop di
    ret

; Draw bullets
draw_bullets:
;    push bx
;    pusha

; mov di, [player + Player.bullet_xy]
; mov [es:di], byte 0x04

    mov si, 0
    cmp si, [player + Player.bullet_index]
    JZ draw_bullets_ret

draw_bullets_loop:
    mov di, [player + Player.bullet_xy + si]

    mov bx, BULLET_LENGTH
make_bullet:
    ; cmp di, 0
    ; JL dont_make_bullet
    cmp di, 0
    JE dont_make_bullet
    mov [es:di], byte al
    dont_make_bullet:

sub di, WIDTH

    dec bx
    cmp bx, 0
    JNZ make_bullet

    add si, 2
    cmp si, [player + Player.bullet_index]
    JL draw_bullets_loop

draw_bullets_ret:
;    popa
    ret

fill_screen:
    xor di, di
    mov cx, WIDTH*HEIGHT
    mov al, BG_COLOR
    rep stosb
    ret

; no code execution after this
; bss and data segments
exit:

struc Player
    .ship_x: resw 1
    .ship_y: resw 1
    ; .fire_rate: resb 1
    .bullet_xy: times 100 resw 1
    .bullet_index: resw 1 ;resb wont work
endstruc

player:
istruc Player
    at Player.ship_x, dw WIDTH/2 - CUSTOM_IMAGE_SIZE/2
    at Player.ship_y, dw ( HEIGHT/2 - CUSTOM_IMAGE_SIZE/2 )
    ; at Player.fire_rate, db 1
    at Player.bullet_xy, times 100 dw 0
    at Player.bullet_index, dw 0  ; b wont work
iend

;times 200 db 1

test_image: incbin "enemy_ship.bin"  ; needs to be at the top of .bss/data section idk why
len EQU $-test_image

times 512*8 - ($-$$) db 0