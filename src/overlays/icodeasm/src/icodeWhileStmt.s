;
; icodeWhileStmt.s
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

.export icodeWhileStmt

.import icodeFormatLabel, icodeLabel, icodeOper1Label, icodeWriteInstruction
.import loadStackValue, icodeExprRead, icodeStmts

.data

lblWhile: .asciiz "while"
lblEndWhile: .asciiz "endwhile"

.code

.proc icodeWhileStmt
    stq ptr1
    stq intOp32
    jsr pushQ

    lda #<lblWhile
    ldx #>lblWhile
    jsr icodeFormatLabel
    jsr icodeOper1Label
    lda #IC_LOC
    jsr icodeWriteInstruction

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

    ldz #stmtOffset
    jsr loadStackValue
    stq intOp32
    lda #<lblEndWhile
    ldx #>lblEndWhile
    jsr icodeFormatLabel
    jsr icodeOper1Label
    lda #IC_BIF
    jsr icodeWriteInstruction

    ; Body of while loop
    ldz #stmtOffset
    jsr loadStackValue
    stq ptr1
    ldz #stmt::body
    neg
    neg
    nop
    lda (ptr1),z
    jsr icodeStmts

    ; Branch back to the start label
    ldz #stmtOffset
    jsr loadStackValue
    stq intOp32
    lda #<lblWhile
    ldx #>lblWhile
    jsr icodeFormatLabel
    jsr icodeOper1Label
    lda #IC_BRA
    jsr icodeWriteInstruction

    ; End of the while loop
    ldz #stmtOffset
    jsr loadStackValue
    stq intOp32
    lda #<lblEndWhile
    ldx #>lblEndWhile
    jsr icodeFormatLabel
    jsr icodeOper1Label
    lda #IC_LOC
    jsr icodeWriteInstruction

    jsr popQ
    rts
.endproc
