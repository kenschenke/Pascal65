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

.bss

limitOffset: .res 1             ; type::min or type::max
elemKind: .res 1                ; a kind kept across getBaseType
indexSub: .res 4                ; an index type's subtype, likewise

.code

; Parameters on runtime stack, bottom to top:
;    parameters of forward declaration
;    parameters of formal declaration
.proc checkForwardVsFormalDeclaration
L1: ldz #fwdParamsOffset
    jsr loadStackValue
    stq ptr1
    jsr isQZero
    bne :+
    jmp DN
:   ldz #formalParamsOffset
    jsr loadStackValue
    stq ptr3
    jsr isQZero
    bne :+
    jmp DN

:   ldz #param_list::type
    neg
    neg
    nop
    lda (ptr1),z
    jsr getBaseType
    jsr pushQ
    ldz #param_list::type
    neg
    neg
    nop
    lda (ptr3),z
    jsr getBaseType
    stq ptr4
    jsr popQ
    stq ptr2

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
    ; Compare the types
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

; This routine checks array parameters: the base types of the elements and
; of the indexes must be the same kind, an enumeration index must be the
; same enumeration, and the limits must be the same. A parameter's type
; can be a type name, so the base types are looked up. getBaseType changes
; the pointers, so a kind and subtype are kept in elemKind and indexSub.
.proc checkArrayParams
    ; Check the array element types
    ldz #fwdParamsOffset
    jsr getElemType
    stq ptr3
    ldz #type::kind
    nop
    lda (ptr3),z
    sta elemKind
    ldz #formalParamsOffset
    jsr getElemType
    stq ptr4
    lda elemKind
    ldz #type::kind
    nop
    cmp (ptr4),z
    beq :+
    lda #errIncompatibleTypes
    jsr typeCheckError

    ; Check the array index types. A dynamic array has none.
:   ldz #fwdParamsOffset
    jsr getIndexType
    jsr isQZero
    beq L1
    stq ptr3
    ldz #type::kind
    nop
    lda (ptr3),z
    sta elemKind
    ldz #type::subtype
    neg
    neg
    nop
    lda (ptr3),z
    stq indexSub
    ldz #formalParamsOffset
    jsr getIndexType
    jsr isQZero
    beq L1
    stq ptr4
    lda elemKind
    ldz #type::kind
    nop
    cmp (ptr4),z
    bne ER
    cmp #TYPE_ENUMERATION
    bne L1
    ldz #type::subtype
    neg
    neg
    nop
    lda (ptr4),z
    stq ptr4
    ldx #0
:   lda indexSub,x
    cmp ptr4,x
    bne ER
    inx
    cpx #4
    bne :-
    bra L1
ER: lda #errIncompatibleTypes
    jsr typeCheckError
L1: lda #type::min
    jsr compareArrayLimit
    lda #type::max
    jsr compareArrayLimit
    rts
.endproc

; This routine returns the base type of the elements of the array
; parameter at the stack offset in Z.
.proc getElemType
    jsr getParamType
    jsr getBaseType
    stq ptr1
    ldz #type::subtype
    neg
    neg
    nop
    lda (ptr1),z
    jmp getBaseType
.endproc

; This routine returns the base type of the index of the array parameter
; at the stack offset in Z, or zero if it has none.
.proc getIndexType
    jsr getParamType
    jsr getBaseType
    stq ptr1
    ldz #type::indextype
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    beq :+
    jmp getBaseType
:   rts
.endproc

; This routine compares the array limits (min or max).
; The offset in the type in passed in A.
.proc compareArrayLimit
    sta limitOffset
    ; getArrayLimit looks up the base type, which destroys the
    ; pointers, so keep the forward declaration's limit on the stack.
    ; The limits are on the stack above the two parameter lists.
    ldz #fwdParamsOffset
    jsr getArrayLimit
    jsr pushQ
    ldz #formalParamsOffset+4
    jsr getArrayLimit
    stq ptr4
    jsr popQ
    stq ptr3
    ; A missing limit can't be compared
    jsr isQZero
    beq RT
    ldq ptr4
    jsr isQZero
    beq RT
    ; Compare the kinds for the min and max
    ldz #expr::kind
    nop
    lda (ptr3),z
    nop
    cmp (ptr4),z
    bne ER
    ; Compare the values for the min and max
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
RT: rts
ER: lda #errIncompatibleTypes
    jsr typeCheckError
    rts
.endproc

; This routine retrieves the array limit for the parameter list at
; the stack offset in Z and returns the expression in Q (0 if none).
; limitOffset is expected to contain the type offset for min or max.
; The limits are on the array's index type. A parameter's type can be
; a type name, so look up the base type first.
; Ptr1, ptr2 and ptr4 are destroyed.
.proc getArrayLimit
    jsr getParamType
    jsr getBaseType
    stq ptr1
    ldz #type::indextype
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    beq DN
    stq ptr1
    ldz limitOffset
    neg
    neg
    nop
    lda (ptr1),z
DN: rts
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
