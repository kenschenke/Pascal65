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
rightExprOffset = leftTypeOffset + .sizeof(type)
leftExprOffset = rightExprOffset + 4
rightTypePtrOffset = leftExprOffset + 4
leftTypePtrOffset = rightTypePtrOffset + 4

; What getStringKind returns for a string operand
STRKIND_CHAR = 1
STRKIND_STRING = 2

.export checkRelOpOperands

.import typeCheckError, loadStackValue, isTypeNumeric, isTypeInteger, isSigned
.import typeCheckWarning, evalConstInt, constSign

.bss

leftIsSigned: .res 1

.code

; This routine checks the operands for the relative operator (less-than, greather-than, etc).
; It looks for compatibility or any warnings about sign differences (comparing
; a signed value with an unsigned value).
;
; Inputs (on runtime stack, from bottom to top)
;    Left type pointer
;    Right type pointer
;    Left expression pointer
;    Right expression pointer
;
; The routine also adds two local values to the runtime stack:
;    A type structure for the left
;    A type structure for the right
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
    bne L2
    ldz #rightTypePtrOffset
    jsr getTypeKind
    cmp #TYPE_BOOLEAN
    beq DN

    ; Two Chars, or a Char and a Char subrange, are left to the checks
    ; below: checkStringOperands sees their base types and leaves them.
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

    jsr checkStringOperands
    bcs DN
    jsr checkEnumOperands
    bcs DN
    jsr checkPointerOperands
    bcs DN

    ; If both operands are an integer type, check if the signs match.
    ; If both are not signed or both are not unsigned, issue a warning.
    jsr checkIntegerOperands

    ; Check the base types, so that an operand of a subrange type is its
    ; subrange's integer or character type
    lda #leftTypeOffset
    jsr calcTypePtr
    stq ptr1
    ldz #type::kind
    nop
    lda (ptr1),z
    cmp #TYPE_CHARACTER
    beq DN                  ; The right is Char too (checkStringOperands)
    jsr isTypeNumeric
    bne L3
    lda #rightTypeOffset
    jsr calcTypePtr
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
    jsr popQ
    jsr popQ
    rts
.endproc

; This checks the operands of a comparison if either one is a string
; operand: a String, a string literal, a string object, an array of Char
; or a Char. Two string operands compare as strings, unless both are Char,
; which compare as ordinals. A string operand with anything else is an
; error. The types on the stack are the base types.
; The carry flag is set if the comparison is a string comparison or an
; error was reported, and clear if neither operand is a string operand or
; both are Char.
.proc checkStringOperands
    lda #leftTypeOffset
    jsr getStringKind
    pha
    lda #rightTypeOffset
    jsr getStringKind
    plx                     ; X: the left's, A: the right's
    cpx #0
    beq LN                  ; Branch if the left isn't a string operand
    cmp #0
    beq ER                  ; Branch if the right isn't
    cmp #STRKIND_CHAR
    bne SC
    cpx #STRKIND_CHAR
    bne SC
NO: clc                     ; Neither, or both Char
    rts
LN: cmp #0
    beq NO
ER: lda #errIncompatibleTypes
    jsr typeCheckError
SC: sec
    rts
.endproc

; This routine returns in A what the type at the stack offset in A is as a
; string operand: 0 if it isn't one, STRKIND_CHAR for a Char, or
; STRKIND_STRING for a String, a string literal, a string object or an
; array of Char.
.proc getStringKind
    jsr calcTypePtr
    stq ptr1
    ldz #type::kind
    nop
    lda (ptr1),z
    cmp #TYPE_CHARACTER
    beq CH
    cmp #TYPE_STRING_VAR
    beq ST
    cmp #TYPE_STRING_LITERAL
    beq ST
    cmp #TYPE_STRING_OBJ
    beq ST
    cmp #TYPE_ARRAY
    bne NO
    ldz #type::subtype
    neg
    neg
    nop
    lda (ptr1),z
    jsr getBaseType
    stq ptr1
    ldz #type::kind
    nop
    lda (ptr1),z
    cmp #TYPE_CHARACTER
    beq ST
NO: lda #0
    rts
CH: lda #STRKIND_CHAR
    rts
ST: lda #STRKIND_STRING
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

; This checks the operands of a comparison if either one is a pointer or
; an address. The other one must be a pointer or an address too, or nil
; (an integer constant). Two pointers or addresses must point to the same
; kind of base type.
; The carry flag is set if left or right is a pointer or an address.
; The copies of the types on the stack are replaced by the types they
; point to.
.proc checkPointerOperands
    lda #leftTypeOffset
    jsr isPointerOperand
    beq L1
    lda #rightTypeOffset
    jsr isPointerOperand
    beq L1
    clc
    rts

    ; If one isn't a pointer, it must be nil
L1: lda #leftTypeOffset
    jsr isPointerOperand
    beq :+
    lda #leftTypeOffset
    bra L2
:   lda #rightTypeOffset
    jsr isPointerOperand
    beq L3
    lda #rightTypeOffset
L2: jsr calcTypePtr
    stq ptr1
    ldz #type::kind
    nop
    lda (ptr1),z
    jsr isTypeInteger
    bne ER
    ldz #type::flags
    nop
    lda (ptr1),z
    and #TYPE_FLAG_ISCONST
    bne DN
ER: lda #errIncompatibleTypes
    jsr typeCheckError
    bra DN

    ; Both are pointers. Replace each with the type it points to.
L3: lda #leftTypeOffset
    jsr copySubtype
    lda #rightTypeOffset
    jsr copySubtype

    ; Compare the kinds of the base types. getBaseType changes ptr1 and
    ; ptr2, so keep the left one's kind on the stack.
    lda #leftTypeOffset
    jsr calcTypePtr
    jsr getBaseType
    stq ptr3
    ldz #type::kind
    nop
    lda (ptr3),z
    pha
    lda #rightTypeOffset
    jsr calcTypePtr
    jsr getBaseType
    stq ptr3
    pla
    ldz #type::kind
    nop
    cmp (ptr3),z
    bne ER
DN: sec
    rts
.endproc

; This routine sets the Z flag if the type at the stack offset in A is a
; pointer or an address.
.proc isPointerOperand
    jsr calcTypePtr
    stq ptr1
    ldz #type::kind
    nop
    lda (ptr1),z
    cmp #TYPE_POINTER
    beq :+
    cmp #TYPE_ADDRESS
:   rts
.endproc

; This routine replaces the pointer or address type at the stack offset in
; A with a copy of the type it points to.
.proc copySubtype
    jsr calcTypePtr
    stq ptr1
    ldz #type::subtype
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
    rts
.endproc

; If both operands are an integer type, check if the signs match.
; If both are not signed or both are not unsigned, issue a warning.
; If one side is a constant AND it's negative, a warning is issued
; if the other side is an unsigned variable.
.proc checkIntegerOperands
    lda #leftTypeOffset
    jsr calcTypePtr
    stq ptr1
    ldz #type::kind
    nop
    lda (ptr1),z
    jsr isTypeInteger
    beq :+
    jmp DN
:   jsr checkConstOperand
    bcs :+
    jmp DN                  ; Branch if a side has a constant value
:   lda #leftTypeOffset
    jsr calcTypePtr
    stq ptr1
    ; Check if the left operand is a constant
    ldz #type::flags
    nop
    lda (ptr1),z
    and #TYPE_FLAG_ISCONST
    beq LeftNotConst
    ; The left operand is a constant. Check if the value is negated.
    ldz #leftExprOffset
    jsr loadStackValue
    stq ptr1
    ldz #expr::neg
    nop
    lda (ptr1),z
    beq DN
    lda #rightTypeOffset
    jsr calcTypePtr
    stq ptr1
    ldz #type::kind
    nop
    lda (ptr1),z
    jsr isSigned
    beq DN
    lda #warnMixedSignComparison
    jsr typeCheckWarning
    rts
LeftNotConst:
    ldz #type::kind
    nop
    lda (ptr1),z
    jsr isSigned
    eor #$01
StoreLeftSigned:
    sta leftIsSigned

    lda #rightTypeOffset
    jsr calcTypePtr
    stq ptr1
    ldz #type::kind
    nop
    lda (ptr1),z
    jsr isTypeInteger
    bne DN
    ; Check if the right operand is a constant
    ldz #type::flags
    nop
    lda (ptr1),z
    and #TYPE_FLAG_ISCONST
    beq RightNotConst
    ; The right operand is a constant. Check if the value is negated.
    ldz #rightExprOffset
    jsr loadStackValue
    stq ptr1
    ldz #expr::neg
    nop
    lda (ptr1),z
    beq DN
    ; If the left is an unsigned variable, issue a warning.
    lda #leftTypeOffset
    jsr calcTypePtr
    stq ptr1
    ldz #type::kind
    nop
    lda (ptr1),z
    jsr isSigned
    beq DN
    lda #warnMixedSignComparison
    jsr typeCheckWarning
    rts

RightNotConst:
    ldz #type::kind
    nop
    lda (ptr1),z
    jsr isSigned
    eor #$01
CompareSigned:
    cmp leftIsSigned
    beq DN

    lda #warnMixedSignComparison
    jsr typeCheckWarning

DN: rts
.endproc

; If a side is an expression of literals and constants (evalConstInt),
; this warns if it's negative and the other side is unsigned, and returns
; with the carry clear. Otherwise it returns with the carry set. 4 * 12 is
; an Integer, but comparing a Word with it isn't a mixed-sign comparison.
.proc checkConstOperand
    ldz #leftExprOffset
    jsr loadStackValue
    jsr evalConstInt
    bcs :+                  ; Branch if the left isn't a constant
    lda #rightTypeOffset
    bra CK
:   ldz #rightExprOffset
    jsr loadStackValue
    jsr evalConstInt
    bcs DN                  ; Branch if neither is a constant
    lda #leftTypeOffset
CK: jsr calcTypePtr         ; The other side
    stq ptr1
    ldz #type::kind
    nop
    lda (ptr1),z
    jsr isTypeInteger
    bne OK                  ; Branch if not an integer
    ldx constSign
    beq OK                  ; Branch if not negative
    jsr isSigned
    beq OK                  ; Branch if the other side is signed
    lda #warnMixedSignComparison
    jsr typeCheckWarning
OK: clc
DN: rts
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
