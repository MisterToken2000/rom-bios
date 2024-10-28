org 0
rom_size_multiple_of equ 512
bits 16

; PCI Expansion Rom Header
db 0x55, 0xAA                    ; signature
db rom_size/512                  ; initialization size in 512-byte blocks
entry_point: jmp start

start:
    push CS
    pop DS
    call cls

    ; Выводим сообщение BIOS
    mov AX, bios_msg
    call puts
    mov AX, info_msg
    call puts
    mov AX, menu_msg
    call puts

    ; Основной цикл
main_loop:
    call get_input
    jmp main_loop

cls:
    ; Очистка экрана
    mov AH, 06h
    mov AL, 0
    mov BH, 0x3F            ; 07h
    mov CH, 0
    mov CL, 0
    mov DH, 24
    mov DL, 79
    int 10h

    ; Перемещение курсора в начало экрана
    mov DL, 0
    mov DH, 0
    mov BH, 0               ; номер страницы
    mov AH, 02h             ; установка позиции курсора
    int 10h
    ret

puts:
    push AX
    push BX
    mov BX, AX
puts_loop:
    mov AL, [BX]
    cmp AL, 0
    jz end_puts
    call putc
    inc BX
    jmp puts_loop
end_puts:
    pop BX
    pop AX
    ret

putc:
    pusha
    cmp AL, `\n`
    jz putc_nl
    cmp AL, `\r`
    jz putc_nl
    jmp putc_print_char

putc_nl:
    mov AH, 03h             ; получение текущей позиции курсора
    mov BH, 0               ; номер страницы
    int 10h
    mov DL, 0               ; переход на начало строки
    inc DH                  ; переход на следующую строку
    cmp DH, 24              ; проверка на выход за границу экрана
    jle putc_set_cursor

    ; Прокрутка на одну строку вверх
    mov AH, 06h
    mov AL, 1
    mov BH, 0x3F
    mov CH, 0
    mov CL, 0
    mov DH, 24
    mov DL, 79
    int 10h
    mov DH, 24              ; курсор на последней строке

putc_set_cursor:
    mov AH, 02h             ; установка позиции курсора
    int 10h
    popa
    ret

putc_print_char:
    mov AH, 09h
    mov AL, AL              ; символ для вывода
    mov BL, [cur_style]
    mov BH, 0               ; номер страницы
    mov CX, 1               ; количество символов
    int 10h

    ; Переход на следующую позицию
    mov AH, 03h             ; получение текущей позиции курсора
    mov BH, 0               ; номер страницы
    int 10h
    inc DL                  ; увеличение столбца
    cmp DL, 79
    jle putc_set_cursor
    mov DL, 0
    inc DH
    cmp DH, 24
    jle putc_set_cursor

    ; Прокрутка на одну строку вверх
    mov AH, 06h
    mov AL, 1
    mov BH, 0x3F
    mov CH, 0
    mov CL, 0
    mov DH, 24
    mov DL, 79
    int 10h
    mov DL, 0
    mov DH, 24              ; курсор на последней строке
    jmp putc_set_cursor

get_input:
    mov AH, 0              ; Ждем ввода с клавиатуры
    int 16h                ; Вызов прерывания для клавиатуры
    cmp AL, 1Bh            ; Проверка на ESC (ASCII-код 1Bh)
    je restart              ; Если ESC, перезагрузка
    cmp AL, 'a'            ; Проверка на 'a'
    je handle_a            ; Если нажата 'a'
    cmp AL, 'b'            ; Проверка на 'b'
    je handle_b            ; Если нажата 'b'
    cmp AL, 0x3A           ; Проверка на 'Alt' (ASCII-код 0x3A)
    je handle_alt          ; Если нажата 'Alt'

skip_reboot:
    ret

restart:
    jmp start              ; Перезагрузка

handle_a:
    mov AX, press_a_msg
    call puts
    ret

handle_b:
    ; mov AX, press_b_msg
    call cls
    ret

handle_alt:
    ; Обработка нажатия клавиши Alt
    mov AX, alt_msg
    call puts
    ret

input_buffer db 512 dup(0)  ; Буфер для ввода (макс 128 символов)
hello_world_msg db `no bootable device\n\0`
bios_msg db `Read Only Memory Basic Input Output System by [@Unralf]\n\0`
menu_msg db `\nMenu:\n1. Press 'a'\n2. Press 'b' to clear screen\nPress ESC to reboot\n\0`
info_msg db `[INFO]: 16 bits rom bios\n\0`
press_a_msg db `You pressed 'a'\n\0`
; press_b_msg db `You pressed 'b'\n\0`
alt_msg db `You pressed Alt key!\n\0`

cur_style db 0x3F           ; белый на синем
db 0                         ; резервирование байта под контрольную сумму

rom_end equ $-$$
rom_size equ (((rom_end-1)/rom_size_multiple_of)+1)*rom_size_multiple_of
times rom_size - rom_end db 0   ; выравнивание ROM до rom_size

