;
; exprClone.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; exprClone routine

.include "ast.inc"
.include "zeropage.inc"
.include "4510macros.inc"

.export exprClone

.import savePtrs, restorePtrs, storePtr, nameClone, symbolClone, typeClone
.import heapAlloc, isQZero, rtPushQ, rtPopQ

.proc exprClone
    jsr isQZero
    bne :+
    rts

:   jsr rtPushQ

    ; Allocate a expr structure and store the pointer in ptr2
    lda #.sizeof(expr)
    ldx #0
    jsr heapAlloc
    stq ptr2

    ; Zero out the new expr
    lda #0
    ldz #0
:   nop
    sta (ptr2),z
    inz
    cpz #.sizeof(expr)
    bne :-

    ; Put the original structure pointer in ptr1
    jsr rtPopQ
    stq ptr1

    ; Copy the kind
    ldz #expr::kind
    nop
    lda (ptr1),z
    nop
    sta (ptr2),z

    ; Clone the left expr
    jsr savePtrs
    ldz #expr::left
    neg
    neg
    nop
    lda (ptr1),z
    jsr exprClone
    stq ptr3
    jsr restorePtrs
    ldz #expr::left
    jsr storePtr
    
    ; Clone the right expr
    jsr savePtrs
    ldz #expr::right
    neg
    neg
    nop
    lda (ptr1),z
    jsr exprClone
    stq ptr3
    jsr restorePtrs
    ldz #expr::right
    jsr storePtr

    ; Name, value, and width share storage in the expr, as do node and
    ; precision. What gets cloned depends on the kind of expression.
    ldz #expr::kind
    nop
    lda (ptr1),z
    cmp #EXPR_ARG
    bne :+
    jmp CloneArg
:   cmp #EXPR_BOOLEAN_LITERAL
    beq CopyValue
    cmp #EXPR_BYTE_LITERAL
    beq CopyValue
    cmp #EXPR_WORD_LITERAL
    beq CopyValue
    cmp #EXPR_DWORD_LITERAL
    beq CopyValue
    cmp #EXPR_CHARACTER_LITERAL
    beq CopyValue

    ; Clone the name (or the text of a string or real literal)
    jsr savePtrs
    ldz #expr::name
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr3
    jsr isQZero
    beq :+
    jsr nameClone
    stq ptr3
:   jsr restorePtrs
    ldz #expr::name
    jsr storePtr
    bra CloneNode

    ; Copy the value
CopyValue:
    ldz #expr::value
    ldx #0
:   nop
    lda (ptr1),z
    nop
    sta (ptr2),z
    inz
    inx
    cpx #4
    bne :-

    ; Clone the symbol table node
CloneNode:
    jsr savePtrs
    ldz #expr::node
    neg
    neg
    nop
    lda (ptr1),z
    jsr symbolClone
    stq ptr3
    jsr restorePtrs
    ldz #expr::node
    jsr storePtr
    bra CloneCommon

    ; Clone the width and precision exprs
CloneArg:
    jsr savePtrs
    ldz #expr::width
    neg
    neg
    nop
    lda (ptr1),z
    jsr exprClone
    stq ptr3
    jsr restorePtrs
    ldz #expr::width
    jsr storePtr

    jsr savePtrs
    ldz #expr::precision
    neg
    neg
    nop
    lda (ptr1),z
    jsr exprClone
    stq ptr3
    jsr restorePtrs
    ldz #expr::precision
    jsr storePtr

CloneCommon:
    ; Clone the neg byte
    ldz #expr::neg
    nop
    lda (ptr1),z
    nop
    sta (ptr2),z

    ; Clone the evalType
    jsr savePtrs
    ldz #expr::evalType
    neg
    neg
    nop
    lda (ptr1),z
    jsr typeClone
    stq ptr3
    jsr restorePtrs
    ldz #expr::evalType
    jsr storePtr

    ldq ptr2
    rts
.endproc
