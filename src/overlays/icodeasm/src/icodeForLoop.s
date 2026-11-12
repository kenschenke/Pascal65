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

; The loop is laid out as:
;
;        control := initial value
;        if control > final value, goto endfor    (< for Downto)
;   for: body
;        if control = final value, goto endfor
;        control := Succ(control)                 (Pred for Downto)
;        goto for
;   endfor:
;
; The loop stops at the final value before stepping the control variable,
; so it never steps past the end of its type. For b := 3 Downto 0 with a
; Byte or For k := Blue Downto Red would otherwise step below zero, which
; wraps around to the top of the type, and never end.
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

    ; Skip the loop if the initial value is past the final value
    jsr getStmt
    ldz #stmt::isDownTo
    nop
    lda (ptr1),z
    beq :+
    lda #IC_LST
    bra L1
:   lda #IC_GRT
L1: jsr compareAndExit

    ; The start of each iteration
    lda #<lblFor
    ldx #>lblFor
    ldy #IC_LOC
    jsr labelInstruction

    ; Body of for loop
    jsr getStmt
    ldz #stmt::body
    neg
    neg
    nop
    lda (ptr1),z
    jsr icodeStmts

    ; Stop after the iteration for the final value
    lda #IC_EQU
    jsr compareAndExit

    ; Increment or decrement the control variable
    jsr evaluateControlExpression
    ldz #controlKindOffset
    nop
    lda (stackPointer),z
    jsr icodeOper1Short
    jsr getStmt
    ldz #stmt::isDownTo
    nop
    lda (ptr1),z
    beq :+
    lda #IC_PRE
    bra L2
:   lda #IC_SUC
L2: jsr icodeWriteInstruction

    jsr getControlExpression
    stq ptr1
    ldz #expr::node
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr2                ; sym

    ldz #controlKindOffset
    nop
    lda (stackPointer),z
    pha
    ldz #expr::evalTypeFlags
    nop
    lda (ptr1),z
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

    ; Jump back up for the next iteration
    lda #<lblFor
    ldx #>lblFor
    ldy #IC_BRA
    jsr labelInstruction

    lda #<lblEndFor
    ldx #>lblEndFor
    ldy #IC_LOC
    jsr labelInstruction

    jsr popA                ; target kind
    jsr popA                ; control kind
    jsr popQ                ; stmt
    rts
.endproc

; Compares the control variable to the final value with the comparison
; instruction in A and branches to the end of the loop if it's true.
.proc compareAndExit
    pha

    ; Push the value of the control variable on to the stack
    jsr evaluateControlExpression
    ldz #controlKindOffset
    nop
    sta (stackPointer),z

    ; Push the final value on to the stack
    jsr getStmt
    ldz #stmt::to_expr
    neg
    neg
    nop
    lda (ptr1),z
    jsr icodeExprRead
    ldz #targetKindOffset
    nop
    sta (stackPointer),z

    ; Compare them
    ldz #controlKindOffset
    nop
    lda (stackPointer),z
    jsr icodeOper1Short
    ldz #targetKindOffset
    nop
    lda (stackPointer),z
    jsr icodeOper2Short
    pla
    jsr icodeWriteInstruction

    ; Branch to the end of the loop if true
    lda #<lblEndFor
    ldx #>lblEndFor
    ldy #IC_BIT
    jmp labelInstruction
.endproc

; Writes the instruction in Y with this loop's label as its operand. A/X
; points to the label's prefix.
.proc labelInstruction
    phy
    pha
    phx
    ldz #stmtOffset
    jsr loadStackValue
    stq intOp32
    plx
    pla
    jsr icodeFormatLabel
    jsr icodeOper1Label
    pla
    jmp icodeWriteInstruction
.endproc

; Loads the For statement into ptr1
.proc getStmt
    ldz #stmtOffset
    jsr loadStackValue
    stq ptr1
    rts
.endproc

; Control type kind left in A. This is the kind of the control variable's
; base type, from the type checker, which the comparisons, Succ and Pred
; need. For a subrange such as 'a'..'e' it is the subrange's base type.
.proc evaluateControlExpression
    jsr getControlExpression
    jsr icodeExprRead
    jsr getControlExpression
    stq ptr1
    ldz #expr::evalTypeKind
    nop
    lda (ptr1),z
    rts
.endproc

; Returns the control variable's expression in Q
.proc getControlExpression
    jsr getStmt
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
    rts
.endproc
