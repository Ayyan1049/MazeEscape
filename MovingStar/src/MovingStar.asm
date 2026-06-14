[org 0x100]
jmp start

; --- Data Segment ---
; Direction: 0: Right, 1: Up, 2: Left, 3: Down
direction: dw 0 
init: dw 3920    ; Initial position of the player (Row 24, Col 40)
oldTimer: dd 0
oldKb: dd 0
tickcount: dw 0
endG: dw 0       ; Game State: 0=Playing, 1=Lost, 2=Won

; --- Subroutines ---

clrscr:
    push es
    push ax
    push cx
    push di
    mov ax, 0xb800
    mov es, ax      
    xor di, di      
    mov ax, 0x0720  ; space char in normal attribute (White on Black)
    mov cx, 2000    
    cld             
    rep stosw       
    pop di
    pop cx
    pop ax
    pop es
    ret

; --- Keyboard Interrupt Handler ---
key:
    push ax
    in al, 0x60
    
    cmp al, 48h
    jne check_right
    mov word [cs:direction], 1 ; Up
    jmp end_key

check_right:
    cmp al, 4Dh
    jne check_left
    mov word [cs:direction], 0 ; Right
    jmp end_key

check_left:
    cmp al, 4Bh
    jne check_down
    mov word [cs:direction], 2 ; Left
    jmp end_key

check_down:
    cmp al, 50h
    jne end_key
    mov word [cs:direction], 3 ; Down

end_key:
    mov al, 0x20
    out 0x20, al 
    pop ax
    iret

; --- Timer Interrupt Handler (Speed set to requirement of 2 ticks) ---
timer:
    push ax
    inc word [cs:tickcount]
    
    cmp word [cs:tickcount], 2
    jne e_timer
    mov word [cs:tickcount], 0
    
    push es
    push di
    push bx             
    push cx             
    mov ax, 0xB800
    mov es, ax
    
    ; 1. Clear current player position
    mov di, [cs:init]
    mov word[es:di], 0x0720 
    
    ; 2. Calculate new position (di)
    mov bx, [cs:direction]
    cmp bx, 0           
    je move_right
    cmp bx, 1           
    je move_up
    cmp bx, 2           
    je move_left
    
move_down:
    add di, 160       
    jmp check_boundary

move_right:
    add di, 2           
    jmp check_boundary
    
move_up:
    sub di, 160         
    jmp check_boundary
    
move_left:
    sub di, 2           
    
check_boundary:
    ; 3. Top/Bottom Boundary Check
    cmp di, 0
    jl gamEnd_lost_check 
    cmp di, 4000
    jge gamEnd_lost_check 

    ; 4. Stricter Collision/Win Check
    mov cx, [es:di]     
    
    ; Check for Goal (Red background word: 0x4420)
    cmp cx, 0x4420
    je gamWin           
    
    ; Check for Obstacle (Green background word: 0x2220)
    cmp cx, 0x2220
    je gamEnd_lost_check 

    ; 5. If safe, move the player
    mov word [es:di], 0x012A 
    mov [cs:init], di        

f_timer: 
    pop cx              
    pop bx              
    pop di
    pop es
e_timer:
    mov al, 0x20
    out 0x20, al 
    pop ax
    iret

gamWin:
    mov word [cs:endG], 2 
    jmp f_timer

gamEnd_lost_check:
    mov word [cs:endG], 1 
    jmp f_timer

; --- Obstacle Placement Subroutine ---
place_obstacles:
    push ax
    push di
    push es
    push dx
    push cx
    
    mov ax, 0xB800
    mov es, ax
    mov ax, 0x2220 ; Green Obstacle

    ; 1. Draw Right Boundary (Col 79)
    mov di, 158         
    mov cx, 25          
abc:
    mov [es:di], ax
    add di, 160         
    loop abc

    ; 2. Draw Internal Obstacles (approximate positions)
    mov di, (160*4 + 8*2) ; Vertical 1
    mov cx, 6
def1:
    mov [es:di], ax
    add di, 160
    loop def1

    mov di, (160*3 + 20*2) ; Horizontal 1
    mov cx, 10
def2:
    mov [es:di], ax
    add di, 2
    loop def2

    mov di, (160*10 + 20*2) ; Horizontal 2
    mov cx, 10
def3:
    mov [es:di], ax
    add di, 2
    loop def3

    mov di, (160*6 + 40*2) ; Vertical 2
    mov cx, 7
def4:
    mov [es:di], ax
    add di, 160
    loop def4

    mov di, (160*3 + 60*2) ; Vertical 3
    mov cx, 8
def5:
    mov [es:di], ax
    add di, 160
    loop def5
    
    mov di, (160*4 + 60*2) ; Horizontal 3
    mov cx, 10
def6:
    mov [es:di], ax
    add di, 2
    loop def6
    
    pop cx
    pop dx
    pop es
    pop di
    pop ax
    ret

; --- Game Message Display Subroutines ---

print_win:
    mov bp, win_msg
    mov si, 12*160 + 72 
    mov cx, 8           
    call print_string
    ret
    
print_lost:
    mov bp, lost_msg
    mov si, 12*160 + 70 
    mov cx, 9           
    call print_string
    ret

print_string:
    push ax
    push es
    push di
    push ds           
    push cs           
    pop ds            
    
    mov ax, 0xB800
    mov es, ax
    mov di, si        
    mov ah, 0x70      
.next_char:
    mov al, [bp]      
    inc bp            
    cmp al, 0
    je .done
    mov [es:di], ax     
    add di, 2           
    loop .next_char
.done:
    pop ds            
    pop di
    pop es
    pop ax
    ret

win_msg db 'Game Win', 0
lost_msg db 'Game Lost', 0

; --- Main Execution ---

start:
    call clrscr 
    call place_obstacles 
    
    ; Save old interrupt vectors
    mov ax, 0
    mov es, ax
    mov ax, [es:8h*4]
    mov bx, [es:8h*4+2]
    mov [oldTimer], ax
    mov [oldTimer+2], bx
    mov ax, [es:9h*4]
    mov bx, [es:9h*4+2]
    mov [oldKb], ax
    mov [oldKb+2], bx
    
    ; Set new interrupt vectors
    cli
    mov word[es:8h*4], timer
    mov word [es:8h*4+2], cs
    mov word[es:9h*4], key
    mov word [es:9h*4+2], cs
    
    ; Place Goal 
    mov ax, 0xB800
    mov es, ax
    mov di, 0
    mov ax, 0x4420 
    mov [es:di], ax
    
    ; Place Player 
    mov di, 3920 
    mov word [es:di] , 0x012A 
    sti 
    
start1:
    ; Game loop: HLT waits for timer or key interrupts
    cmp word [endG], 0
    jne end1 
    
    hlt        
    jmp start1 

end1:
    ; Game Over
    call clrscr
    
    ; Display Game Win/Lost Message
    cmp word [endG], 2
    je game_win_message
    
game_lost_message:
    call print_lost 
    jmp restore_vectors
    
game_win_message:
    call print_win 

restore_vectors:
    ; Restore old interrupt vectors (Safe Termination)
    mov ax, 0
    mov es, ax
    
    mov ax, [oldTimer]
    mov bx, [oldTimer+2]
    cli
    mov [es:8h*4], ax
    mov [es:8h*4+2], bx
    
    mov ax, [oldKb]
    mov bx, [oldKb+2]
    mov [es:9h*4], ax
    mov [es:9h*4+2], bx
    sti
    
    ; Exit to DOS
    mov ax, 0x4C00
    int 21h
