;
; checkForwardVsFormalDeclaration.s
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

formalParamsOffset = 0
fwdParamsOffset = formalParamsOffset + 4

.export checkForwardVsFormalDeclaration

.import loadStackValue, typeCheckError

.proc checkForwardVsFormalDeclaration
L1: ldz #fwdParamsOffset
    jsr loadStackValue
    stq ptr1
    jsr isQZero
    beq DN
    ldz #formalParamsOffset
    jsr loadStackValue
    stq ptr3
    jsr isQZero
    beq DN

    ldz #param_list::type
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr2
    ldz #param_list::type
    neg
    neg
    nop
    lda (ptr3),z
    stq ptr4

    ; If fwdType.kind != formalType.kind
    ldz #type::kind
    nop
    lda (ptr2),z
    nop
    cmp (ptr4),z
    beq L2
    lda #errIncompatibleTypes
    jsr typeCheckError
    jmp NX

    ; If fwdType.kind == TYPE_ENUMERATION
L2: ldz #type::kind
    nop
    lda (ptr2),z
    cmp #TYPE_ENUMERATION
    bne L3
    ldz #type::subtype
    neg
    neg
    nop
    lda (ptr2),z
    stq ptr2
    ldz #type::subtype
    neg
    neg
    nop
    lda (ptr4),z
    stq ptr4
    ; Compare the subtypes
    ldx #0
:   lda ptr2,x
    cmp ptr4,x
    bne :+
    inx
    cpx #4
    bne :-
    bra NX
:   lda #errIncompatibleTypes
    jsr typeCheckError
    bra NX

    ; If fwdType.kind == TYPE_ARRAY
L3: cmp #TYPE_ARRAY
    bne NX
    jsr checkArrayParams

NX: ldz #formalParamsOffset
    jsr goToNext
    ldz #fwdParamsOffset
    jsr goToNext
    jmp L1

DN: ldz #fwdParamsOffset
    jsr loadStackValue
    jsr isQZero
    bne ER
    ldz #formalParamsOffset
    jsr loadStackValue
    jsr isQZero
    beq RT
ER: lda #errWrongNumberOfParams
    jsr typeCheckError
RT: jsr popQ
    jsr popQ
    rts
.endproc

; This routine goes to the next parameter in the param_list chain.
; The offset on the stack is passed in Z.
.proc goToNext
    phz
    jsr loadStackValue
    stq ptr1
    ldz #param_list::next
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr2
    plz
    ldx #0
:   lda ptr2,x
    nop
    sta (stackPointer),z
    inx
    inz
    cpx #4
    bne :-
    rts
.endproc

.proc checkArrayParams
    ; Check the array element types
    ldz #fwdParamsOffset
    jsr getParamType
    stq ptr3
    ldz #type::subtype
    neg
    neg
    nop
    lda (ptr3),z
    jsr getBaseType
    stq ptr3
    ldz #formalParamsOffset
    jsr getParamType
    stq ptr4
    ldz #type::subtype
    neg
    neg
    nop
    lda (ptr4),z
    jsr getBaseType
    stq ptr4
    ldz #type::kind
    nop
    lda (ptr3),z
    nop
    cmp (ptr4),z
    beq :+
    lda #errIncompatibleTypes
    jsr typeCheckError

    ; Check the array index types
:   ldz #fwdParamsOffset
    jsr getParamType
    stq ptr3
    ldz #type::indextype
    neg
    neg
    nop
    lda (ptr3),z
    jsr getBaseType
    stq ptr3
    ldz #type::subtype
    neg
    neg
    nop
    lda (ptr3),z
    stq ptr3
    ldz #formalParamsOffset
    jsr getParamType
    stq ptr4
    ldz #type::indextype
    neg
    neg
    nop
    lda (ptr4),z
    jsr getBaseType
    stq ptr4
    ldz #type::subtype
    neg
    neg
    nop
    lda (ptr4),z
    stq ptr4
    ldx #0
:   lda ptr3,x
    cmp ptr4,x
    bne :+
    inx
    cpx #4
    bne :-
    bra L1
:   lda #errIncompatibleTypes
    jsr typeCheckError
L1: lda #type::min
    jsr compareArrayLimit
    lda #type::max
    jsr compareArrayLimit
    rts
.endproc

; This routine compares the array limits (min or max).
; The offset in the type in passed in A.
.proc compareArrayLimit
    sta tmp1
    ; Compare the kinds for the min and max
    ldz #fwdParamsOffset
    jsr getArrayLimit
    stq ptr3
    ldz #formalParamsOffset
    jsr getArrayLimit
    stq ptr4
    ldz #expr::kind
    nop
    lda (ptr3),z
    nop
    cmp (ptr4),z
    beq :+
    lda #errIncompatibleTypes
    jsr typeCheckError
    ; Compare the values for the min and max
:   ldz #fwdParamsOffset
    jsr getArrayLimit
    stq ptr3
    ldz #formalParamsOffset
    jsr getArrayLimit
    stq ptr4
    ldz #expr::value
    ldx #0
:   nop
    lda (ptr3),z
    nop
    cmp (ptr4),z
    bne ER
    inz
    inx
    cpx #4
    bne :-
    rts
ER: lda #errIncompatibleTypes
    jsr typeCheckError
    rts
.endproc

; This routine retrieves the array limit for the offset in Z.
; and returns the expression in Q.
; tmp1 is expected to contain the expr offset for min or max.
; Ptr1 is destroyed
.proc getArrayLimit
    jsr getParamType
    stq ptr1
    ldz tmp1
    neg
    neg
    nop
    lda (ptr1),z
    rts
.endproc

; This routine gets the type of the parameter offset in Z.
; The type is returned in Q.
; Ptr1 is destroyed.
.proc getParamType
    jsr loadStackValue
    stq ptr1
    ldz #param_list::type
    neg
    neg
    nop
    lda (ptr1),z
    rts
.endproc
