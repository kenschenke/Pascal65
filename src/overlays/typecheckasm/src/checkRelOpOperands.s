;
; checkRelOpOperands.s
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

rightTypeOffset = 0
leftTypeOffset = rightTypeOffset + .sizeof(type)
rightTypePtrOffset = leftTypeOffset + .sizeof(type)
leftTypePtrOffset = rightTypePtrOffset + 4

.export checkRelOpOperands

.import typeCheckError, loadStackValue, isTypeNumeric

.proc checkRelOpOperands
    lda #.sizeof(type)
    jsr pushBlock
    lda #.sizeof(type)
    jsr pushBlock

    lda #leftTypeOffset
    ldx #leftTypePtrOffset
    jsr copyType

    lda #rightTypeOffset
    ldx #rightTypePtrOffset
    jsr copyType

    ldz #leftTypePtrOffset
    jsr getTypeKind
    cmp #TYPE_BOOLEAN
    bne L1
    ldz #rightTypePtrOffset
    jsr getTypeKind
    cmp #TYPE_BOOLEAN
    beq DN

L1: ldz #leftTypePtrOffset
    jsr getTypeKind
    cmp #TYPE_CHARACTER
    bne L2
    ldz #rightTypePtrOffset
    jsr getTypeKind
    cmp #TYPE_CHARACTER
    beq DN

L2: lda #leftTypeOffset
    jsr calcTypePtr
    jsr getBaseType
    ldz #leftTypeOffset
    jsr copyToType
    lda #rightTypeOffset
    jsr calcTypePtr
    jsr getBaseType
    ldz #rightTypeOffset
    jsr copyToType

    jsr checkEnumOperands
    bcs DN
    jsr checkPointerOperands
    bcs DN

    ldz #leftTypePtrOffset
    jsr loadStackValue
    stq ptr1
    ldz #type::kind
    nop
    lda (ptr1),z
    jsr isTypeNumeric
    bne L3
    ldz #rightTypePtrOffset
    jsr loadStackValue
    stq ptr1
    ldz #type::kind
    nop
    lda (ptr1),z
    jsr isTypeNumeric
    beq DN

L3: lda #errIncompatibleTypes
    jsr typeCheckError

DN: lda #.sizeof(type)
    jsr popBlock
    lda #.sizeof(type)
    jsr popBlock
    jsr popQ
    jsr popQ
    rts
.endproc

; This checks if the left and right types are both enumerations.
; If so, it checks they are the same enumeration type.
; The carry flag is set if left and right are enumerations.
.proc checkEnumOperands
    lda #leftTypeOffset
    jsr calcTypePtr
    stq ptr1
    ldz #type::kind
    nop
    lda (ptr1),z
    cmp #TYPE_ENUMERATION
    beq L1
    cmp #TYPE_ENUMERATION_VALUE
    beq L1
    clc
    rts

L1: lda #rightTypeOffset
    jsr calcTypePtr
    stq ptr2
    ldz #type::kind
    nop
    lda (ptr2),z
    cmp #TYPE_ENUMERATION
    beq L2
    cmp #TYPE_ENUMERATION_VALUE
    beq L2
    clc
    rts

L2: ldz #type::subtype
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr3
    ldz #type::paramFields
    neg
    neg
    nop
    lda (ptr3),z
    stq ptr3
    ldz #type::subtype
    neg
    neg
    nop
    lda (ptr2),z
    stq ptr4
    ldz #type::paramFields
    neg
    neg
    nop
    lda (ptr4),z
    stq ptr4
    ldx #0
:   lda ptr3,x
    cmp ptr4,x
    bne L3
    inx
    cpx #4
    bne :-
    bra L4
L3: lda #errIncompatibleTypes
    jsr typeCheckError
L4: sec
    rts
.endproc

; This checks if the left or right is a pointer and the right is an address.
; If so, it checks they are the same base type.
; The carry flag is set if left or right are pointers.
.proc checkPointerOperands
    lda #leftTypeOffset
    jsr calcTypePtr
    stq ptr1
    ldz #type::kind
    nop
    lda (ptr1),z
    cmp #TYPE_POINTER
    beq L1

    lda #rightTypeOffset
    jsr calcTypePtr
    stq ptr2
    ldz #type::kind
    nop
    lda (ptr2),z
    cmp #TYPE_POINTER
    beq L1

    clc
    rts

L1: ldz #type::kind
    nop
    lda (ptr1),z
    cmp #TYPE_POINTER
    beq L2
    cmp #TYPE_ADDRESS
    bne L3
    ; Retrieve the subtype and copy it into leftType.
L2: ldz #type::subtype
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr3
    ldz #0
:   nop
    lda (ptr3),z
    nop
    sta (ptr1),z
    inz
    cpz #.sizeof(type)
    bne :-

L3: ldz #type::kind
    nop
    lda (ptr2),z
    cmp #TYPE_POINTER
    beq L4
    cmp #TYPE_ADDRESS
    bne L5
    ; Retrieve the subtype and copy it into rightType.
L4: ldz #type::subtype
    neg
    neg
    nop
    lda (ptr2),z
    stq ptr4
    ldz #0
:   nop
    lda (ptr4),z
    nop
    sta (ptr2),z
    inz
    cpz #.sizeof(type)
    bne :-
L5: ldz #type::kind
    nop
    lda (ptr1),z
    nop
    cmp (ptr2),z
    beq L6
    lda #errIncompatibleTypes
    jsr typeCheckError
L6: rts
.endproc

; This routine returns the type kind for the type offset in Z
.proc getTypeKind
    jsr loadStackValue
    stq ptr1
    ldz #type::kind
    nop
    lda (ptr1),z
    rts
.endproc

; This routine calculates the pointer of the type stored on the stack.
; The stack offset is passed in A and the pointer is returned in Q.
.proc calcTypePtr
    sta intOp32
    lda #0
    sta intOp32+1
    sta intOp32+2
    sta intOp32+3
    ldq stackPointer
    clc
    adcq intOp32
    rts
.endproc

; This routine copies a type structure from the offset in X to A.
.proc copyType
    phx
    jsr calcTypePtr
    stq ptr1                ; dest
    plz
    jsr loadStackValue
    stq ptr2                ; source
    ldz #0
:   nop
    lda (ptr2),z
    nop
    sta (ptr1),z
    inz
    cpz #.sizeof(type)
    bne :-
    rts
.endproc

; This routine copies the type pointed at in Q to the
; left on the stack in offset Z.
; ptr1 and ptr2 are destroyed
.proc copyToType
    phz
    ldz #0
    stq ptr2                ; source in ptr2
    pla
    jsr calcTypePtr
    stq ptr1                ; dest in ptr1
    ldz #0
:   nop
    lda (ptr2),z
    nop
    sta (ptr1),z
    inz
    cpz #.sizeof(type)
    bne :-
    rts
.endproc
