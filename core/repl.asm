%include "interp.asm"
SECTION .data

SECTION .bss
_start:
    ; we're going to need to call from






    ; Same loop from interp.asm => reading_loop:
    ; The only difference is that
    reading_loop:

        ; Read from stdin
        mov rax, 0
        mov rdi, 0 ; stdin
        mov rsi, [alloc_ptr]
        mov rdx, 100000
        syscall

        add [alloc_ptr], rax

        cmp rax, 0
        jne reading_loop
    ;   call reading_loop
    ; After the loop:

        ; Save the end of the program
        mov rax, [alloc_ptr]
        mov [program_end], rax

        ; Add a null terminator
        mov byte [rax], 0
        inc rax
