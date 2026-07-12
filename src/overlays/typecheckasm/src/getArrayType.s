;
; getArrayType.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

.include "ast.inc"
.include "error.inc"
.include "asmlib.inc"
.include "zeropage.inc"
.include "4510macros.inc"

pTypeOffset = 0
exprOffset = pTypeOffset + 4

.export getArrayType

.import loadStackValue, typeCheckError, exprTypeCheck

.proc getArrayType
    ldz #exprOffset
    jsr loadStackValue
    stq ptr1
    ldz #expr::kind
    nop
    lda (ptr1),z
    cmp #EXPR_SUBSCRIPT
    beq L1
    cmp #EXPR_POINTER
    bne L2

L1: ldz #pTypeOffset
    jsr loadStackValue
    stq ptr2
    ldz #expr::left
    neg
    neg
    nop
    lda (ptr1),z
    jsr pushQ
    ldq ptr2
    jsr pushQ
    jsr getArrayType
    ldz #pTypeOffset
    jsr loadStackValue
    stq ptr1
    ldz #type::subtype
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr2
    ldz #0
:   nop
    lda (ptr2),z
    nop
    sta (ptr1),z
    inz
    cpz #.sizeof(type)
    bne :-
    jmp DN

    ; if (expr.kind == EXPR_NAME)
L2: cmp #EXPR_NAME
    bne L3
    ldz #exprOffset
    jsr loadStackValue
    stq ptr1
    ldz #expr::name
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr4
    jsr scopeLookup
    jsr isQZero
    bne :+
    lda #errUndefinedIdentifier
    jsr typeCheckError
    ldz #pTypeOffset
    jsr loadStackValue
    stq ptr1
    ldz #type::kind
    lda #TYPE_VOID
    nop
    sta (ptr1),z
    bra DN
:   stq ptr1
    ldz #symbol::type
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr2
    ldz #pTypeOffset
    jsr loadStackValue
    stq ptr1
    ldz #0
:   nop
    lda (ptr2),z
    nop
    sta (ptr1),z
    inz
    cpz #.sizeof(type)
    bne :-
    bra DN

    ; if (expr.kind == EXPR_FIELD)
L3: cmp #EXPR_FIELD
    bne L4
    ldz #exprOffset
    jsr loadStackValue
    stq ptr1
    ldz #pTypeOffset
    jsr loadStackValue
    stq ptr2
    ldq ptr1
    jsr pushQ
    jsr pushQZero
    ldq ptr2
    jsr pushQ
    lda #0
    jsr pushA
    jsr exprTypeCheck
    bra DN

L4: lda #errUndefinedIdentifier
    jsr typeCheckError
    ldz #pTypeOffset
    jsr loadStackValue
    stq ptr1
    ldz #type::kind
    lda #TYPE_VOID
    nop
    sta (ptr1),z

DN: jsr popQ
    jsr popQ
    rts
.endproc
