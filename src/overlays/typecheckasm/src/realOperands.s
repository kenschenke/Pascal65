;
; realOperands.s
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

typePtrOffset = 0
rightKindOffset = typePtrOffset + 4
leftKindOffset = rightKindOffset + 1

.export realOperands

.import isTypeNumeric, typeCheckError, getTypeConversion, getTypeSize
.import loadStackValue

.bss

resultKind: .res 1

.code

; This routine determines the expression result from two numeric operands.
; The routine is passed the following on the runtime stack, in this order:
;    The leftType kind
;    The rightType kind
;    Pointer to the result type
.proc realOperands
    ldz #leftKindOffset
    nop
    lda (stackPointer),z
    jsr isTypeNumeric
    bne ER
    ldz #rightKindOffset
    nop
    lda (stackPointer),z
    jsr isTypeNumeric
    bne ER

    ldz #rightKindOffset
    nop
    lda (stackPointer),z
    tax
    ldz #leftKindOffset
    nop
    lda (stackPointer),z
    jsr getTypeConversion
    sta resultKind
    cmp #TYPE_VOID
    beq ER

    cmp #TYPE_REAL
    bne L1
    lda #4
    pha
    lda #0
    pha
    bra L2

L1: jsr getTypeSize
    pha
    phx
L2: ldz #typePtrOffset
    jsr loadStackValue
    stq ptr1
    ldz #type::size+1
    pla
    nop
    sta (ptr1),z
    dez
    pla
    nop
    sta (ptr1),z
    ldz #type::kind
    lda resultKind
    nop
    sta (ptr1),z
    bra DN

ER: lda #errIncompatibleTypes
    jsr typeCheckError

DN: jsr popQ
    jsr popA
    jsr popA
    rts
.endproc
