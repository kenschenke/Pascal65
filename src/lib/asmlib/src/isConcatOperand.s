;
; isConcatOperand.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; freeUnits routine

.include "ast.inc"
.include "zeropage.inc"
.include "4510macros.inc"

.export isConcatOperand

.import getBaseType, isQZero

; This routine determines the expression passed in Q could be an operand
; for a string concatenation.
; The Z flag is set if so.
.proc isConcatOperand
    jsr isQZero
    bne :+
    lda #1
    rts

    ; Make sure the expression has an evalType
:   stq ptr1
    ldz #expr::evalType
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    bne :+
    lda #1
    rts

:   jsr getBaseType
    stq ptr1
    ldz #type::kind
    nop
    lda (ptr1),z
    cmp #TYPE_ARRAY
    bne :+
    ldz #type::subtype
    neg
    neg
    nop
    lda (ptr1),z
    jsr getBaseType
    stq ptr1

:   ldz #type::kind
    nop
    lda (ptr1),z
    cmp #TYPE_CHARACTER
    beq DN
    cmp #TYPE_STRING_LITERAL
    beq DN
    cmp #TYPE_STRING_OBJ
    beq DN
    cmp #TYPE_STRING_VAR
DN: rts
.endproc
