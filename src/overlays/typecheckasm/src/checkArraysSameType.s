;
; checkArraySameType.s
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

type2Offset = 0
type1Offset = type2Offset + 4

.export checkArraysSameType

.import typeCheckError, loadStackValue

.proc checkArraysSameType
    ; Check the element kinds are the same
    ldz #type1Offset
    jsr loadStackValue
    stq ptr1
    ldz #type::subtype
    neg
    neg
    nop
    lda (ptr1),z
    jsr getBaseType
    stq ptr1

    ldz #type2Offset
    jsr loadStackValue
    stq ptr2
    ldz #type::subtype
    neg
    neg
    nop
    lda (ptr2),z
    jsr getBaseType
    stq ptr2

    ldz #type::kind
    nop
    lda (ptr1),z
    nop
    cmp (ptr2),z
    beq :+
    lda #errInvalidType
    jsr typeCheckError

    ; Compare the indexes
:   ldz #type2Offset
    jsr loadStackValue
    jsr getBaseType
    stq ptr2
    ldz #type::indextype
    neg
    neg
    nop
    lda (ptr2),z
    stq ptr2

    ldz #type1Offset
    jsr loadStackValue
    stq ptr1
    ldz #type::indextype
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1

    ; Compare the min and max expressions
    ldz #type::min
    jsr compareSubrangeLimits
    ldz #type::max
    jsr compareSubrangeLimits

    ; Compare the index types
    ldz #type::kind
    nop
    lda (ptr1),z
    nop
    cmp (ptr2),z
    beq :+
    lda #errInvalidType
    jsr typeCheckError
:   jsr popQ
    jsr popQ
    rts
.endproc

; This routine compares the kinds (EXPR_*) and the values
; of the index limits (min or max).
; type::min or type::max is passed in Z.
.proc compareSubrangeLimits
    phz
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr3
    plz
    neg
    neg
    nop
    lda (ptr2),z
    stq ptr4
    ldz #expr::kind
    nop
    lda (ptr3),z
    nop
    cmp (ptr4),z
    beq L1
    ldq ptr1
    jsr pushQ
    ldq ptr2
    jsr pushQ
    ldq ptr3
    jsr pushQ
    ldq ptr4
    jsr pushQ
    lda #errInvalidType
    jsr typeCheckError
    jsr popQ
    stq ptr4
    jsr popQ
    stq ptr3
    jsr popQ
    stq ptr2
    jsr popQ
    stq ptr1

L1: ldz #expr::value
    ldx #0
:   nop
    lda (ptr3),z
    nop
    cmp (ptr4),z
    bne L2
    inz
    inx
    cpx #4
    bne :-
    rts
L2: ldq ptr1
    jsr pushQ
    ldq ptr2
    jsr pushQ
    lda #errInvalidType
    jsr typeCheckError
    jsr popQ
    stq ptr2
    jsr popQ
    stq ptr1
    rts
.endproc
