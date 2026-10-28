;
; isExprARoutineCall.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

.include "ast.inc"
.include "zeropage.inc"
.include "4510macros.inc"

.export isExprARoutineCall

; This routine is called by exprTypeCheck to determine if an EXPR_CALL expression
; is a routine call. At the time this routine is called, the EXPR_CALL can possibly be
; a type cast, which syntactically looks like a routine call. This routine looks at
; the node of the expression and determines if the type is a TYPE_PROCEDURE or
; TYPE_FUNCTION.
;
; Inputs:
;    Expression pointer in Q.
;
; Outputs:
;    Z flag is set if the expression is a routine call
.proc isExprARoutineCall
    stq ptr1
    ldz #expr::node
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    ldz #symbol::type
    neg
    neg
    nop
    lda (ptr1),z
    jsr getBaseType
    stq ptr1
    ldz #type::kind
    nop
    lda (ptr1),z
    cmp #TYPE_ROUTINE_POINTER
    bne :+
    ldz #type::subtype
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    ldz #type::kind
    nop
    lda (ptr1),z
:   cmp #TYPE_PROCEDURE
    beq :+
    cmp #TYPE_FUNCTION
:   rts
.endproc
