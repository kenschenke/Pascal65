;
; icodeIntOrRealMath.s
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

resultTypeOffset = 0
instructionOffset = resultTypeOffset + 1
rightTypeOffset = instructionOffset + 1
leftTypeOffset = rightTypeOffset + 1
exprOffset = leftTypeOffset + 1

.export icodeIntOrRealMath

.import loadStackValue, icodeExprRead
.import icodeOper1Short, icodeOper2Short, icodeOper3Short
.import icodeOper1Int, icodeWriteInstruction

; Expression passed in Q
.proc icodeIntOrRealMath
    stq ptr1
    jsr pushQ           ; expression
    lda #0
    jsr pushA           ; leftType
    lda #0
    jsr pushA           ; rightType
    lda #0
    jsr pushA           ; instruction

    ldz #expr::evalType
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr2
    ldz #type::kind
    nop
    lda (ptr2),z
    jsr pushA           ; resultType

    ldz #expr::left
    neg
    neg
    nop
    lda (ptr1),z
    jsr icodeExprRead
    ldz #leftTypeOffset
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
    ldz #rightTypeOffset
    nop
    sta (stackPointer),z

    ldz #exprOffset
    jsr loadStackValue
    stq ptr1
    ldz #expr::kind
    nop
    lda (ptr1),z
    cmp #EXPR_ADD
    bne :+
    lda #IC_ADD
    bra L1
:   cmp #EXPR_SUB
    bne :+
    lda #IC_SUB
    bra L1
:   cmp #EXPR_MUL
    bne :+
    lda #IC_MUL
    bra L1
:   jmp DN

L1: ldz #instructionOffset
    nop
    sta (stackPointer),z
    cmp #IC_MUL
    bne L2
    ldz #leftTypeOffset
    nop
    lda (stackPointer),z
    cmp #TYPE_POINTER
    bne L2

    ldz #exprOffset
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
    ldz #rightTypeOffset
    nop
    lda (stackPointer),z
    pha
    jsr icodeOper1Short
    pla
    jsr icodeOper3Short
    lda #TYPE_INTEGER
    jsr icodeOper2Short
    lda #IC_MUL
    jsr icodeWriteInstruction

L2: ldz #leftTypeOffset
    nop
    lda (stackPointer),z
    jsr icodeOper1Short
    ldz #rightTypeOffset
    nop
    lda (stackPointer),z
    jsr icodeOper2Short
    ldz #resultTypeOffset
    nop
    lda (stackPointer),z
    jsr icodeOper3Short
    ldz #instructionOffset
    nop
    lda (stackPointer),z
    jsr icodeWriteInstruction

DN: jsr popA                ; resultType.kind
    pha
    jsr popA                ; instruction
    jsr popA                ; rightType
    jsr popA                ; leftType
    jsr popQ                ; expression
    pla
    rts
.endproc
