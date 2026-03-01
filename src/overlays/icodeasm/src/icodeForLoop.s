;
; icodeForLoop.s
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

targetKindOffset = 0
controlKindOffset = targetKindOffset + 1
stmtOffset = controlKindOffset + 1

.export icodeForLoop

.import icodeExprRead, loadStackValue, icodeFormatLabel, icodeLabel
.import icodeWriteInstruction, icodeOper1Label, icodeOper1Short
.import icodeOper2Short, icodeStmts, icodeVar

.data

lblFor: .asciiz "for"
lblEndFor: .asciiz "endfor"

.code

.proc icodeForLoop
    stq ptr1
    jsr pushQ               ; stmt
    lda #0
    jsr pushA               ; control kind
    lda #0
    jsr pushA               ; target kind

    ; Emit the initialization expression
    ldz #stmt::init_expr
    neg
    neg
    nop
    lda (ptr1),z
    jsr icodeExprRead

    ; Initialize the start of each iteration
    ldz #stmtOffset
    jsr loadStackValue
    stq intOp32
    lda #<lblFor
    ldx #>lblFor
    jsr icodeFormatLabel
    jsr icodeOper1Label
    lda #IC_LOC
    jsr icodeWriteInstruction

    ; Push the value of the control variable on to the stack
    jsr evaluateControlExpression
    ldz #controlKindOffset
    nop
    sta (stackPointer),z

    ; Push the target value on to the stack
    ldz #stmtOffset
    jsr loadStackValue
    stq ptr1
    ldz #stmt::to_expr
    neg
    neg
    nop
    lda (ptr1),z
    jsr icodeExprRead
    ldz #targetKindOffset
    nop
    sta (stackPointer),z

    ; Compare the control value to the target value
    ldz #controlKindOffset
    nop
    lda (stackPointer),z
    jsr icodeOper1Short
    ldz #targetKindOffset
    nop
    lda (stackPointer),z
    jsr icodeOper2Short
    ldz #stmtOffset
    jsr loadStackValue
    stq ptr1
    ldz #stmt::isDownTo
    nop
    lda (ptr1),z
    beq :+
    lda #IC_LST
    bra L1
:   lda #IC_GRT
L1: jsr icodeWriteInstruction
    
    ; Branch to the end of the loop if true
    ; Initialize the start of each iteration
    ldz #stmtOffset
    jsr loadStackValue
    stq intOp32
    lda #<lblEndFor
    ldx #>lblEndFor
    jsr icodeFormatLabel
    jsr icodeOper1Label
    lda #IC_BIT
    jsr icodeWriteInstruction

    ; Body of for loop
    ldz #stmtOffset
    jsr loadStackValue
    stq ptr1
    ldz #stmt::body
    neg
    neg
    nop
    lda (ptr1),z
    jsr icodeStmts

    ; Increment or decrement the control variable
    jsr evaluateControlExpression
    ldz #controlKindOffset
    nop
    lda (stackPointer),z
    jsr icodeOper1Short
    ldz #stmtOffset
    jsr loadStackValue
    stq ptr1
    ldz #stmt::isDownTo
    nop
    lda (ptr1),z
    beq :+
    lda #IC_PRE
    bra L2
:   lda #IC_SUC
L2: jsr icodeWriteInstruction

    ldz #stmtOffset
    jsr loadStackValue
    stq ptr1
    ldz #stmt::init_expr
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    ldz #expr::left
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    ldz #expr::node
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr2                ; sym
    ldz #expr::evalType
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr3                ; controlType

    ldz #controlKindOffset
    nop
    lda (stackPointer),z
    pha
    ldz #type::flags
    nop
    lda (ptr3),z
    and #TYPE_FLAG_ISBYREF
    beq :+
    lda #IC_VVW
    bra L3
:   lda #IC_VDW
L3: jsr pushA               ; operation
    pla
    jsr pushA               ; control kind
    ldz #symbol::level
    nop
    lda (ptr2),z
    jsr pushA               ; level
    ldz #symbol::offset
    nop
    lda (ptr2),z
    jsr pushA               ; offset
    jsr icodeVar

    ldz #controlKindOffset
    nop
    lda (stackPointer),z
    pha
    jsr icodeOper1Short
    pla
    jsr icodeOper2Short
    lda #IC_SET
    jsr icodeWriteInstruction

    ; Jump back up and check the control variable for the next iteration
    ldz #stmtOffset
    jsr loadStackValue
    stq intOp32
    lda #<lblFor
    ldx #>lblFor
    jsr icodeFormatLabel
    jsr icodeOper1Label
    lda #IC_BRA
    jsr icodeWriteInstruction

    ldz #stmtOffset
    jsr loadStackValue
    stq intOp32
    lda #<lblEndFor
    ldx #>lblEndFor
    jsr icodeFormatLabel
    jsr icodeOper1Label
    lda #IC_LOC
    jsr icodeWriteInstruction

    jsr popA                ; target kind
    jsr popA                ; control kind
    jsr popQ                ; stmt
    rts
.endproc

; Control type kind left in A
.proc evaluateControlExpression
    ldz #stmtOffset
    jsr loadStackValue
    stq ptr1
    ldz #stmt::init_expr
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    ldz #expr::left
    neg
    neg
    nop
    lda (ptr1),z
    jsr icodeExprRead
    rts
.endproc
