;                              .....
;                            .e$$$$$$$$$$$$$$e.
;                          z$$ ^$$$$$$$$$$$$$$$$$.
;                        .$$$* J$$$$$$$$$$$$$$$$$$$e
;                       .$"  .$$$$$$$$$$$$$$$$$$$$$$*-
;                      .$  $$$$$$$$$$$$$$$$***$$  .ee"
;         z**$$        $$r ^**$$$$$$$$$*" .e$$$$$$*"
;        " -\e$$      4$$$$.         .ze$$$""""
;       4 z$$$$$      $$$$$$$$$$$$$$$$$$$$"
;       $$$$$$$$     .$$$$$$$$$$$**$$$$*"
;     z$$"    $$     $$$$P*""     J$*$$c
;    $$"      $$F   .$$$          $$ ^$$
;   $$        *$$c.z$$$          $$   $$
;  $P          $$$$$$$          4$F   4$
; dP            *$$$"           $$    '$r
;.$                            J$"     $"
;$                             $P     4$
;                            $$      4$
;                            4$%      4$
;                            $$       4$
;                           d$"       $$
;                           $P        $$
;                          $$         $$
;                         4$%         $$
;                         $$          $$
;                        d$           $$
;                        $F           "3
;                 r=4e="  ...  ..rf   .  ""%
;		 __    ____
;		(  )  ( ___)=========================|
;		 )(__  )__)      Version 0.0.3       |
;		(____)(____)  Copyright (C) 2020     |
;		 _  _   __|==========================|
;		( \/ ) /__\  Leya Compiler Version   |
;		 \  / /(__)\        0.0.5            |
;		 (__)(__)(__)========================|
; <------ [deps] ------>
%include "utilities.asm"
%include "type.asm"
%include "codeparser.asm"
; <------ [deps] ------>
;          DON'T HARDCODE THESE SYMBOLS
SECTION .data
    nullSymbol: db "null",0
    ifSymbol: db "if",0
    quoteSymbol: db "quote",0
    lambdaSymbol: db "lambda",0
    beginSymbol: db "begin",0
    ; memory tag define JUMP > Add to environment Define.
    defineSymbol: db "function",0
    letSymbol: db "let",0
    setSymbol: db "var",0
    numPrintBuffLen equ 80
    lemmaSymbol: db "lemma",0

SECTION .bss
    heap_start: resq 1
    program_end: resq 1
    numPrintBuff: resb (numPrintBuffLen +1)
    charPrintBuff: resb 1
    alloc_ptr: resq 1


SECTION .text
    ; Starts main:
    global _start


_start:




; Allocate our memory

        ; Get the current brk address
        mov rax, 12 ; brk
        mov rdi, 0
        syscall

        ; rax => alloc_ptr && heap_start
        mov [alloc_ptr], rax
        mov [heap_start], rax

        ; (Allocate memory)
        mov rdi, rax
        ; 64 == 9 million;
        add rdi, 1000000

        ; Syscall
        mov rax, 12
        syscall



; Read the source code into memory
;   VVVVVVVVVVVV Recreate this with call reading_loop attached
;            for read evaluate print
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

    ; Align pointer
    align_loop:
        mov rdi, rax
        and rdi, 0x1f
        cmp rdi, 0
        je align_loop_break

        inc rax
        jmp align_loop

    align_loop_break:
        mov [alloc_ptr], rax




; (Global)
    ; Move heap_start value into rsi
    mov rsi, [heap_start]
    ; Parse duh rest of the list
    call parseRestOfList
    push rax
    mov al, [rsi]
    cmp al, ')'
    errorE "Syntax Error: Incomplete Parenthesis in expression."

    mov byte [rsi], 0 ; Allows our symbol to be read.
    pop rax




    push rax
    push rbx


    call createInitialEnvironment


    pop rbx
    pop rax

    mov rdx, rdi
    mov rcx, rsi
    mov rdi, rax
    mov rsi, rbx


    call evalSequence



    mov rax, rdi
    mov rbx, rsi

    call print ; PRINTING ISN'T SYSTEM-V BUT SHOULD
    ;BE SINCE IT WORKS WITH SYSCALLS


; Exit

        mov rax, 60
        mov rdi, 0
        syscall

import:

        ; CONTROL VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
cmpNullTerminatedStrings:
    ; String pointers come into rdi and rsi
    ; returns 0 in rax if strings are equal, 1 if they are not:
    ; (idea is that eventually we might also say whether one of them is bigger
    ; than the other)


    .loop:
        mov r8b, [rdi]
        mov al, [rsi]
        cmp r8b, al
        je .same
        jmp .negative

    .same:
        cmp r8b, 0
        je .positive

        inc rdi
        inc rsi
        jmp .loop

    .positive:
        mov rax, 0
        jmp .return

    .negative:
        mov rax, 1
        jmp .return

    .return:
        ret


addDefineNodeToEnvironment:


    mov rax, [alloc_ptr]

    mov qword [rax], null_t
    mov qword [rax+8], 0
    mov [rax+16], rdi
    mov [rax+24], rsi

    mov rdi, pair_t_full
    mov rsi, [alloc_ptr]
    add qword [alloc_ptr], 32

    ret
    ; (Return from call)



addToEnvironmentWithDefine:
    ; When defining things with "define", to make sure that the definitions
    ; are mutually recursive,
    ; we pass an environment containing an indirection.
    ;
    ; For now, that indirection is a pair whose car is a null.
    ; addDefineNodeToEnvironment is used to get the redirection.
    ;
    ; The pointer to the environment list (a cons cell) is in rdi:rsi
    ; The symbol we insert with is in rdx:rcx
    ; The value we insert is in r8:r9
    ;
    cmp edi, pair_t
    errorNe "Environment given to addToEnvironmentWithDefine isn't a pair"

    cmp qword [rsi], null_t
    errorNe "Are you trying to define inside an expression?"

    push rsi
    push rdi

    mov rdi, [rsi+16]
    mov rsi, [rsi+24]

    call addToEnvironment

    pop rax
    pop rax

    ; CAREFUL: here we write a pointer to a heap-allocated value!
    ; With a generational collector, we would need to replace this.
    mov [rax+16], rdi
    mov [rax+24], rsi

    mov rdi, pair_t_full
    mov rsi, rax

    ret



addToEnvironment:
    ; The pointer to the environment list (a cons cell) is in rdi:rsi
    ; The symbol we insert with is in rdx:rcx
    ; The value we insert is in r8:r9
    ;
    ; The new environment is returned in rdi:rsi
    ;

        cmp rdx, symbol_t
        je .standardAdd

        cmp edx, pair_t
        je .listAdd
        cmp rdx, null_t
        je .listAdd
        jmp  exitError


    .listAdd:
        call addListToEnv

        jmp .return

    .standardAdd:

        ; create the (symbol, value) pair
        mov r10, [alloc_ptr]

        mov [r10], rdx
        mov [r10 + 8], rcx
        mov [r10 + 16], r8
        mov [r10 + 24], r9

        add qword [alloc_ptr], 32

        ; create the ((symbol, value), previousEnvironment) pair
        mov r11, [alloc_ptr]

        mov r9, pair_t_full
        mov qword [r11], r9
        mov [r11 + 8], r10
        mov [r11 + 16], rdi
        mov [r11 + 24], rsi

        add qword [alloc_ptr], 32

        ;return it
        mov rdi, pair_t
        mov rsi, r11

        jmp .return

    .return:

        ret



addListToEnv:
    ; The pointer to the environment list (a cons cell) is in rdi:rsi
    ; The symbols we insert with are in rdx:rcx (should be a list)
    ; The values we insert are in r8:r9 (should be a list)
    ;


        push r12
        push r13
        push r14
        push r15

        mov r12, rdx
        mov r13, rcx
        mov r14, r8
        mov r15, r9

    .loop:

        cmp r12d, pair_t
        jne .notCons

        cmp r14d, pair_t
        jne exitError

        mov rdx, [r13] ;car of symbols
        mov rcx, [r13+8]
        mov r12, [r13+16] ; cdr of symbols
        mov r13, [r13+24]

        mov r8, [r15] ;car of values
        mov r9, [r15+8]
        mov r14, [r15+16] ; cdr of values
        mov r15, [r15+24]

        ; At this point, rdx:rcx contains a symbol and r8:r9 contains a value
        ; rdi:rsi contains previous environment

        call addToEnvironment

        ; At this point, rdi:rsi contains new environment

        jmp .loop


    .notCons:
        cmp r12, null_t
        je .isNull

        jmp exitError; (We don't handle weird . thing yet)

    .isNull:
        ; Verify that the length of the values is the same
        cmp r14, null_t
        jne exitError

        jmp .return

    .return:

        pop r15
        pop r14
        pop r13
        pop r12

        ret


findInEnvironment:
    ; An environment is a list of pairs
    ; Bindings closer to the beginning shadow those closer to the end

    ; The pointer to the environment list (a cons cell) is in rdi:rsi
    ; A pointer to the string we are searching for comes into rdx

    ; Value comes out of rdi:rsi
        call findInEnvironmentPointer

        mov rdi, [rax]
        mov rsi, [rax + 8]

        ret


replaceInEnvironment:
    ; Environment comes into rdi:rsi
    ; Key comes into rdx:rcx
    ; Value comes into r8:r9
    ;
    ; Nothing is returned


        push r9
        push r8

        mov rdx, rcx ; Assuming for now rdx:rcx is a symbol

        call findInEnvironmentPointer

        pop r8
        pop r9

        ; CAREFUL: mutation here
        mov [rax], r8
        mov [rax + 8], r9

        ret



; Todo: the key should be in the form rdx:rcx
findInEnvironmentPointer:
    ; An environment is a list of pairs
    ; Bindings closer to the beginning shadow those closer to the end

    ; The pointer to the environment list (a cons cell) is in rdi:rsi
    ; A pointer to the string we are searching for comes into rdx

    ; A pointer to the returned value comes out of rax
    ;

        push r15
        push r14
        push r13
        push r12


        ; Check if the input is a cons.
        ; It might be a null if the variable isn't in the environment
        ; TODO make a clearer error message about this
    ;    cmp edi, pair_t
    ;    errorNe "Looked up variable is not in environment"


        mov r8, [rsi]   ; car type
        mov r9, [rsi+8] ; car
        mov r10, [rsi+16] ;cdr type
        mov r11, [rsi+24] ;cdr

        ; Just a sanity check
        cmp r8, null_t
        je .tryNext

        cmp r8d, pair_t
        errorNe "Something that's not a pair is in the environment list."


        mov r12, [r9] ; (car (car x)) type
        mov r13, [r9+8] ; (car (car x))
        lea r14, [r9+16] ; (cdr (car x)) type







        mov rdi, r13
        mov rsi, rdx

        push r11
        push r10


        call cmpNullTerminatedStrings

        pop r10
        pop r11

        cmp rax, 0
        je .success

    .tryNext:
        mov rdi, r10
        mov rsi, r11

        call findInEnvironment

        jmp .return


    .success:

        mov rax, r14
        jmp .return

    .return:

        pop r12
        pop r13
        pop r14
        pop r15


        ret






;TODO: a lot of the branches have the same structure. It would be nice to refactor it
; Perhaps get the symbols interned?

eval:
    ; The expression to be evaled goes into rdi:rsi
    ; The environment (pointer to a cons or null) goes into rdx:rcx
    ;
    ; The evaluated result comes out of rdi:rsi
    ; The modified environment comes out of rdx:rcx

        cmp rdi, null_t
        je exitError

        cmp rdi, int_t
        je .selfQuoting
        cmp rdi, bool_t
        je .selfQuoting
        cmp rdi, char_t
        je .selfQuoting

        cmp edi, pair_t
        je .pair
        cmp rdi, symbol_t
        je .symbol

        ; We shouldn't find anything else in the AST
        errorMsg "Trying to evaluate something that isn't valid AST"

    .selfQuoting:
        ret ;

    .pair:

        mov r8, [rsi] ; (car exp) type
        mov r9, [rsi+8] ; (car exp)
        mov r10, rsi

        cmp r8, symbol_t
        jne .notSpecialForm

    ; Check if "if"

    .maybeIf:
        mov rsi, r9
        mov rdi, ifSymbol

        call cmpNullTerminatedStrings

        cmp rax, 0
        jne .maybeQuote

        mov rdi, [r10 + 16]
        mov rsi, [r10 + 24]

        call handleIf;

        jmp .endPair


    .maybeQuote:
        mov rsi, r9
        mov rdi, quoteSymbol

        call cmpNullTerminatedStrings
        cmp rax, 0
        jne .maybeLambda


        mov r11, [r10 + 24] ; get the cdr
        mov r10, [r10 + 16]

        cmp r10d, pair_t ; if cdr not a cons, is not correct
        jne exitError

        ; If it's a quote, we just return the car of the cdr as is
        mov rdi, [r11]
        mov rsi, [r11 + 8]

        jmp .endPair


    .maybeLambda:
        mov rsi, r9
        mov rdi, lambdaSymbol

        call cmpNullTerminatedStrings
        cmp rax, 0
        jne .maybeBegin

        mov r11, [r10 + 24] ; get the cdr
        mov r10, [r10 + 16]

        cmp r10d, pair_t ; if cdr not a pair, is not correct
        jne exitError

        ; A lambda is a pair of its environment and its ast (excluding the "lambda" bit)

        mov rsi, [alloc_ptr]

        mov [rsi], rdx
        mov [rsi+8], rcx
        mov [rsi+16], r10
        mov [rsi+24], r11

        add qword [alloc_ptr], 32

        mov rdi, sc_fun_t_full

        jmp .endPair

    .maybeBegin:
        mov rsi, r9
        mov rdi, beginSymbol

        call cmpNullTerminatedStrings
        cmp rax, 0
        jne .maybeDefine

        mov rdi, [r10 + 16]
        mov rsi, [r10 + 24]

        jmp evalSequence ; tail call

    .maybeDefine:
        mov rsi, r9
        mov rdi, defineSymbol

        call cmpNullTerminatedStrings
        cmp rax, 0
        jne .maybeSet

        mov rdi, [r10 + 16]
        mov rsi, [r10 + 24]

        jmp handleDefine ; tail call

    .maybeSet:
        mov rsi, r9
        mov rdi, setSymbol

        call cmpNullTerminatedStrings
        cmp rax, 0
        jne .notSpecialForm

        mov rdi, [r10 + 16]
        mov rsi, [r10 + 24]

        jmp  handleSet; tail call

    .notSpecialForm:
        mov rdi, [r10] ; Get the car
        mov rsi, [r10 + 8]

        push rdx
        push rcx
        push r10

        call eval

        pop r10
        pop rcx
        pop rdx

        cmp rdi, bi_fun_t ; built-in function
        jne .maybeSchemeFunction

        mov r8, [r10 + 16] ; get the cdr
        mov r9, [r10 + 24]

        call handleBuiltInApplication

        jmp .endPair

    .maybeSchemeFunction: ; Maybe a lambda?
        cmp edi, sc_fun_t
        jne exitError

        mov r8, [r10 + 16] ; get the cdr
        mov r9, [r10 + 24]

        call handleSchemeApplication

        jmp .endPair


    .endPair:

        jmp .return

        jmp exitError ; NOT IMPLEMENTED

    .symbol:
        push rdx
        push rcx

        mov rdi, rdx
        mov rdx, rsi
        mov rsi, rcx


        call findInEnvironment


        pop rcx
        pop rdx
        jmp .return


    .return:

        ret


handleIf:
    ; rdi:rsi is (cdr exp)
    ; rdx:rcx is environment
    ;
    ; returns in rdi:rsi
    ; returns environment in rdx:rcx

        push r12
        push r13
        push r14
        push r15

        ; If cdr isn't a list, it's worthless
        cmp edi, pair_t
        jne exitError

        mov r12, [rsi] ; (car (cdr exp)) type (the condition)
        mov r13, [rsi+8] ; (car (cdr exp))
        mov r14, [rsi+16] ; (cdr (cdr exp)) type
        mov r15, [rsi+24] ; (cdr (cdr exp))

        mov rdi, r12
        mov rsi, r13

        push rdx
        push rcx

        call eval

        pop rcx
        pop rdx


        cmp edi, bool_t
        jne .isTrue
        cmp rsi, 0
        je .isFalse
    .isTrue:

        ; we need to get and evaluate the caddr

        cmp r14d, pair_t
        jne exitError

        mov rsi, r15
        mov r12, [rsi] ; caddr type
        mov r13, [rsi+8] ; caddr

        mov rdi, r12
        mov rsi, r13

        push rdx
        push rcx


        call eval

        pop rcx
        pop rdx


        jmp .return
    .isFalse:

        ; we need to get and evaluate the cadddr
        cmp r14d, pair_t
        jne exitError

        mov rsi, r15
        mov r12, [rsi+16] ; cdddr type
        mov r13, [rsi+24] ; cdddr



        cmp r12d, pair_t
        jne exitError

        mov rsi, r13
        mov r12, [rsi] ; cadddr type
        mov r13, [rsi+8] ; cadddr

        mov rdi, r12
        mov rsi, r13

        push rdx
        push rcx


        call eval

        pop rcx
        pop rdx

        jmp .return

    .return:

        pop r15
        pop r14
        pop r13
        pop r12

        ret



; Used as a debugging tool to print stuff
printWrapper:
    pushEverything

    mov rax, rdi
    mov rbx, rsi

    call print

    popEverything

    ret


handleBuiltInApplication:
    ; rdi:rsi is the function. rdi doesn't really matter tho since we know it's bi_fun_t
    ; rdx:rcx is the environment of course
    ; r8:r9 is the argument list
    ;
    ; rdi:rsi value out
    ; Let's assume that there is no environment out
    ;
    ; As I evaluate the arguments, I put them onto the stack.
    ; Then I put the number of arguments into rdi and call the function
    ; Value should be returned to rdi:rsi
    ; Functions should follow system-v clobbered/preserved convention

    push r12
    push r13
    push r14
    push r15

    mov rax, 0

    .argEvalLoop:
        cmp r8, null_t
        je .break

        cmp r8d, pair_t
        jne exitError

        mov r12, [r9]
        mov r13, [r9+8]
        mov r14, [r9+16]
        mov r15, [r9+24]

        push rax
        push rdx
        push rcx
        push rsi

        mov rdi, r12
        mov rsi, r13

        call eval


        mov r10, rdi
        mov r11, rsi

        pop rsi
        pop rcx
        pop rdx
        pop rax


        push r11 ; These pushes are special. They are used to pass the arguments
        push r10

        mov r8, r14
        mov r9, r15

        inc rax
        jmp .argEvalLoop

    .break:

        ; Now it's the time to evaluate that function
        mov r12, rax ; We need to save the number of arguments somewhere not on the stack
        mov rdi, rax

        call rsi

        ; Now the answer should be in rdi:rsi
        ; Time to clean the stack

        lea r12, [r12*2]
        lea rsp, [rsp + r12*8] ; subtract rsi*16 from the stack
        ; This is equivalent to popping r12*2 times

    .return:

        pop r15
        pop r14
        pop r13
        pop r12

        ret



handleSchemeApplication:
    ; rdi:rsi is the function. we know it's a sc_fun_t
    ; rdx:rcx is the environment of course
    ; r8:r9 is the argument list
    ;
    ; rdi:rsi value out
    ; Let's assume that there is no environment out
    ;
    ; What I'm going to do is that I'm going to evaluate builtInList on the
    ; argument list and then put it into the environment and eval the AST

    push rsi

    push rdx
    push rcx

    mov rdi, bi_fun_t
    mov rsi, builtInList

    call handleBuiltInApplication

    pop rcx
    pop rdx

    ; Now rdi:rsi contains the list we want to insert into env
    mov r8, rdi
    mov r9, rsi

    pop rsi

    mov rax, rsi


    mov rdi, [rax]    ; the "car" of the lambda is the environment
    mov rsi, [rax + 8]

    mov r10, [rax + 16]  ; the "cdr" of the lambda is the argument list and the body AST
    mov r11, [rax + 24]

    ; Better check this at creation time...
    cmp r10d, pair_t
    jne exitError

    mov rdx, [r11]  ; the car of the cdr is tha argument list
    mov rcx, [r11 + 8]



    push r11

    call addToEnvironment

    call addDefineNodeToEnvironment

    pop r11


    ; Now the new environment is in rdi:rsi. Move it to rdx:rcx
    mov rdx, rdi
    mov rcx, rsi

    mov rdi, [r11 + 16]   ;the "cddr" of the lambda is the body.
    mov rsi, [r11 + 24]   ;the "cddr" of the lambda is the body.
    ; For now, we only consider a single expression, even though we should
    ; consider that there is an implicit "begin"

    ; There should be something in the lambda body
    ; (Though we probably want to check this at lambda creation time)
    cmp edi, pair_t
    errorNe "Lambda must have body"

    jmp evalSequence; tail-call


handleDefine:
    ;
    ; rdi:rsi
    ; rdx:rcx is the environment

    cmp edi, pair_t
    errorNe "'define' must be followed by two data."

    mov r8, [rsi]
    mov r9, [rsi+8]
    mov r10, [rsi+16]
    mov r11, [rsi+24]

    push r9
    push r8

    cmp r10d, pair_t
    errorNe "'define' must be followed by two data."

    mov r8, [r11]
    mov r9, [r11+8]
    mov r10, [r11+16]
    mov r11, [r11+24]

    cmp r10d, null_t
    errorNe "'define' must be followed by two data."

    mov rdi, r8
    mov rsi, r9

    push rcx
    push rdx

    call eval

    mov r8, rdi ; put the value in r8:r9
    mov r9, rsi

    pop rdi ; Put the environment in rdi:rsi
    pop rsi

    pop rdx ; Put the key in rdx:rcx
    pop rcx

    call addToEnvironmentWithDefine

    mov rdi, unspecified_t
    mov rsi, unspecified_value

    ret

handleSet:
    ;
    ; rdi:rsi
    ; rdx:rcx is the environment

    cmp edi, pair_t
    errorNe "'set' must be followed by two data."

    mov r8, [rsi]
    mov r9, [rsi+8]
    mov r10, [rsi+16]
    mov r11, [rsi+24]

    push r9
    push r8

    cmp r10d, pair_t
    errorNe "'set' must be followed by two data."

    mov r8, [r11]
    mov r9, [r11+8]
    mov r10, [r11+16]
    mov r11, [r11+24]

    cmp r10d, null_t
    errorNe "'set' must be followed by two data."

    mov rdi, r8
    mov rsi, r9

    push rcx
    push rdx

    call eval

    mov r8, rdi ; put the value in r8:r9
    mov r9, rsi

    pop rdi ; Put the environment in rdi:rsi
    pop rsi

    pop rdx ; Put the key in rdx:rcx
    pop rcx

    call replaceInEnvironment

    mov rdi, unspecified_t
    mov rsi, unspecified_value

    ret





evalSequence:
    ; Evaluates a sequences, which might contain defines
    ; Sequences are explicitly defined with `begin` or implicitly defined in the body of lambdas
    ;
    ; rdi:rsi is the list of instructions
    ; rdx:rcx is the environment
    ;



    ; What's a bit special about evalSequence is that it returns the result of the last operation.

    .loop:


        cmp edi, pair_t
        errorNe "What was passed to evalSequence isn't a list"

        mov r8, [rsi]
        mov r9, [rsi+8]
        mov r10, [rsi+16]
        mov r11, [rsi+24]

        cmp r10, null_t
        je .tailCall


        push r11
        push r10
        push rcx
        push rdx

        mov rdi, r8
        mov rsi, r9

        call eval

        pop rdx
        pop rcx
        pop rdi
        pop rsi


        jmp .loop



    .tailCall:
        mov rdi, r8
        mov rsi, r9

        jmp eval
        builtInAdd:

                mov rax, 0

                lea rdi, [rdi*2]
                lea rdi, [rdi*8]

            .loop:
                cmp rdi, 0
                je .return

                mov rsi, [rsp + rdi - 8]

                cmp rsi, int_t
                errorNe "Argument to '+' isn't an integer"

                add rax, [rsp + rdi]

                sub rdi, 8
                sub rdi, 8

                jmp .loop

            .return:

                mov rdi, int_t
                mov rsi, rax

                ret


        builtInSub:

                cmp rdi, 0
                errorE "'-' must be called with at least one argument"

                cmp rdi, 1
                jne .actuallySub


            .negate:

                mov rdi, [rsp + 8]
                mov rsi, [rsp + 16]

                cmp rdi, int_t
                jne .typeError

                neg rsi

                ret


            .actuallySub:

                lea rdi, [rdi*2]
                lea rdi, [rdi*8]

                mov rdx, [rsp + rdi - 8]
                mov rcx, [rsp + rdi]

                sub rdi, 8
                sub rdi, 8

                cmp rdx, int_t
                jne .typeError

                mov rax, rcx

            .loop:
                cmp rdi, 0
                je .return

                mov rsi, [rsp + rdi - 8]

                cmp rsi, int_t
                jne .typeError

                sub rax, [rsp + rdi]

                sub rdi, 8
                sub rdi, 8

                jmp .loop

            .typeError:
                errorMsg "Argument to '-' isn't an integer"

            .return:

                mov rdi, int_t
                mov rsi, rax

                ret
	;		builtinDiv:


        builtInMul:

                mov rax, 1

                lea rdi, [rdi*2]
                lea rdi, [rdi*8]

            .loop:
                cmp rdi, 0
                je .return

                mov rsi, [rsp + rdi - 8]

                cmp rsi, int_t
                jne exitError

                mov rcx, [rsp + rdi]
                imul rcx

                sub rdi, 8
                sub rdi, 8

                jmp .loop

            .return:

                mov rdi, int_t
                mov rsi, rax

                ret

        builtInIntEq:

                cmp rdi, 0
                je .argumentNumberError
                cmp rdi, 1
                je .argumentNumberError


            .takeFirst:

                lea rdi, [rdi*2]
                lea rdi, [rdi*8]

                mov rdx, [rsp + rdi - 8]
                mov rcx, [rsp + rdi]

                sub rdi, 8
                sub rdi, 8

                cmp rdx, int_t
                jne .typeError

                mov rax, rcx

            .loop:
                cmp rdi, 0
                je .returnEqual

                mov rsi, [rsp + rdi - 8]

                cmp rsi, int_t
                jne .typeError

                cmp rax, [rsp + rdi]
                jne .returnNotEqual

                sub rdi, 8
                sub rdi, 8

                jmp .loop

            .typeError:
                errorMsg "Argument to '=' isn't an integer"

            .argumentNumberError:
                errorMsg "'=' must be called with at least two argument"

            .returnEqual:

                mov rdi, bool_t
                mov rsi, 1

                ret

            .returnNotEqual:

                mov rdi, bool_t
                mov rsi, 0

                ret


        %macro comparisonFunction 3

        %1:

                cmp rdi, 0
                je .argumentNumberError
                cmp rdi, 1
                je .argumentNumberError


            .takeFirst:

                lea rdi, [rdi*2]
                lea rdi, [rdi*8]

                mov rdx, [rsp + rdi - 8]
                mov rcx, [rsp + rdi]

                sub rdi, 8
                sub rdi, 8

                cmp rdx, int_t
                jne .typeError

                mov rax, rcx

            .loop:
                cmp rdi, 0
                je .returnEqual

                mov rsi, [rsp + rdi - 8]

                cmp rsi, int_t
                jne .typeError

                cmp rax, [rsp + rdi]
                %3 .returnNotEqual
                mov rax, [rsp + rdi]

                sub rdi, 8
                sub rdi, 8

                jmp .loop

            .typeError:
                errorMsg "Argument to comparison function isn't an integer"

            .argumentNumberError:
                errorMsg "Comparison functions must be called with at least two argument"

            .returnEqual:

                mov rdi, bool_t
                mov rsi, 1

                ret

            .returnNotEqual:

                mov rdi, bool_t
                mov rsi, 0

                ret

        %endmacro


        ; Bloating the binary, generate a bunch of comparison functions
        comparisonFunction builtInIntLt, "<", jge
        comparisonFunction builtInIntGt, ">", jle
        comparisonFunction builtInIntLeq, "<=", jg
        comparisonFunction builtInIntGeq, ">=", jl



        ; This sub-procedure is to get 2 arguments passed to a built-in proc
        ; The zf will be preserved so a jne or je could be used after
        get2Arguments:
                cmp rdi, 2
                je .correct
                ret

            .correct:
                ; Note that we need to jump over the return address
                mov rdi, [rsp + 32]
                mov rsi, [rsp + 40]
                mov rdx, [rsp + 16]
                mov rcx, [rsp + 24]

                ret





        builtInCons:

                cmp rdi, 2
                errorNe "'cons' requires two arguments"

                mov r8, [rsp + 24]
                mov r9, [rsp + 32]
                mov r10, [rsp + 8]
                mov r11, [rsp + 16]

                mov rdi, [alloc_ptr]

                ; TODO: use vectorization

                mov [rdi], r8
                mov [rdi+8], r9
                mov [rdi+16], r10
                mov [rdi+24], r11

                add qword [alloc_ptr], 32

                mov rsi, rdi
                mov rdi, pair_t_full


                ret


        builtInNot:

                cmp rdi, 1
                errorNe "'not' must have exactly one argument"

                mov rdi, [rsp + 8]
                mov rsi, [rsp + 16]

                cmp rdi, bool_t
                jne .returnFalse
                cmp rsi, 0
                jne .returnFalse

            .returnTrue:
                mov rdi, bool_t
                mov rsi, 1

                ret

            .returnFalse:

                mov rdi, bool_t
                mov rsi, 0

                ret


        builtInList:


                mov r10, rdi

                mov rdi, null_t
                mov rsi, 0

                lea r10, [r10*2]
                lea r10, [r10*8]
                mov r11, 0

            .loop:


                cmp r10, r11
                je .return


                add r11, 8
                mov r8, [rsp + r11]
                add r11, 8
                mov r9, [rsp + r11]

                mov rax, [alloc_ptr]

                mov [rax], r8
                mov [rax + 8], r9
                mov [rax + 16], rdi
                mov [rax + 24], rsi

                mov rdi, pair_t_full
                mov rsi, [alloc_ptr]

                add qword [alloc_ptr], 32

                jmp .loop

            .return:

                ; At this point, rdi:rsi contains the answer

                ret

        builtInGetType:


        builtInVectorRef:

                call get2Arguments
                errorNe "'vector-ref' requires 2 arguments"

                ;call printWrapper

                mov r8, vector_mask
                and r8, rdi

                mov r9, vector_mask
                cmp qword r8, r9
                errorNe "Something that isn't essentially a vector was passed to 'vector-ref'"

                cmp rdx, int_t
                errorNe "Second argument of 'vector-ref' isn't an integer"

                mov r8, rdi
                shr r8, 32
                and r8, size_mask

                cmp rcx, 0
                jl .notInRange

                cmp r8, rcx
                jle .notInRange

                lea rcx, [rcx*2]

                mov rdi, [rsi + rcx*8]
                mov rsi, [rsi + rcx*8 + 8]


                ret

            .notInRange:
                errorMsg "Integer passed to vector-ref is not in range"






        %macro insertFunctionIntoEnvironment 2
            ; embed the string in the source... what???
            jmp %%after
            %%string: db %2, 0
            %%after:

            mov rdx, symbol_t
            mov rcx, %%string
            mov r8, bi_fun_t
            mov r9, %1

            call addToEnvironment

        %endmacro



        createInitialEnvironment:

            ; Places all the built-in functions into the environment

            mov rdi, null_t
            mov rsi, 0

            mov rdx, symbol_t
            mov rcx, nullSymbol
            mov r8, null_t
            mov r9, 0

            call addToEnvironment

            insertFunctionIntoEnvironment builtInAdd, "+"
            insertFunctionIntoEnvironment builtInSub, "-"
            insertFunctionIntoEnvironment builtInMul, "*"
            insertFunctionIntoEnvironment builtInIntEq, "="
            insertFunctionIntoEnvironment builtInIntLt, "<"
            insertFunctionIntoEnvironment builtInIntGt, ">"
            insertFunctionIntoEnvironment builtInIntLeq, "<="
            insertFunctionIntoEnvironment builtInIntGeq, ">="
            insertFunctionIntoEnvironment builtInNot, "not"
            insertFunctionIntoEnvironment builtInVectorRef, "vecrf"
            insertFunctionIntoEnvironment builtInCons, "cons"
		;	insertFunctionIntoEnvironment builtInLen, "len"
            insertFunctionIntoEnvironment builtInList, "'"
		;	insertFunctionIntoEnvironment builtinDiv


            call addDefineNodeToEnvironment

            ret
			print:
			    ; type of input comes into rax
			    ; input comes into rbx

			        push rdi


			    .maybeList:
			        cmp rax, null_t
			        je .isList

			        cmp eax, pair_t
			        je .isList

			        jmp .maybeNumber

			    .isList:
			        push rax

			        mov rdi, 1 ; print to stdout

			        mov sil, '('
			        call printChar




			        mov sil, ' '
			        call printChar

			        pop rax

			        call printRestOfList
			        jmp .return


			    .maybeNumber:
			        cmp rax, int_t
			        jne .maybeBool

			        mov rax, rbx

			        call printNumber

			        jmp .return

			    .maybeBool:
			        cmp rax, bool_t
			        jne .maybeSymbol

			        mov rdi, 1
			        mov sil, "#"

			        call printChar

			        cmp rbx, 0
			        jne .true


			        mov rdi, 1
			        mov sil, "f"

			        call printChar

			        jmp .return


			    .true:
			        mov rdi, 1
			        mov sil, "t"

			        call printChar

			        jmp .return


			    .maybeSymbol:
			        cmp rax, symbol_t
			        jne .error

			        push rsi

			        mov rsi, rbx
			        call printNullTerminatedString

			        pop rsi

			        jmp .return

			    .error:
			        errorMsg "The object cannot be printed"


			    .return:
			        pop rdi
			        ret



			printNullTerminatedString:
			    ; string comes into rsi

					push rax
					push rbx
					push rcx
					push rdx
			        push rdi
			        push rsi

			        push r8
			        push r9
			        push r10
			        push r11



			        push rsi

			        mov rdx, 0

			    .findLength:
			        mov r9b, [rsi]
			        cmp r9b, 0
			        je .print

			        inc rsi
			        inc rdx
			        jmp .findLength

			    .print:

			        mov rax, 1 ; write
			        mov rdi, 1 ; stdout
			        pop rsi ; get beginning of string
			        ; rdx is the size of the string
			        syscall

			        pop r11
			        pop r10
			        pop r9
			        pop r8

			        pop rsi
			        pop rdi
					pop rdx
					pop rcx
					pop rbx
					pop rax
			        ret




			printRestOfList:
			    ; type (null or cons) comes into rax
			    ; value comes into rax

			    push rdi


			    .start:

			    .maybeNull:
			        cmp rax, null_t
			        jne .notNull

			        mov rdi, 1 ; print to stdout
			        mov rsi, ')'
			        call printChar

			        jmp .return

			    .notNull:
			        cmp eax, pair_t
			        jne .somethingElse

			        push rax
			        push rbx

			        ; Get the car of the cons
			        mov rax, [rbx]
			        mov rbx, [rbx + 8]

			        ; Print it
			        call print

			        mov rdi, 1 ; print char to stdout
			        mov rsi, ' '
			        call printChar

			        pop rbx
			        pop rax

			        ; Get the cdr of the cons
			        mov rax, [rbx + 16]
			        mov rbx, [rbx + 24]

			        ; recursive tail-call
			        jmp .start



			    .somethingElse: ; to consider the weird case of pairs whose cdr isn't a list (cons 1 1) = '(1 . 1)

			        push rax


			        mov rdi, 1
			        mov rsi, '.'
			        call printChar
			        mov rdi, 1
			        mov rsi, ' '
			        call printChar


			        pop rax

			        call print

			        mov rdi, 1
			        mov rsi, ' '
			        call printChar
			        mov rdi, 1
			        mov rsi, ')'
			        call printChar

			        jmp .return

			    .return:
			        pop rdi

			        ret



			printChar:
			    ; file to print to comes into rdi
			    ; character to print comes into lower byte of rsi

			    push rax
			    push rbx
			    push rcx
			    push rdx
			    push rdi
			    push rsi

			    push r8
			    push r9
			    push r10
			    push r11


			    mov byte [charPrintBuff], sil

			    mov rax, 1
			    ; rdi is already right
			    mov rsi, charPrintBuff
			    mov rdx, 1
			    syscall

			    pop r11
			    pop r10
			    pop r9
			    pop r8

			    pop rsi
			    pop rdi
			    pop rdx
			    pop rcx
			    pop rbx
			    pop rax


			    ret


			printNumber:
				; number comes in rax

					push rax
					push rbx
					push rcx
					push rdx
			        push rdi
			        push rsi

			        push r8
			        push r9
			        push r10
			        push r11


			        push rax

			        mov rdi, numPrintBuff
			        mov rcx, numPrintBuffLen
			        mov rax, 0
			        rep stosb

			        pop rax

			        mov rdi, numPrintBuff

				.checkIfSigned:
					cmp rax, 0
					jge .startBreakingUp
					mov byte [rdi], '-'
					inc rdi
					neg rax


				.startBreakingUp:


					mov rcx, 0 ;counter
					mov rbx, 10 ;variable to divide by 10

				.breakUpNumber:
					mov rdx, 0
					div rbx  ;divide by 10
					push rdx
					inc rcx
					cmp rax, 0
					jne .breakUpNumber

				.writeNumber:

					cmp rcx, 0
					je .end

					pop rax
					add al, '0'
					stosb

					dec rcx
					jmp .writeNumber


				.end:
			        ;mov al, `\n`
			        ;stosb

			        mov rdx, rdi
			        sub rdx, numPrintBuff

			        mov rax, 1
			        mov rdi, 1 ; stdout
			        mov rsi, numPrintBuff
			        syscall


			        pop r11
			        pop r10
			        pop r9
			        pop r8

			        pop rsi
			        pop rdi
					pop rdx
					pop rcx
					pop rbx
					pop rax

			ret


			printNewline:
					push rax
					push rbx
					push rcx
					push rdx
			        push rdi
			        push rsi

			        push r8
			        push r9
			        push r10
			        push r11

			    mov rdi, 1 ; print char to stdout
			    mov rsi, 0
			    mov sil, `\n`
			    call printChar

			        pop r11
			        pop r10
			        pop r9
			        pop r8

			        pop rsi
			        pop rdi
					pop rdx
					pop rcx
					pop rbx
					pop rax

			    ret
