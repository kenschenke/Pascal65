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

    ; Value
    jsr peekQ
    stq ptr1
    ldz #expr::kind
    nop
    lda (ptr1),z
    cmp #EXPR_REAL_LITERAL
    bne :+
    jsr freeValueString
    bra L1
:   cmp #EXPR_STRING_LITERAL
    bne L1
    jsr freeValueString

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

    ; Width
    jsr peekQ
    stq ptr1
    ldz #expr::width
    jsr loadPtr
    jsr freeExpr

    ; Precision
    jsr peekQ
    stq ptr1
    ldz #expr::precision
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

.proc freeValueString
    ldz #expr::value
    jsr loadPtr
    jsr isQZero
    beq :+
    jsr heapFree
:   rts
.endproc
