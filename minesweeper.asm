; minesweeper.asm - Minesweeper x64 for Windows
; Build: ml64.exe minesweeper.asm /link /subsystem:windows /entry:main kernel32.lib user32.lib gdi32.lib ucrt.lib

extrn ExitProcess: proc, GetLastError: proc, MessageBoxA: proc
extrn GetModuleHandleA: proc, wsprintfA: proc
extrn RegisterClassExA: proc
extrn CreateWindowExA: proc
extrn ShowWindow: proc
extrn UpdateWindow: proc
extrn GetMessageA: proc
extrn TranslateMessage: proc
extrn DispatchMessageA: proc
extrn DefWindowProcA: proc
extrn BeginPaint: proc
extrn EndPaint: proc
extrn LoadCursorA: proc
extrn SetBkMode: proc
extrn CreateSolidBrush: proc
extrn SelectObject: proc
extrn DeleteObject: proc
extrn Rectangle: proc
extrn Ellipse: proc
extrn TextOutA: proc
extrn PostQuitMessage: proc
extrn InvalidateRect: proc
extrn SetWindowPos: proc

; Constants
CS_VREDRAW equ 1
CS_HREDRAW equ 2
IDC_ARROW equ 32512
TRANSPARENT equ 1
WS_OVERLAPPEDWINDOW equ 0CF0000h
WS_VISIBLE equ 10000000h
SW_SHOW equ 5
SW_SHOWNORMAL equ 1
CW_USEDEFAULT equ 80000000h
HWND_TOPMOST equ -1
SWP_NOMOVE equ 2
SWP_NOSIZE equ 1

CELL_SIZE equ 40
COLS equ 9
ROWS equ 9
MINES equ 9
WIN_W equ COLS*CELL_SIZE + 16
WIN_H equ ROWS*CELL_SIZE + 38

; Offsets for WNDCLASSEXA (manual, x64)
WNDCLASSEXA_cbSize equ 0
WNDCLASSEXA_style equ 4
WNDCLASSEXA_lpfnWndProc equ 8
WNDCLASSEXA_cbClsExtra equ 16
WNDCLASSEXA_cbWndExtra equ 20
WNDCLASSEXA_hInstance equ 24
WNDCLASSEXA_hIcon equ 32
WNDCLASSEXA_hCursor equ 40
WNDCLASSEXA_hbrBackground equ 48
WNDCLASSEXA_lpszMenuName equ 56
WNDCLASSEXA_lpszClassName equ 64
WNDCLASSEXA_hIconSm equ 72
SIZEOF_WNDCLASSEXA equ 80

; Offsets for PAINTSTRUCT
SIZEOF_PAINTSTRUCT equ 72

; Offsets for MSG
MSG_message equ 8
MSG_wParam equ 16
SIZEOF_MSG equ 48

.data
className db "MineClass",0
windowName db "Minesweeper",0
goText db "GAME OVER",0
winText db "YOU WIN",0
board db ROWS*COLS dup(0)
errorTitle db "Error", 0
errorFmt db "Failed with code: %d", 0
gameOver db 0
gameWin db 0
seed dd 12345

.data?
hInst dq ?
hwndMain dq ?
wc db SIZEOF_WNDCLASSEXA dup(?)
ps db SIZEOF_PAINTSTRUCT dup(?)
msg db SIZEOF_MSG dup(?)
errorBuf db 64 dup(?)

.code

GetCellAddr proc
    imul ecx, COLS
    add ecx, edx
    mov rax, offset board
    add rax, rcx
    ret
GetCellAddr endp

myrand proc
    mov eax, seed
    imul eax, eax, 1103515245
    add eax, 12345
    mov seed, eax
    ret
myrand endp

DrawCell proc row:dword, col:dword, hdc:qword
    mov eax, col
    imul eax, CELL_SIZE
    mov r10d, eax
    mov eax, row
    imul eax, CELL_SIZE
    mov r11d, eax

    mov ecx, row
    mov edx, col
    call GetCellAddr
    movzx r12d, byte ptr [rax]

    test r12b, 10h
    jnz cell_open
    test r12b, 20h
    jnz cell_flag
    mov r8d, 0C0C0C0h
    jmp draw_bg
cell_flag:
    mov r8d, 0FF6666h
    jmp draw_bg
cell_open:
    mov r8d, 0E0E0E0h
draw_bg:
    mov ecx, r8d
    sub rsp, 32
    call CreateSolidBrush
    add rsp, 32
    mov r13, rax

    mov rcx, hdc
    mov rdx, r13
    call SelectObject
    mov r14, rax

    mov rcx, hdc
    mov edx, r10d
    mov r8d, r11d
    mov r9d, r10d
    add r9d, CELL_SIZE
    sub rsp, 40
    mov eax, r11d
    add eax, CELL_SIZE
    mov [rsp+32], eax
    call Rectangle
    add rsp, 40

    mov rcx, hdc
    mov rdx, r14
    call SelectObject
    mov rcx, r13
    call DeleteObject

    test r12b, 10h
    jz cell_done
    and r12b, 0Fh
    cmp r12b, 9
    je draw_mine
    cmp r12b, 0
    je cell_done

    add r12b, '0'
    sub rsp, 16
    mov byte ptr [rsp], r12b

    mov rcx, hdc
    mov edx, r10d
    add edx, 14
    mov r8d, r11d
    add r8d, 8
    lea r9, [rsp]

    sub rsp, 40
    add edx, 8
    mov r8d, r11d
    add r8d, 8
    mov r9d, r10d
    add r9d, 32
    sub rsp, 40
    mov eax, r11d
    add eax, 32
    mov [rsp+32], eax
    call TextOutA
    add rsp, 40
    jmp cell_done

draw_mine:
    mov rcx, hdc
    mov edx, r10d
    add edx, 8
    mov r8d, r11d
    add r8d, 8
    mov r9d, r10d
    add r9d, 32
    mov eax, r11d
    add eax, 32
    mov [rsp+32], eax
    call Ellipse
    add rsp, 40

cell_done:
    ret
DrawCell endp

CountMines proc row:dword, col:dword
    xor r10d, r10d
    mov r8d, -1
cm_r:
    cmp r8d, 1
    jg cm_done
    mov r9d, -1
cm_c:
    cmp r9d, 1
    jg cm_inc_r
    mov eax, row
    add eax, r8d
    mov ebx, col
    add ebx, r9d
    cmp eax, 0
    jl cm_skip
    cmp eax, ROWS
    jge cm_skip
    cmp ebx, 0
    jl cm_skip
    cmp ebx, COLS
    jge cm_skip
    mov ecx, eax
    mov edx, ebx
    push r8
    push r9
    call GetCellAddr
    pop r9
    pop r8
    movzx eax, byte ptr [rax]
    and al, 0Fh
    cmp al, 9
    jne cm_skip
    inc r10d
cm_skip:
    inc r9d
    jmp cm_c
cm_inc_r:
    inc r8d
    jmp cm_r
cm_done:
    mov eax, r10d
    ret
CountMines endp

Reveal proc row:dword, col:dword
    cmp gameOver, 1
    je rev_end
    cmp row, 0
    jl rev_end
    cmp row, ROWS
    jge rev_end
    cmp col, 0
    jl rev_end
    cmp col, COLS
    jge rev_end

    mov ecx, row
    mov edx, col
    call GetCellAddr
    movzx ebx, byte ptr [rax]
    test bl, 10h
    jnz rev_end
    test bl, 20h
    jnz rev_end

    or bl, 10h
    mov [rax], bl

    and bl, 0Fh
    cmp bl, 9
    jne not_mine
    mov gameOver, 1
    jmp rev_end

not_mine:
    push rax
    mov ecx, row
    mov edx, col
    call CountMines
    pop rdx
    movzx ebx, byte ptr [rdx]
    and bl, 0F0h
    or bl, al
    mov [rdx], bl
    cmp al, 0
    jne rev_end

    mov r8d, -1
rev_r:
    cmp r8d, 1
    jg rev_end
    mov r9d, -1
rev_c:
    cmp r9d, 1
    jg rev_inc_r
    push r8
    push r9
    mov ecx, row
    add ecx, r8d
    mov edx, col
    add edx, r9d
    call Reveal
    pop r9
    pop r8
    inc r9d
    jmp rev_c
rev_inc_r:
    inc r8d
    jmp rev_r
rev_end:
    ret
Reveal endp

CheckWin proc
    mov gameWin, 1
    mov rax, offset board
    mov rcx, rax
    xor edx, edx
cw_loop:
    cmp edx, ROWS*COLS
    jge cw_done
    movzx eax, byte ptr [rcx + rdx]
    test al, 10h
    jz cw_closed
    and al, 0Fh
    cmp al, 9
    jne cw_next
    mov gameWin, 0
    jmp cw_done
cw_closed:
    and al, 0Fh
    cmp al, 9
    je cw_next
    mov gameWin, 0
    jmp cw_done
cw_next:
    inc edx
    jmp cw_loop
cw_done:
    ret
CheckWin endp

InitBoard proc
    rdtsc
    mov seed, eax
    mov rax, offset board
    mov rdi, rax
    mov ecx, ROWS*COLS
    xor al, al
    rep stosb
    mov r12d, MINES
plant:
    cmp r12d, 0
    je plant_done
    call myrand
    xor edx, edx
    mov ecx, ROWS*COLS
    div ecx
    mov rax, offset board
    cmp byte ptr [rax + rdx], 9
    je plant
    mov byte ptr [rax + rdx], 9
    dec r12d
    jmp plant
plant_done:
    mov gameOver, 0
    mov gameWin, 0
    mov rcx, hwndMain
    xor edx, edx
    call InvalidateRect
    ret
InitBoard endp

WndProc proc hwnd:qword, umsg:dword, wparam:qword, lparam:qword
    cmp umsg, 2
    je wm_destr
    cmp umsg, 1
    je wm_creat
    cmp umsg, 0Fh
    je wm_pnt
    cmp umsg, 201h
    je wm_lclk
    cmp umsg, 204h
    je wm_rclk

    sub rsp, 40
    call DefWindowProcA
    add rsp, 40
    ret

wm_destr:
    xor ecx, ecx
    call PostQuitMessage
    xor eax, eax
    ret

wm_creat:
    ; Выделяем теневое пространство перед вызовом
    sub rsp, 32 
    call InitBoard
    add rsp, 32 
    xor eax, eax
    ret

wm_pnt:
    sub rsp, 40 ; shadow space + align
    lea rdx, ps
    mov rcx, hwnd
    call BeginPaint
    add rsp, 40
    mov r12, rax

    sub rsp, 32 ; shadow space
    mov ecx, r12d
    mov edx, TRANSPARENT
    call SetBkMode
    add rsp, 32
    xor r13d, r13d
wp_r:
    cmp r13d, ROWS
    jge wp_done
    xor r14d, r14d
wp_c:
    cmp r14d, COLS
    jge wp_inc_r
    mov ecx, r13d
    mov edx, r14d
    mov r8, r12
    call DrawCell
    inc r14d
    jmp wp_c
wp_inc_r:
    inc r13d
    jmp wp_r
wp_done:
    cmp gameOver, 1
    jne chk_w
    mov ecx, r12d
    mov edx, WIN_W/2 - 40
    mov r8d, WIN_H/2
    lea r9, goText
    sub rsp, 40
    mov qword ptr [rsp+32], 9
    call TextOutA
    add rsp, 40
    jmp ep
chk_w:
    cmp gameWin, 1
    jne ep
    mov ecx, r12d
    mov edx, WIN_W/2 - 30
    mov r8d, WIN_H/2
    lea r9, winText
    sub rsp, 40
    mov qword ptr [rsp+32], 7
    call TextOutA
    add rsp, 40
ep:
    mov rcx, hwnd
    sub rsp, 40 ; shadow space + align
    lea rdx, ps
    call EndPaint
    add rsp, 40
    xor eax, eax
    ret

wm_lclk:
    cmp gameOver, 1
    je click_done
    cmp gameWin, 1
    je click_done
    mov eax, dword ptr lparam
    and eax, 0FFFFh
    xor edx, edx
    mov ecx, CELL_SIZE
    div ecx
    mov r15d, eax
    mov eax, dword ptr lparam
    shr eax, 16
    xor edx, edx
    mov ecx, CELL_SIZE
    div ecx
    mov r14d, eax
    mov ecx, r14d
    mov edx, r15d
    sub rsp, 32 ; shadow space
    call Reveal
    call CheckWin
    add rsp, 32
    sub rsp, 32 ; shadow space
    mov rcx, hwnd
    xor edx, edx
    call InvalidateRect
    add rsp, 32
    jmp click_done

wm_rclk:
    cmp gameOver, 1
    je click_done
    cmp gameWin, 1
    je click_done
    mov eax, dword ptr lparam
    and eax, 0FFFFh
    xor edx, edx
    mov ecx, CELL_SIZE
    div ecx
    mov r15d, eax
    mov eax, dword ptr lparam
    shr eax, 16
    xor edx, edx
    mov ecx, CELL_SIZE
    div ecx
    mov r14d, eax
    mov ecx, r14d
    mov edx, r15d
    sub rsp, 32 ; shadow space
    call GetCellAddr
    add rsp, 32
    movzx ebx, byte ptr [rax]
    test bl, 10h
    jnz click_done
    xor bl, 20h
    mov [rax], bl
    sub rsp, 32 ; shadow space
    mov rcx, hwnd
    xor edx, edx
    call InvalidateRect
    add rsp, 32

click_done:
    xor eax, eax
    ret
WndProc endp

; Процедура для вывода кода последней ошибки
ShowLastError proc
    call GetLastError
    lea rdx, errorFmt
    mov r8d, eax
    lea rcx, errorBuf
    sub rsp, 32 ; shadow space
    call wsprintfA
    add rsp, 32
    xor ecx, ecx ; hwnd
    lea rdx, errorBuf
    lea r8, errorTitle
    mov r9d, 0 ; MB_OK
    sub rsp, 32 ; shadow space
    call MessageBoxA
    add rsp, 32
    ret
ShowLastError endp

main proc
    push rbp
    mov rbp, rsp
    ; Выделяем 32 байта теневого пространства + 8 байт для выравнивания.
    ; Итого 40 байт. RSP становится (RSP_initial - 8 - 40), что кратно 16.
    sub rsp, 40
    xor ecx, ecx
    call GetModuleHandleA
    mov hInst, rax ; Сохраняем hInst
    lea rdi, wc
    mov dword ptr [rdi+WNDCLASSEXA_cbSize], SIZEOF_WNDCLASSEXA
    mov dword ptr [rdi+WNDCLASSEXA_style], CS_HREDRAW or CS_VREDRAW
    lea rax, WndProc
    mov [rdi+WNDCLASSEXA_lpfnWndProc], rax
    mov dword ptr [rdi+WNDCLASSEXA_cbClsExtra], 0
    mov dword ptr [rdi+WNDCLASSEXA_cbWndExtra], 0
    mov rax, hInst
    mov [rdi+WNDCLASSEXA_hInstance], rax
    mov qword ptr [rdi+WNDCLASSEXA_hIcon], 0
    sub rsp, 32 ; shadow space
    mov ecx, IDC_ARROW
    call LoadCursorA
    mov [rdi+WNDCLASSEXA_hCursor], rax
    add rsp, 32
    mov qword ptr [rdi+WNDCLASSEXA_hbrBackground], 6
    mov qword ptr [rdi+WNDCLASSEXA_lpszMenuName], 0
    lea rax, className
    mov [rdi+WNDCLASSEXA_lpszClassName], rax
    mov qword ptr [rdi+WNDCLASSEXA_hIconSm], 0
    lea rcx, wc
    call RegisterClassExA
    test eax, eax
    jz fatal_error_debug

    mov r9d, WS_OVERLAPPEDWINDOW or WS_VISIBLE ; dwStyle
    lea r8, windowName                         ; lpWindowName
    lea rdx, className                         ; lpClassName
    xor ecx, ecx                               ; dwExStyle

    ; Выделяем место для 8 стековых аргументов + 32 байта теневого пространства.
    ; 8*8 + 32 = 96, что кратно 16.
    sub rsp, 96
    mov dword ptr [rsp+32], CW_USEDEFAULT      ; X (arg 5)
    mov dword ptr [rsp+40], CW_USEDEFAULT      ; Y (arg 6)
    mov dword ptr [rsp+48], WIN_W              ; nWidth (arg 7)
    mov dword ptr [rsp+56], WIN_H              ; nHeight (arg 8)
    mov qword ptr [rsp+64], 0                  ; hWndParent (arg 9)
    mov qword ptr [rsp+72], 0                  ; hMenu (arg 10)
    mov rax, hInst
    mov [rsp+80], rax                          ; hInstance (arg 11)
    mov qword ptr [rsp+88], 0                  ; lpParam (arg 12)
    call CreateWindowExA
    add rsp, 96                                ; Очищаем стек
    test rax, rax
    jz fatal_error_debug
    mov hwndMain, rax

    mov rcx, hwndMain
    sub rsp, 32 ; shadow space
    mov edx, 5 ; SW_SHOW
    call ShowWindow
    add rsp, 32
    sub rsp, 32 ; shadow space
    mov rcx, hwndMain
    call UpdateWindow
    add rsp, 32
mloop:
    lea rcx, msg
    xor edx, edx
    xor r8d, r8d
    xor r9d, r9d
    call GetMessageA
    test eax, eax ; Проверяем на 0 (WM_QUIT) или -1 (ошибка)
    jle done      ; Выходим, если 0 или -1
    lea rcx, msg
    sub rsp, 32 ; shadow space
    call TranslateMessage
    add rsp, 32
    sub rsp, 32 ; shadow space
    lea rcx, msg
    call DispatchMessageA
    add rsp, 32
    jmp mloop
done:
    cmp eax, 0
    jne fatal_error_debug ; Если GetMessageA вернул -1, показать ошибку
    mov ecx, dword ptr [msg + MSG_wParam]
    mov rsp, rbp
    pop rbp
    call ExitProcess
main endp
fatal_error_debug:
    call ShowLastError
    mov ecx, 1
    mov rsp, rbp
    pop rbp
    call ExitProcess

end