;
; icodeCompExpr.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

.include "ast.inc"
.include "icode.inc"
.include "asmlib.inc"
.include "zeropage.inc"
.include "4510macros.inc"

rightKindOffset = 0
leftKindOffset = rightKindOffset + 1
instructionOffset = leftKindOffset + 1
exprOffset = instructionOffset + 1

.export icodeCompExpr

.import loadStackValue, icodeExprRead
.import icodeOper1Short, icodeOper2Short, icodeWriteInstruction

; Expression passed in Q
.proc icodeCompExpr
    stq ptr1
    jsr pushQ

    lda #0
    jsr pushA               ; instruction
    lda #0
    jsr pushA               ; leftKind
    lda #0
    jsr pushA               ; rightKind

    ldz #expr::kind
    nop
    lda (ptr1),z
    cmp #EXPR_EQ
    bne :+
    lda #IC_EQU
    bra L1
:   cmp #EXPR_LT
    bne :+
    lda #IC_LST
    bra L1
:   cmp #EXPR_LTE
    bne :+
    lda #IC_LSE
    bra L1
:   cmp #EXPR_GT
    bne :+
    lda #IC_GRT
    bra L1
:   cmp #EXPR_GTE
    bne :+
    lda #IC_GTE
    bra L1
:   cmp #EXPR_NE
    bne :+
    lda #IC_NEQ
    bra L1
:   jmp DN

L1: ldz #instructionOffset
    nop
    sta (stackPointer),z

    ldz #exprOffset
    jsr loadStackValue
    stq ptr1
    ldz #expr::left
    neg
    neg
    nop
    lda (ptr1),z
    jsr icodeExprRead
    ldz #leftKindOffset
    nop
    sta (stackPointer),z

    ldz #exprOffset
    jsr loadStackValue
    stq ptr1
    ldz #expr::right
    neg
    neg
    nop
    lda (ptr1),z
    jsr icodeExprRead
    ldz #rightKindOffset
    nop
    sta (stackPointer),z

    ldz #leftKindOffset
    nop
    lda (stackPointer),z
    cmp #TYPE_ENUMERATION
    beq LW
    cmp #TYPE_ENUMERATION_VALUE
    bne L2
LW: lda #TYPE_WORD
    ldz #leftKindOffset
    nop
    sta (stackPointer),z

L2: ldz #rightKindOffset
    nop
    lda (stackPointer),z
    cmp #TYPE_ENUMERATION
    beq RW
    cmp #TYPE_ENUMERATION_VALUE
    bne L3
RW: lda #TYPE_WORD
    ldz #rightKindOffset
    nop
    sta (stackPointer),z

L3: ldz #leftKindOffset
    nop
    lda (stackPointer),Z
    jsr icodeOper1Short
    ldz #rightKindOffset
    nop
    lda (stackPointer),z
    jsr icodeOper2Short
    ldz #instructionOffset
    nop
    lda (stackPointer),z
    jsr icodeWriteInstruction

DN: jsr popA
    jsr popA
    jsr popA
    jsr popQ
    rts
.endproc
