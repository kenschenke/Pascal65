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
.import followPtr1, loadQPtr1, loadQPtr2, typeErrInvalidType

.proc checkArraysSameType
    ; Check the element kinds are the same. Either type can be a type name
    ; (a Var parameter's is), so look up the base types first. getBaseType
    ; changes ptr1, so the first kind is kept on the stack.
    ldz #type1Offset
    jsr loadStackValue
    jsr getBaseType
    stq ptr1
    ldz #type::subtype
    jsr loadQPtr1
    jsr getBaseType
    stq ptr1
    ldz #type::kind
    nop
    lda (ptr1),z
    pha

    ldz #type2Offset
    jsr loadStackValue
    jsr getBaseType
    stq ptr2
    ldz #type::subtype
    jsr loadQPtr2
    jsr getBaseType
    stq ptr2

    pla
    ldz #type::kind
    nop
    cmp (ptr2),z
    beq :+
    jsr typeErrInvalidType

    ; Compare the indexes
:   ldz #type2Offset
    jsr loadStackValue
    jsr getBaseType
    stq ptr2
    ldz #type::indextype
    jsr loadQPtr2
    stq ptr2

    ldz #type1Offset
    jsr loadStackValue
    stq ptr1
    ldz #type::indextype
    jsr followPtr1

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
    jsr typeErrInvalidType
:   jsr popQ
    jsr popQ
    rts
.endproc

; This routine compares the kinds (EXPR_*) and the values
; of the index limits (min or max).
; type::min or type::max is passed in Z.
.proc compareSubrangeLimits
    phz
    jsr loadQPtr1
    stq ptr3
    plz
    jsr loadQPtr2
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
    jsr typeErrInvalidType
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
    jsr typeErrInvalidType
    jsr popQ
    stq ptr2
    jsr popQ
    stq ptr1
    rts
.endproc
