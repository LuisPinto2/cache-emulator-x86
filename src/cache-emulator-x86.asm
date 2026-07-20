; fc60831

SECTION .data
    msg_erro db "Argumento(s) inválido(s)." ; Mensagem de erro
    msg_len equ $ - msg_erro                ; Length msg_erro
    
SECTION .text
    extern set_validation_bit
    extern set_tag
    extern get_validation_bit
    extern get_tag
    extern get_data
    extern display_table
    
    global _start
_start:
    mov rbp, rsp

    ; Ler e validar o nr de args (argc)
    mov r15, [rbp]                      ; r15 = argc
    cmp r15, 1
    jle _erro                           ; Se argc <= 1 então exibe erro

    dec r15                             ; Como tirámos argv[0] restam (argc - 1) argumentos para ler
    mov r14, 0                          ; Contador r14 começa em 0
    
_leitura:
    ; Verificar se todos os argumentos foram processados
    cmp r14, r15
    je _exit
    
    ; Ler argv[r14]
    mov rax, [rbp + 16 + r14*8]         ; Ponteiro para o próximo argumento/string
    inc r14                             ; Incrementar contador de argumentos processados
    
    mov rbx, [rax]
    xor rax, rax
    mov ax, bx                          ; ax = endereço da cache
            
    ; Obter offset em r13b
    mov r13b, 11b
    and r13b, al
    
    ; Obter index em r12b
    mov r12b, 111100b
    and r12b, al                        ; Aplica a máscara
    shr r12b, 2                         ; Restam apenas os 4 bits do index
    
    ; Obter tag em bx
    mov bx, 1111111111000000b
    and bx, ax                          ; Aplica a máscara
    shr bx, 6                           ; Restam apenas os 10 bits da tag
    
    ; Verificar bit de validade
    movzx edi, r12b

    call get_validation_bit             ; Obter bit de validade em al
    call display_table
    
    ; Se o bit de validade for 0, logo ocorre miss
    test al, al                         ; Verificar se o bit de validade é 0 ou 1
    jz _validation_bit                  ; Se al = 0 ocorreu miss
    
    ; Caso bit de validade =! 0 ainda há a possibilidade de ocorrer miss (bit validade = 1 & tags diferentes)
    movzx edi, r12b
    call get_tag                        ; Obter tag em rax

    cmp ax, bx                          ; Comparar o valor da tag que já estava na cache com o valor da tag do argumento dado
    jne _miss
    
    ;Se nenhum destes acontecer então ocorre hit
    jmp _hit

    
_validation_bit:
    movzx edi, r12b
    call set_validation_bit             ; Atualizar o valor do bit de validade
    call display_table

    
_miss:
    movzx rdi, r12b                     ; rdi = index
    movzx rsi, bx                       ; rsi = tag
    call set_tag                        ; Inserir o valor da tag
        
    movzx rdi, r12b                     ; rdi = index
    movzx rsi, r13b                     ; rsi = offset
    call get_data                       ; Obter data da cache
    call display_table

    jmp _iteracao                       ; Salta o bloco _hit para não duplicar leitura
            
_hit:
    movzx rdi, r12b
    movzx rsi, r13b
    call get_data                       ; Obter data da cache
    call display_table
    
_iteracao:
    jmp _leitura                        ; Há de ser um jump para leitura para ler e processar os outros argumentos (aumentando r9)
    
_erro:
    ; Imprimir mensagem de erro
    mov rdi, 2
    lea rsi, [msg_erro]
    mov rdx, msg_len
    mov rax, 1
    syscall

    mov rax, 60
    xor rdi, 1
    syscall
    
_exit:
    mov rax, 60
    xor rdi, rdi
    syscall