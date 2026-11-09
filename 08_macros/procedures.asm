section .data
    msg1 db "start ...", 10
    len1 equ $ - msg1

    msg2 db "stop ...", 10
    len2 equ $ - msg2

section .text
    global _start

print:
    mov rax, 1   ;what       
    mov rdi, 1   ; how
    ; rsi        ;addr
    ; rdx        ;len
    syscall
    ret

delay:
    mov rcx, rdi

loop_l:
    loop loop_l

    ret

_start:
    mov rsi, msg1
    mov rdx, len1
    call print

    ; mov r9, rax

    mov rdi, 1000000000
    call delay

    mov rsi, msg2
    mov rdx, len2
    call print

    ; Exit program
    mov rax, 60
    xor rdi, rdi
    syscall