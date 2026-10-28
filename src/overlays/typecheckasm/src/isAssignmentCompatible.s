;
; isAssignmentCompatible.s
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

exprRightOffset = 0
rightTypeOffset = exprRightOffset + 4
leftKindOffset = rightTypeOffset + 4

.export isAssignmentCompatible, checkIntegerPrecisionWarning, isSigned

.import isTypeInteger, loadStackValue, typeCheckWarning

.bss

leftKind: .res 1            ; This is only populated when both the left and right kinds are integers.
rightKind: .res 1

leftSize: .res 1            ; This is only populated when the left kind is an integer.
rightSize: .res 1           ; This is only populated when the right kind is an integer.

.data

; Maximum values for integer types
maxShortInt: .dword $7f
maxByte: .dword $ff
maxInteger: .dword $7fff
maxWord: .dword $ffff
maxLongInt: .dword $7fffffff
maxCardinal: .dword $ffffffff

.code

; On exit, the Z flag is set if the assignment is compatible.
.proc isAssignmentCompatible
    ; If the right expression is a type cast, then the type kind should be evalTypeKind
    ldz #exprRightOffset
    jsr loadStackValue
    jsr isQZero
    beq L1
    stq ptr1
    ldz #expr::kind
    nop
    lda (ptr1),z
    cmp #EXPR_CAST
    bne L1
    ldz #expr::evalTypeKind
    nop
    lda (ptr1),z
    bra L2

L1: ldz #rightTypeOffset
    jsr loadStackValue
    stq ptr1
    ldz #type::kind
    nop
    lda (ptr1),z
L2: sta rightKind
    ldz #leftKindOffset
    nop
    lda (stackPointer),z
    cmp rightKind
    bne :+
    lda #0
    bra DN

:   jsr isTypeInteger       ; left kind is still in A
    bne NO
    sta leftKind
    lda rightKind
    jsr isTypeInteger
    bne NO
    ldz #exprRightOffset
    jsr loadStackValue
    stq ptr1
    lda leftKind
    ldx rightKind
    jsr checkIntegerPrecisionWarning
    lda #0
    bra DN

NO: lda #1
DN: pha
    jsr popQ
    jsr popQ
    jsr popA
    pla
    rts
.endproc

; Inputs: A = target integer kind, X = source integer kind, ptr1 = source expression.
; Checks for potential precision loss when converting to a smaller integer type.
; The routine also checks for potential precision loss when converting a signed integer to an unsigned
; integer of any size or an unsigned integer to a signed integer of equal or smaller size.
; If precision loss is possible, this routine issues a warning.
.proc checkIntegerPrecisionWarning
    sta leftKind
    stx rightKind
    lda leftKind
    jsr getIntegerSize
    sta leftSize
    lda rightKind
    jsr getIntegerSize
    sta rightSize

    lda leftSize
    cmp rightSize
    bcs NoSizeLoss
    lda #warnLossOfPrecision
    jsr typeCheckWarning
    rts

NoSizeLoss:
    ; Check if the right side is a constant. If so, check if the value would
    ; fit into the left side without precision loss.
    ldz #expr::evalTypeFlags
    nop
    lda (ptr1),z
    and #TYPE_FLAG_ISCONST
    beq NotConstant
    jsr checkConstantFitsLeft
    beq :+
    lda #warnLossOfPrecision
    jsr typeCheckWarning
:   rts

NotConstant:
    ; Check if assigning a signed integer to an unsigned integer of any size.
    lda leftKind
    jsr isSigned
    beq NoSignLoss          ; If left is unsigned, no warning needed
    lda rightKind
    jsr isSigned
    bne NoSignLoss          ; If right is signed, no warning needed
    lda #warnLossOfPrecision
    jsr typeCheckWarning
    rts

NoSignLoss:
    ; Check if assigning an unsigned integer to a signed integer of equal or smaller size.
    lda leftKind
    jsr isSigned
    bne NoEndCheck          ; If left is signed, no warning needed
    lda rightKind
    jsr isSigned
    beq NoEndCheck          ; If right is unsigned, no warning needed
    lda rightSize
    cmp leftSize
    bcc NoEndCheck          ; If left size is smaller, no warning needed
    lda #warnLossOfPrecision
    jsr typeCheckWarning

NoEndCheck:
    rts
.endproc

; This routine returns the size of an integer type in bytes.
; Input: The type kind of the integer type in the A register.
; Output: The size of the integer type in bytes in the A register.
.proc getIntegerSize
    cmp #TYPE_BYTE
    beq Size8
    cmp #TYPE_SHORTINT
    beq Size8
    cmp #TYPE_WORD
    beq Size16
    cmp #TYPE_INTEGER
    beq Size16
    cmp #TYPE_CARDINAL
    beq Size32
    cmp #TYPE_LONGINT
    beq Size32

    lda #0
    rts

Size32:
    lda #4
    rts

Size8:
    lda #1
    rts

Size16:
    lda #2
    rts
.endproc

; This routine checks if an integer type is signed.
; Input: The type kind of the integer type in the A register.
; Output: A = 0 if signed, A = 1 if unsigned
.proc isSigned
    cmp #TYPE_BYTE
    beq SignedNo
    cmp #TYPE_SHORTINT
    beq SignedYes
    cmp #TYPE_WORD
    beq SignedNo
    cmp #TYPE_INTEGER
    beq SignedYes
    cmp #TYPE_CARDINAL
    beq SignedNo
    cmp #TYPE_LONGINT
    beq SignedYes

SignedNo:
    lda #1
    rts

SignedYes:
    lda #0
    rts
.endproc

; This routine checks if the constant expression in ptr1 fits
; into the left side type without precision loss.
;
; Returns: A = 0 if the constant fits, A = 1 otherwise
.proc checkConstantFitsLeft
    ; First, check if the left is a signed type.
    lda leftKind
    jsr isSigned
    beq :+              ; Branch if a signed type
    ; The left is an unsigned type. Check if the constant is negated.
    ldz #expr::neg
    nop
    lda (ptr1),z
    beq :+              ; Branch if not negated
    ; The left is an unsigned type and the constant is negated.
    lda #warnLossOfPrecision
    jsr typeCheckWarning
    ; Already flagged a warning for this expression, so skip more checking.
    lda #0              ; Set the Z flag so the caller doesn't issure another warning.
    rts
:   lda leftKind
    cmp #TYPE_BYTE
    bne :+
    ldq maxByte
    bra L1
:   cmp #TYPE_SHORTINT
    bne :+
    ldq maxShortInt
    bra L1
:   cmp #TYPE_WORD
    bne :+
    ldq maxWord
    bra L1
:   cmp #TYPE_INTEGER
    bne :+
    ldq maxInteger
    bra L1
:   cmp #TYPE_LONGINT
    bne :+
    ldq maxLongInt
    bra L1
:   ldq maxCardinal
L1: stq intOp32
    ldz #expr::value
    neg
    neg
    nop
    lda (ptr1),z
    stq intOp1

    ; If they are equal it fits
    ldx #0
:   lda intOp1,x
    cmp intOp32,x
    bne L2
    inx
    cpx #4
    bne :-
    lda #0
    rts

L2: jsr geUint32
    rts
.endproc
