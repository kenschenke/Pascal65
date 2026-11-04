;
; freeExpr.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; freeExpr routine

.include "ast.inc"
.include "zeropage.inc"
.include "4510macros.inc"

.export freeExpr

.import freeSymbol, freeType, loadPtr, rtPopQ, rtPushQ, heapFree, isQZero, peekQ

.proc freeExpr
    stq ptr1
    jsr isQZero
    bne :+
    rts
:   jsr rtPushQ

    ; The name, value, and width members share storage, so what needs to
    ; be freed depends on the kind of expression.
    jsr peekQ
    stq ptr1
    ldz #expr::kind
    nop
    lda (ptr1),z
    cmp #EXPR_ARG
    beq FreeArg
    cmp #EXPR_BOOLEAN_LITERAL
    beq L1
    cmp #EXPR_BYTE_LITERAL
    beq L1
    cmp #EXPR_WORD_LITERAL
    beq L1
    cmp #EXPR_DWORD_LITERAL
    beq L1
    cmp #EXPR_CHARACTER_LITERAL
    beq L1

    ; Name, or the text of a string or real literal
    ldz #expr::name
    jsr loadPtr
    jsr isQZero
    beq L1
    jsr heapFree
    bra L1

    ; Width and precision
FreeArg:
    ldz #expr::width
    jsr loadPtr
    jsr freeExpr

    jsr peekQ
    stq ptr1
    ldz #expr::precision
    jsr loadPtr
    jsr freeExpr

    ; Left
L1: jsr peekQ
    stq ptr1
    ldz #expr::left
    jsr loadPtr
    jsr freeExpr

    ; Right
    jsr peekQ
    stq ptr1
    ldz #expr::right
    jsr loadPtr
    jsr freeExpr

    ; EvalType
    jsr peekQ
    stq ptr1
    ldz #expr::evalType
    jsr loadPtr
    jsr freeType

    jsr rtPopQ
    jsr heapFree
    rts
.endproc
