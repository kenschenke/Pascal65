;
; icodeDecIncCall.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

.include "ast.inc"
.include "icode.inc"
.include "asmlib.inc"
.include "symtab.inc"
.include "zeropage.inc"
.include "4510macros.inc"

argPtrOffset = 0
routineCodeOffset = argPtrOffset + 4

.export icodeDecIncCall

.import loadStackValue, icodeExprRead, icodeOper1Short, icodeWriteInstruction
.import icodeExpr, icodeOper2Short, icodeOper3Short, icodeOper1Int

.bss

amountType: .res 1
rightArg: .res 4
varTypeKind: .res 1

.code

; Arguments passed on stack, bottom to top:
;   routine code
;   expression arguments
.proc icodeDecIncCall
    ; Push variable value onto stack
    ldz #argPtrOffset
    jsr loadStackValue
    stq ptr1
    ldz #expr::left
    neg
    neg
    nop
    lda (ptr1),z
    jsr icodeExprRead

    ldz #argPtrOffset
    jsr loadStackValue
    stq ptr1
    ldz #expr::right
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero                 ; Was there a second argument?
    beq I1                      ; Branch if only one argument

    ; Increment value is second argument.
    stq ptr1
    stq rightArg
    ldz #expr::left
    neg
    neg
    nop
    lda (ptr1),z
    jsr icodeExprRead
    ldq rightArg
    stq ptr1
    ldz #expr::left
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    ldz #expr::evalTypeKind
    nop
    lda (ptr1),z
    sta amountType
    bra L1

    ; Increment value is one
I1: lda #1
    jsr icodeOper1Short
    lda #IC_PSH
    jsr icodeWriteInstruction
    lda #TYPE_BYTE
    sta amountType

    ; Is the variable being incremented a pointer?
L1: ldz #argPtrOffset
    jsr loadStackValue
    stq ptr1
    ldz #expr::left
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    ldz #expr::evalType
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    ldz #type::kind
    nop
    lda (ptr1),z
    cmp #TYPE_POINTER
    bne L2
    ; The increment amount needs to be multiplied by the
    ; size of the pointer's data type.
    ldz #type::subtype
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    ldz #type::size+1
    nop
    lda (ptr1),z
    tax
    dez
    nop
    lda (ptr1),z
    jsr icodeOper1Int
    lda #IC_PSH
    jsr icodeWriteInstruction
    lda amountType
    jsr icodeOper1Short
    lda #TYPE_INTEGER
    jsr icodeOper2Short
    lda amountType
    jsr icodeOper3Short
    lda #IC_MUL
    jsr icodeWriteInstruction

L2: ldz #argPtrOffset
    jsr loadStackValue
    stq ptr1
    ldz #expr::left
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    ldz #expr::evalTypeKind
    nop
    lda (ptr1),z
    sta varTypeKind
    cmp #TYPE_CHARACTER
    bne :+
    lda #TYPE_SHORTINT
    sta varTypeKind
    bra L3
:   cmp #TYPE_ENUMERATION
    bne L3
    lda #TYPE_INTEGER
    sta varTypeKind

L3: lda varTypeKind
    jsr icodeOper1Short
    lda amountType
    jsr icodeOper2Short
    lda varTypeKind
    jsr icodeOper3Short
    ldz #routineCodeOffset
    nop
    lda (stackPointer),z
    cmp #rcInc
    beq :+
    lda #IC_SUB
    bra L4
:   lda #IC_ADD
L4: jsr icodeWriteInstruction

    ldz #argPtrOffset
    jsr loadStackValue
    stq ptr1
    ldz #expr::left
    neg
    neg
    nop
    lda (ptr1),z
    jsr pushQ
    lda #0
    jsr pushA
    jsr icodeExpr

    lda varTypeKind
    jsr icodeOper1Short
    lda varTypeKind
    jsr icodeOper2Short
    lda #IC_SET
    jsr icodeWriteInstruction

    jsr popQ
    jsr popA
    rts
.endproc
