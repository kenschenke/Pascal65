;
; icodeIfStmt.s
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

stmtOffset = 0

.export icodeIfStmt

.import loadStackValue, icodeFormatLabel, icodeLabel, icodeWriteInstruction
.import icodeOper1Label, icodeExprRead, icodeStmts

.data

lblElse: .asciiz "else"
lblEndIf: .asciiz "endif"

.code

; Statement passed in Q
.proc icodeIfStmt
    stq ptr1
    jsr pushQ

    ; Evaluate the expression
    ldz #stmt::expr
    neg
    neg
    nop
    lda (ptr1),z
    jsr icodeExprRead

    ldz #stmtOffset
    jsr loadStackValue
    stq ptr1
    ldz #stmt::else_body
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    bne :+      ; Branch if else stmt(s)
    ; No else body, so the IF statement ends if the expression is false
    ldq ptr1
    stq intOp32
    lda #<lblEndIf
    ldx #>lblEndIf
    jsr icodeFormatLabel
    bra L1

    ; There is an else body, so the IF statement branches to it
    ; if the expression is false
:   ldq ptr1
    stq intOp32
    lda #<lblElse
    ldx #>lblElse
    jsr icodeFormatLabel

L1: jsr icodeOper1Label
    lda #IC_BIF
    jsr icodeWriteInstruction

    ; Generate the IF true body
    ldz #stmtOffset
    jsr loadStackValue
    stq ptr1
    ldz #stmt::body
    neg
    neg
    nop
    lda (ptr1),z
    jsr icodeStmts

    ; Is there an else body?
    ldz #stmtOffset
    jsr loadStackValue
    stq ptr1
    ldz #stmt::else_body
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    beq L2              ; Branch if no else body

    ; Generate the "else" body
    ldq ptr1
    stq intOp32
    lda #<lblEndIf
    ldx #>lblEndIf
    jsr icodeFormatLabel
    jsr icodeOper1Label
    lda #IC_BRA
    jsr icodeWriteInstruction

    ldz #stmtOffset
    jsr loadStackValue
    stq intOp32
    lda #<lblElse
    ldx #>lblElse
    jsr icodeFormatLabel
    jsr icodeOper1Label
    lda #IC_LOC
    jsr icodeWriteInstruction

    ldz #stmtOffset
    jsr loadStackValue
    stq ptr1
    ldz #stmt::else_body
    neg
    neg
    nop
    lda (ptr1),z
    jsr icodeStmts

L2: ldz #stmtOffset
    jsr loadStackValue
    stq intOp32
    lda #<lblEndIf
    ldx #>lblEndIf
    jsr icodeFormatLabel
    jsr icodeOper1Label
    lda #IC_LOC
    jsr icodeWriteInstruction

    jsr popQ
    rts
.endproc
