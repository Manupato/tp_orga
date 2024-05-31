global strClone
global strPrint
global strCmp
global strLen
global strDelete

global arrayNew
global arrayDelete
global arrayPrint
global arrayGetSize
global arrayAddLast
global arrayGet
global arrayRemove
global arraySwap

global cardCmp
global cardClone
global cardAddStacked
global cardDelete
global cardGetSuit
global cardGetNumber
global cardGetStacked
global cardPrint
global cardNew

extern intClone
extern intCmp
extern intPrint
extern listClone
extern listAddFirst
extern listPrint
extern listNew
extern listDelete
extern intDelete
extern getDeleteFunction
extern getPrintFunction
extern getCloneFunction

extern malloc
extern fprintf
extern fputs
extern fputc
extern free

section .data
    %define corchete_abierto '['
    %define coma ','
    %define corchete_cerrado ']'
    %define llave_abierta '{'
    %define llave_cerrada '}'
    %define guión '-'
    NULL_TEXT db 'NULL', 0, 1, 2, 3

section .text

; ** String **
;char* strClone(char* a);
strClone:
    push rbp
    mov rbp, rsp

    push r12
    sub rsp, 8

    mov r12, rdi

    call strLen

    inc rax
    mov rdi, rax

    call malloc

    mov rdi, rax

    xor rsi, rsi
    xor rbp, rbp

    .for:
        mov sil, [r12 + rbp]
        mov byte [rdi + rbp], sil

        test sil, sil
        je .end

        inc rbp
        jmp .for

    .end:

    mov rax, rdi

    add rsp, 8
    pop r12

    pop rbp

    ret

;void strPrint(char* a, FILE* pFile)
strPrint:
    push rbp
    mov rbp, rsp

    ; Push a los registros que se van a usar
    push r12
    push r13

    mov r12, rdi
    mov r13, rsi

    ; Verificamos si la cadena está vacía
    cmp r12, 0
    je .fin       ; Si no es vacía, saltamos a imprimir la cadena

    call strLen

    cmp al, 0
    je .printNULL

    ; Imprimimos la cadena
    mov rdi, r13            ; Primer argumento: FILE* pFile
    mov rsi, r12            ; Segundo argumento: char*

    xor rax, rax
    call fprintf

    jmp .fin

    .printNULL:

    ; Imprimo "NULL"
    xor rax, rax
    mov rdi, r13
    mov rsi, NULL_TEXT
    call fprintf

    .fin:
    pop r13
    pop r12
    pop rbp
    ret

;uint32_t strLen(char* a);
strLen:
    push rbp
    mov rbp, rsp

    ; Contador en 0
    xor rax, rax
    xor rdx, rdx

    .loop:
        ; Carga el byte actual del string
        mov dl, [rdi + rax]

        ; Comprobación si carácter es nulo o no
        cmp dl, 0
        ; Si es nulo, termina el bucle
        je .end

        ; Si no es nulo, incrementa el contador rax
        inc rax

        ; Continuar con el siguiente carácter
        jmp .loop

    .end:
        pop rbp
        ret

;int32_t strCmp(char* a, char* b);
strCmp:
    push rbp
    mov rbp, rsp

    ; a = "hola" --- b = "chau"

    push r12
    push r13
    push r14
    push r15

    mov r12, rdi ; r12 -> "hola"
    mov r13, rsi ; r13 -> "chau"

    call strLen ; len("hola") = 4

    mov r14, rax ; r14 -> 4
    mov rdi, r13 ; rdi -> "chau"

    call strLen ; len("chau") = 4

    mov r15, rax ; r15 -> 4

    xor rdx, rdx ; rdx -> 0
    xor rax, rax ; rax -> 0

    .while:
        test rax, rax                       ; Chequeo si encontré que los arreglos son distintos.
        jnz .end

        cmp rdx, r14                        ; Chequeo si la variable de control se me fue de rango.
        jnl .end_while

        cmp rdx, r15
        jnl .end_while

        mov dil, [r12 + rdx]                ; Comparo a[i] con b[i]
        cmp dil, [r13 + rdx]
        jg .first_if
        jl .first_elif
        je .redo

        .first_if:
            mov rax, -1
            jmp .redo

        .first_elif:
            mov rax, 1

        .redo:
            inc rdx
            jmp .while

    .end_while:

    sub r14, r15
    js .second_if
    jz .end
    jmp .second_elif

    .second_if:
        mov rax, 1
        jmp .end

    .second_elif:
        mov rax, -1

    .end:

    pop r15
    pop r14
    pop r13
    pop r12

    pop rbp

    ret

;void strDelete(char* a);
strDelete:
    push rbp
    mov rbp, rsp

    ; Argumento: rdi = char* a
    ; Simplemente llamamos a free
    call free

    pop rbp
    ret


; ** Array **

; uint8_t arrayGetSize(array_t* a)
arrayGetSize:
    push rbp
    mov rbp, rsp

    ; Argumento: rdi = array_t*

    xor rax, rax            ; Limpiamos rax (asegurar que los bytes superiores sean cero)
    mov al, [rdi + 4]       ; Leemos el campo size

    pop rbp
    ret

; void arrayAddLast(array_t* a, void* data)
arrayAddLast:
    push rbp
    mov rbp, rsp

    push r12
    push r13
    push r14
    sub rsp, 8

    mov r12, rdi ; Almacena el array_t* a.
    mov r13, rsi ; Almacena el void* data.
    mov r14, [rdi + 8] ; Almacena el arrego el sí.

    mov sil, [rdi + 4]
    cmp sil, [rdi + 5]
    jge .end

    xor rdi, rdi
    mov edi, [r12]
    call getCloneFunction
    mov rbp, rax

    mov rdi, r13
    call rbp

    xor rdx, rdx
    mov dl, [r12 + 4]
    mov [r14 + rdx*8], rax

    inc byte [r12 + 4]

    .end:

    add rsp, 8
    pop r14
    pop r13
    pop r12

    pop rbp

    ret

; void* arrayGet(array_t* a, uint8_t i)
arrayGet:
    push rbp
    mov rbp, rsp

    ; Verifico que i esté en el rango
    xor rax, rax
    mov al, [rdi + 4]               ; rdx = a->size (zero-extension)
    cmp rsi, rax                    ; Comparar i con a->size
    jge .invalid

    ; Calculo la dirección del i-ésimo elemento
    mov rbx, [rdi + 8]          ; rbx = a->data (puntero al array de punteros)
    and rsi, 0xff
    mov rax, [rbx + rsi*8]      ; rax = a->data[i]
    jmp .fin

    .invalid:
        xor rax, rax

    .fin:
    pop rbp
    ret

; array_t* arrayNew(type_t t, uint8_t capacity)
arrayNew:
    push rbp
    mov rbp, rsp

    push r12
    push r13
    push r14
    sub rsp, 8

    mov r12, rdi
    mov r13b, sil

    mov rdi, 16
    call malloc
    ; Ahora, rax contiene el puntero al struct array_t

    ; Guardar el puntero al struct array_t en r14
    mov r14, rax

    ; Inicializar el campo type (type_t t)
    mov dword [r14], r12d

    ; Inicializar el campo size a 0
    mov byte [r14 + 4], 0

    ; Inicializar el campo capacity (uint8_t capacity)
    mov byte [r14 + 5], r13b

    ; Reservar memoria para el campo data (array de punteros, tamaño capacity)
    xor rdi, rdi
    xor rsi, rsi
    mov sil, byte [r14 + 5]
    xor rax, rax
    add rax, 8
    add dil, sil
    mul rdi
    mov rdi, rax
    call malloc
    ; Ahora, rax contiene el puntero a los datos del array

    ; Inicializar el campo data
    mov [r14 + 8], rax

    ; Devolver el puntero al struct array_t
    mov rax, r14

    ; Epilogo de la función: restaurar rbp y retornar

    add rsp, 8
    pop r14
    pop r13
    pop r13

    pop rbp
    ret

; void* arrayRemove(array_t* a, uint8_t i)
arrayRemove:
    push rbp
    mov rbp, rsp

    cmp rsi, 0
    jl .emptyRax

    mov al, sil
    cmp al, [rdi + 4]
    jge .emptyRax

    push r12
    push r13
    push r14
    push r15

    mov r12, rdi ; Almacena el array_t*.
    mov r13, rsi ; Almacena el uint8_t.

    xor r14, r14
    mov r14b, [rdi + 4] ; Almacena el número de elementos del array.
    dec r14
    mov r15, r13 ; Va a funcionar como variable de control.

    .for:
        cmp r15b, r14b
        je .endFor

        mov rdi, r12
        mov rsi, r15
        xor rdx, rdx
        lea rdx, [r15 + 1]

        call arraySwap

        inc r15
        jmp .for

    .emptyRax:
        xor rax, rax
        jmp .end

    .endFor:

    xor r15, r15
    add r15, [r12 + 8] ; Ahora guarda el puntero del arreglo.
    mov rax, 8
    mul r14
    mov rax, [r15 + rax]

    dec byte [r12 + 4] ; Se decrementa el tamaño del array.

    pop r15
    pop r14
    pop r13
    pop r12

    .end:

    pop rbp

    ret

; void arraySwap(array_t* a, uint8_t i, uint8_t j)
arraySwap:
    push rbp
    mov rbp, rsp

    push r12
    push r13
    push r14

    xor r13, r13
    xor r14, r14

    mov r12, rdi       ; Guardar puntero al array en r12
    mov r13b, sil       ; Guardar índice i en r13
    mov r14b, dl       ; Guardar índice j en r14

    cmp sil, 0
    jl .fin

    cmp sil, [r12 + 4]
    jge .fin

    cmp dl, 0
    jl .fin

    cmp dl, [r12 + 4]
    jge .fin

    mov rcx, [r12 + 8]
    mov rbx, [rcx + r13*8]   ; Cargar elemento i en rbx
    mov rdx, [rcx + r14*8]   ; Cargar elemento j en rdx

    mov [rcx + r13*8], rdx   ; Guardar elemento j en posición i
    mov [rcx + r14*8], rbx   ; Guardar elemento i en posición j

    .fin:
    pop r14
    pop r13
    pop r12
    pop rbp
    ret

; void arrayDelete(array_t* a) 
arrayDelete:

    push rbp
    mov rbp, rsp

    push r12
    push r13

    mov r13, rdi

    xor rdi, rdi
    mov edi, [r13]
    call getDeleteFunction

    mov rbp, rax

    xor r12, r12

    .for:
        cmp r12b, [r13 + 4]
        je .end_for

        mov rsi, [r13 + 8]
        mov rdi, [rsi + r12*8]

        call rbp

        .next:
            inc r12
            jmp .for

    .end_for:

    mov rdi, [r13 + 8]
    call free

    mov rdi, r13
    call free

    pop r13
    pop r12

    pop rbp

    ret

;void arrayPrint(array_t* a, FILE* pFile)
arrayPrint:
    push rbp
    mov rbp, rsp

    push r12
    push r13
    push r14
    push r15

    mov r12, rdi
    mov r13, rsi

    xor rdi, rdi
    mov edi, [r12]
    call getPrintFunction
    mov rbp, rax

    mov rsi, r13

    mov rdi, corchete_abierto            
    call fputc

    xor r14, r14
    mov r14b, [r12 + 4]
    xor r15, r15

    .for:
        cmp r15, r14
        je .end

        mov rdi, [r12 + 8]
        mov rdi, [rdi + r15*8]
        mov rsi, r13

        call rbp

        .validComma:
            dec r14
            cmp r15, r14
            je .next

        .addComma:
            mov rsi, r13
            mov rdi, coma         
            call fputc

        .next:

        inc r14
        inc r15
        jmp .for

    .end:

    mov rsi, r13
    mov rdi, corchete_cerrado                 
    call fputc

    pop r15
    pop r14
    pop r13
    pop r12

    pop rbp

    ret

; ** Card **

; card_t* cardNew(char* suit, int32_t* number)
cardNew:
    push rbp
    mov rbp, rsp
    push r12
    push r13
    push r14
    push r15

    mov r12, rdi
    mov r13, rsi

    ; Duplico el string suit
    call strClone                           ; rdi ya contiene r12
    mov r14, rax                            ; Guardo el resultado en r14

    ; Duplico el int32_t number
    mov rdi, r13                            ; Muevo number a rdi
    call intClone
    mov r15, rax                            ; Guardo resultado en r15

    ; Asigno memoria para struct card_t
    xor rdi, rdi
    add rdi, 24                             ; Tamaño de la estructura card_t (3 punteros de 8 bytes cada uno)
    call malloc                             ; Llamar a malloc para asignar memoria

    ; En este punto, rax contiene el puntero a la memoria asignada para card_t

    mov [rax], r14                          ; Guardar el puntero duplicado a suit en la estructura
    mov [rax + 8], r15                      ; Guardar el puntero duplicado a number en la estructura

    mov r15, rax
    xor rdi, rdi
    add rdi, 3

    call listNew

    mov [r15 + 16], rax
    mov rax, r15

    pop r15
    pop r14
    pop r13
    pop r12

    pop rbp
    ret

;char* cardGetSuit(card_t* c)
cardGetSuit:

    push rbp
    mov rbp, rsp 

    mov rax, [rdi]

    pop rbp

    ret

;int32_t* cardGetNumber(card_t* c)
cardGetNumber:
    push rbp
    mov rbp, rsp

    mov rax, [rdi + 8]

    pop rbp

    ret

;list_t* cardGetStacked(card_t* c)
cardGetStacked:
    ; Guardamos el stack frame
    push rbp
    mov rbp, rsp

    ; Arg: card_t* c [rdi]
    mov rax, [rdi + 16] ; Obtenemos el puntero a stack (offset 16 en card_t)

    ; Restauramos stack frame
    pop rbp
    ret


;void cardPrint(card_t* c, FILE* pFile)
cardPrint:
    push rbp
    mov rbp, rsp

    push r12
    push r13

    mov r12, rdi
    mov r13, rsi

    ; '['
    mov rdi, llave_abierta
    call fputc

    mov rdi, [r12]
    mov rsi, r13
    call strPrint
    
    ; '-'
    mov rsi, r13
    mov rdi, guión
    call fputc

    mov rdi, [r12 + 8]
    mov rsi, r13
    call intPrint

    ; '-'
    mov rsi, r13
    mov rdi, guión
    call fputc

    mov rdi, [r12 + 16]
    mov rsi, r13
    call listPrint

    ; ']'
    mov rsi, r13
    mov rdi, llave_cerrada
    call fputc

    pop r13
    pop r12

    pop rbp
    ret


;int32_t cardCmp(card_t* a, card_t* b)
cardCmp:
    push rbp                ; Guardar el stack frame y registros
    mov rbp, rsp
    push r12
    push r13

    mov r12, rdi
    mov r13, rsi

    ; Argumentos: card_t* a [rdi], card_t* b [rsi]

    ; Paso 1: Comparar los suits
    mov rdi, [rdi]          ; suit de a
    mov rsi, [rsi]          ; suit de b
    call strCmp
    test al, al
    jz .compare_numbers     ; Si son iguales, pasar a comparar los números

    ; Evaluamos el resultado de strcmp
    cmp al, 0
    jg .suit_a_b            ; Si a->suit < b->suit
    mov eax, -1
    jmp .fin

    .suit_a_b:
    mov eax, 1
    jmp .fin

    .compare_numbers:       ; Paso 2: Comparar los números
        mov rdi, r12
        mov rsi, r13
        mov rdi, [rdi+8]    ; number de a
        mov rsi, [rsi+8]    ; number de b

    call intCmp

    .fin:
    pop r13                 ; Restauramos registros y stack frame
    pop r12
    pop rbp
    ret

;card_t* cardClone(card_t* c)
cardClone:
    push rbp
    mov rbp, rsp

    push r12
    push r13

    mov r12, rdi

    xor rdi, rdi
    add rdi, 24

    call malloc

    mov r13, rax

    mov rdi, [r12]
    call strClone
    mov [r13], rax

    mov rdi, [r12 + 8]
    call intClone
    mov [r13 + 8], rax

    mov rdi, [r12 + 16]
    call listClone
    mov [r13 + 16], rax

    mov rax, r13

    pop r13
    pop r12

    pop rbp

    ret

;void cardAddStacked(card_t* c, card_t* card)
cardAddStacked:

    push rbp
    mov rbp, rsp

    ; Agregar copia al comienzo de la pila de la carta original
    mov rdi, [rdi + 16]  ; rdi = c->stacked
    call listAddFirst

    pop rbp
    ret

;void cardDelete(card_t* c)
cardDelete:
    push rbp
    mov rbp, rsp

    push r12
    sub rsp, 8

    mov r12, rdi

    mov rdi, [rdi]
    call strDelete

    mov rdi, [r12 + 8]
    call intDelete

    mov rdi, [r12 + 16]
    call listDelete

    mov rdi, r12
    call free

    add rsp, 8
    pop r12

    pop rbp

    ret