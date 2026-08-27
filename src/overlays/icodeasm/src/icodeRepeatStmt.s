;
; icodeRepeatStmt.s
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

.export icodeRepeatStmt

.import loadStackValue, icodeFormatLabel, icodeLabel, icodeOper1Label
.import icodeWriteInstruction, icodeStmts, icodeExprRead

.data

lblRepeat: .asciiz "repeat"

.code

; Statement passed in Q
.proc icodeRepeatStmt
    stq intOp32
    jsr pushQ

    lda #<lblRepeat
    ldx #>lblRepeat
    jsr icodeFormatLabel

    jsr icodeOper1Label
    lda #IC_LOC
    jsr icodeWriteInstruction

    ldz #stmtOffset
    jsr loadStackValue
    stq ptr1
    ldz #stmt::body
    neg
    neg
    nop
    lda (ptr1),z
    jsr icodeStmts

    ; Evaluate the expression
    ldz #stmtOffset
    jsr loadStackValue
    stq ptr1
    ldz #stmt::expr
    neg
    neg
    nop
    lda (ptr1),z
    jsr icodeExprRead

    ; Branch if condition is false
    ldz #stmtOffset
    jsr loadStackValue
    stq intOp32
    lda #<lblRepeat
    ldx #>lblRepeat
    jsr icodeFormatLabel
    jsr icodeOper1Label
    lda #IC_BIF
    jsr icodeWriteInstruction

    jsr popQ
    rts
.endproc
