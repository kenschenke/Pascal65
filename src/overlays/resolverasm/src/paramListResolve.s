;
; paramListResolve.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; paramListResolve routine

.include "ast.inc"
.include "asmlib.inc"
.include "zeropage.inc"
.include "4510macros.inc"

.export paramListResolve

.import getTypeSize

.bss

paramPtr: .res 4
typePtr: .res 4
offset: .res 2

.code

; On entry, the first param is in Q
.proc paramListResolve
    stq paramPtr
    stq ptr1

    lda #0
    sta offset
    sta offset+1

    ; Loop through the parameters
L1: ldq paramPtr
    jsr isQZero
    bne :+
    jmp L2

:   ldz #param_list::type
    neg
    neg
    nop
    lda (ptr1),z
    stq typePtr
    ; Calculate and store the type size
    jsr getTypeSize
    pha
    phx
    ldq typePtr
    stq ptr2
    ldz #type::size+1
    pla
    nop
    sta (ptr2),z
    dez
    pla
    nop
    sta (ptr2),z

    ; Restore ptr1 in case getTypeSize stomped on it
    ldq paramPtr
    stq ptr1

    ; Create a symbol structure
    lda #SYMBOL_LOCAL
    jsr pushA               ; symbol type
    ldz #param_list::type
    neg
    neg
    nop
    lda (ptr1),z
    jsr typeClone
    jsr pushQ               ; type
    
    ; Restore ptr1 in case typeClone stomped on it
    ldq paramPtr
    stq ptr1

    ldz #param_list::name
    neg
    neg
    nop
    lda (ptr1),z
    jsr pushQ               ; name
    jsr symbolCreate
    stq ptr3                ; new symbol in ptr3

    ; Set the symbol's offset
    ldz #symbol::offset
    lda offset
    nop
    sta (ptr3),z
    inz
    lda offset+1
    nop
    sta (ptr3),z

    ; Set the symbol's level
    jsr scopeLevel
    ldz #symbol::level
    nop
    sta (ptr3),z

    ldq paramPtr
    stq ptr1
    ldz #param_list::name
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr2
    sec
    jsr scopeBind

    ; Increment offset
    inc offset
    bne :+
    inc offset+1

:   ldq paramPtr
    stq ptr1
    ldz #param_list::next
    neg
    neg
    nop
    lda (ptr1),z
    stq paramPtr
    stq ptr1
    jmp L1

L2: rts
.endproc
