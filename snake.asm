org 100h
jmp start

; ================= DATA =================
snake_x db 10,9,8,0 dup(0)
snake_y db 12,12,12,0 dup(0)
snake_len db 3

dir_x db 1
dir_y db 0

food_x db 30
food_y db 10

score dw 0
level db 1
delay_val dw 3000
game_over db 0

score_text db 'Score:',0
level_text db 'Level:',0

; ================= CLEAR SCREEN =================
clrscr:
    mov ax,0B800h
    mov es,ax
    xor di,di
    mov cx,2000
    mov ax,0720h
cls1:
    stosw
    loop cls1
    ret

; ================= DRAW BORDER =================
draw_border:
    mov ax,0B800h
    mov es,ax

    mov di,0
    mov cx,80
top:
    mov ax,0723h
    stosw
    loop top

    mov di,24*160
    mov cx,80
bot:
    mov ax,0723h
    stosw
    loop bot

    mov di,160
    mov cx,23
side:
    mov ax,0723h
    mov [es:di],ax
    mov [es:di+158],ax
    add di,160
    loop side
    ret

; ================= DRAW CELL =================
draw_cell:
    push ax
    push bx
    mov ax,0B800h
    mov es,ax
    mov al,bh
    mov bl,80
    mul bl
    add ax,bx
    shl ax,1
    mov di,ax
    pop bx
    pop ax
    mov ah,07h
    mov [es:di],ax
    ret

; ================= DRAW SNAKE =================
draw_snake:
    mov cx,[snake_len]
    xor si,si
ds1:
    mov bl,[snake_x+si]
    mov bh,[snake_y+si]
    mov al,'o'
    cmp si,0
    jne ds2
    mov al,'O'
ds2:
    call draw_cell
    inc si
    loop ds1
    ret

; ================= DRAW FOOD =================
draw_food:
    mov bl,[food_x]
    mov bh,[food_y]
    mov al,'*'
    call draw_cell
    ret

; ================= MOVE SNAKE =================
move_snake:
    mov cl,[snake_len]
    dec cl
ms1:
    mov si,cx
    mov al,[snake_x+si-1]
    mov [snake_x+si],al
    mov al,[snake_y+si-1]
    mov [snake_y+si],al
    loop ms1

    mov al,[snake_x]
    add al,[dir_x]
    mov [snake_x],al

    mov al,[snake_y]
    add al,[dir_y]
    mov [snake_y],al
    ret

; ================= SELF COLLISION =================
check_self:
    mov cl,[snake_len]
    dec cl
    mov si,1
cs1:
    mov al,[snake_x]
    cmp al,[snake_x+si]
    jne cs2
    mov al,[snake_y]
    cmp al,[snake_y+si]
    je dead
cs2:
    inc si
    loop cs1
    ret

; ================= WALL + FOOD =================
check_collision:
    mov al,[snake_x]
    cmp al,1
    jbe dead
    cmp al,78
    jae dead

    mov al,[snake_y]
    cmp al,1
    jbe dead
    cmp al,23
    jae dead

    mov al,[snake_x]
    cmp al,[food_x]
    jne ok
    mov al,[snake_y]
    cmp al,[food_y]
    jne ok

    inc byte [snake_len]
    inc word [score]
    call beep_food
    call spawn_food
    call check_level
ok:
    ret

dead:
    mov byte [game_over],1
    call beep_dead
    ret

; ================= SPAWN FOOD =================
spawn_food:
    mov ah,00
    int 1Ah
    mov al,dl
    and al,63
    add al,8
    mov [food_x],al
    mov al,dh
    and al,15
    add al,5
    mov [food_y],al
    ret

; ================= INPUT =================
input:
    mov ah,01
    int 16h
    jz no_key
    mov ah,00
    int 16h
    cmp ah,48h
    je up
    cmp ah,50h
    je down
    cmp ah,4Bh
    je left
    cmp ah,4Dh
    je right
no_key:
    ret
up:    mov byte [dir_x],0  mov byte [dir_y],-1 ret
down:  mov byte [dir_x],0  mov byte [dir_y],1  ret
left:  mov byte [dir_x],-1 mov byte [dir_y],0  ret
right: mov byte [dir_x],1  mov byte [dir_y],0  ret

; ================= SCORE + LEVEL UI =================
draw_ui:
    mov ax,0B800h
    mov es,ax

    mov di,2
    mov si,score_text
    call print_str
    mov ax,[score]
    mov di,16
    call print_num

    mov di,30
    mov si,level_text
    call print_str
    mov al,[level]
    xor ah,ah
    mov di,44
    call print_num
    ret

print_str:
    lodsb
    or al,al
    jz ps_done
    mov ah,07h
    stosw
    jmp print_str
ps_done:
    ret

print_num:
    mov bx,10
    xor cx,cx
pn1:
    xor dx,dx
    div bx
    push dx
    inc cx
    or ax,ax
    jnz pn1
pn2:
    pop dx
    add dl,'0'
    mov dh,07h
    mov [es:di],dx
    add di,2
    loop pn2
    ret

; ================= LEVEL SYSTEM =================
check_level:
    mov ax,[score]
    cmp ax,5
    jb lvl1
    cmp ax,10
    jb lvl2
    mov word [delay_val],1000
    mov byte [level],3
    ret
lvl2:
    mov word [delay_val],2000
    mov byte [level],2
    ret
lvl1:
    mov word [delay_val],3000
    mov byte [level],1
    ret

; ================= SOUND =================
beep_food:
    in al,61h
    or al,03h
    out 61h,al
    mov cx,1500
bf: loop bf
    in al,61h
    and al,0FCh
    out 61h,al
    ret

beep_dead:
    in al,61h
    or al,03h
    out 61h,al
    mov cx,6000
bd: loop bd
    in al,61h
    and al,0FCh
    out 61h,al
    ret

; ================= DELAY =================
delay:
    mov cx,[delay_val]
d1: loop d1
    ret

; ================= MAIN =================
start:
    call spawn_food

main:
    call clrscr
    call draw_border
    call draw_ui
    call draw_food
    call draw_snake
    call input
    call move_snake
    call check_collision
    call check_self
    call delay

    cmp byte [game_over],1
    jne main

exit:
    mov ax,4C00h
    int 21h
