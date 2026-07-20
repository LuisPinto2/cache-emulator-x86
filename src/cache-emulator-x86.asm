; fc60831

SECTION .data
    msg_erro db "Invalid argument(s)."      ; Error message
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

    ; Read and validate args number (argc)
    mov r15, [rbp]                      ; r15 = argc
    cmp r15, 1
    jle _erro                           ; If argc <= 1 then show error

    dec r15                             ; Removed argv[0] so theres (argc - 1) arguments left to read
    mov r14, 0                          ; Counter r14 begins at 0
    
_leitura:
    ; Verify if all args have been processed
    cmp r14, r15
    je _exit
    
    ; Read argv[r14]
    mov rax, [rbp + 16 + r14*8]         ; Pointer to the next argument
    inc r14                             ; Increment processed arguments counter
    
    mov rbx, [rax]
    xor rax, rax
    mov ax, bx                          ; ax = cache address
            
    ; Get offset in r13b
    mov r13b, 11b
    and r13b, al
    
    ; Get index in r12b
    mov r12b, 111100b
    and r12b, al                        ; Apply the mask
    shr r12b, 2                         ; Theres only 4 bits left from the index
    
    ; Get tag in bx
    mov bx, 1111111111000000b
    and bx, ax                          ; Apply the mask
    shr bx, 6                           ; Theres only 10 bits left from the tag
    
    ; Verify validation bit
    movzx edi, r12b

    call get_validation_bit             ; Get validation bit in al
    call display_table
    
    ; If validation bit is 0, then miss
    test al, al                         ; Verificar se o bit de validade é 0 ou 1
    jz _validation_bit                  ; Se al = 0 ocorreu miss
    
    ; If validation bit =! 0 theres still chance of being a miss (validity bit = 1 & different tags)
    movzx edi, r12b
    call get_tag                        ; Get tag in rax

    cmp ax, bx                          ; Compare tag value that was in cache to argument tag
    jne _miss
    
    ; If any of these happen then hit
    jmp _hit

    
_validation_bit:
    movzx edi, r12b
    call set_validation_bit             ; Update validation bit
    call display_table

    
_miss:
    movzx rdi, r12b                     ; rdi = index
    movzx rsi, bx                       ; rsi = tag
    call set_tag                        ; Insert tag value
        
    movzx rdi, r12b                     ; rdi = index
    movzx rsi, r13b                     ; rsi = offset
    call get_data                       ; Get cache data
    call display_table

    jmp _iteracao                       ; Jumps _hit block not to read twice
            
_hit:
    movzx rdi, r12b
    movzx rsi, r13b
    call get_data                       ; Get cache data
    call display_table
    
_iteracao:
    jmp _leitura
    
_erro:
    ; Print error message
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