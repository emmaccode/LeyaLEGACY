%define vector_mask ((0b1001) << (64 - 4))
%define buffer_mask ((0b1010) << (64 - 4))

%define size_mask 0x0fffffff

; Null array
%define null_t 0

; What to return from things that shouldn't return anything
%define unspecified_t 0
%define unspecified_value 0

; Boolean
%define bool_t 1

; 64-bit integer
%define int_t 2

; Unicode character
%define char_t 4

; Points to a heap allocated cons cell
%define pair_t 5
%define pair_t_full (5 | (2 << 32) | vector_mask)

; A symbol is a null-terminated string
%define symbol_t 6

; Built-in function
%define bi_fun_t 7
%define sc_fun_t 8
%define sc_fun_t_full 8 | (2 << 32) | vector_mask
