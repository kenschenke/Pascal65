;
; icodeStmts.s
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

.export icodeStmts

.import currentLineNumber, loadStackValue, icodeWriteInstruction, icodeOper1Word
.import icodeExpr, icodeIfStmt, icodeForLoop, icodeWhileStmt
.import icodeRepeatStmt, icodeCaseStmt

; This routine processes a chain of statements, passed in Q.
.proc icodeStmts
    jsr pushQ

    ; Loop through the statements
L1: ldz #stmtOffset
    jsr loadStackValue
    jsr isQZero
    bne :+
    jmp DN

:   stq ptr1
    ldz #stmt::lineNumber
    nop
    lda (ptr1),z
    sta currentLineNumber
    inz
    nop
    lda (ptr1),z
    sta currentLineNumber+1
    tax
    lda currentLineNumber
    jsr icodeOper1Word
    lda #IC_LIN
    jsr icodeWriteInstruction

    ldz #stmtOffset
    jsr loadStackValue
    stq ptr1
    ldz #stmt::kind
    nop
    lda (ptr1),z
    cmp #STMT_EXPR
    bne :+
    jsr stmtExpr
    jmp NX
:   cmp #STMT_IF_ELSE
    bne :+
    ldq ptr1
    jsr icodeIfStmt
    jmp NX
:   cmp #STMT_FOR
    bne :+
    ldq ptr1
    jsr icodeForLoop
    jmp NX
:   cmp #STMT_WHILE
    bne :+
    ldq ptr1
    jsr icodeWhileStmt
    jmp NX
:   cmp #STMT_REPEAT
    bne :+
    ldq ptr1
    jsr icodeRepeatStmt
    jmp NX
:   cmp #STMT_CASE
    bne NX
    ldq ptr1
    jsr icodeCaseStmt

NX: ldz #stmtOffset
    jsr loadStackValue
    stq ptr1
    ldz #stmt::next
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    ldx #0
    ldz #stmtOffset
:   lda ptr1,x
    nop
    sta (stackPointer),z
    inz
    inx
    cpx #4
    bne :-
    jmp L1

DN: jsr popQ
    rts
.endproc

.proc stmtExpr
    ldz #stmt::expr
    neg
    neg
    nop
    lda (ptr1),z
    jsr pushQ
    lda #0
    jsr pushA
    jsr icodeExpr
    rts
.endproc
