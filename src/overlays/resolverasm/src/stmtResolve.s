;
; stmtResolve.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; stmtResolve routine

.include "ast.inc"
.include "asmlib.inc"
.include "zeropage.inc"
.include "4510macros.inc"

stmtOffset = 0
caseLabelOffset = 0
exprOffset = 0

.export stmtResolve

.import currentLineNumber, declResolve, exprResolve

; First stmt passed in Q
.proc stmtResolve
    jsr pushQ

    ; Loop through the statements
L1: ldz #stmtOffset
    neg
    neg
    nop
    lda (stackPointer),z
    jsr isQZero
    bne :+
    jmp L3

:   stq ptr1
    ldz #stmt::lineNumber
    nop
    lda (ptr1),z
    sta currentLineNumber
    inz
    nop
    lda (ptr1),z
    sta currentLineNumber+1

    ldz #stmt::kind
    nop
    lda (ptr1),z
    cmp #STMT_CASE_LABEL
    bne L2
    jsr resolveCaseLabel
    jsr restoreStmtPtr

L2: ldz #stmt::interfaceDecl
    neg
    neg
    nop
    lda (ptr1),z
    jsr pushQ
    jsr pushQZero
    jsr declResolve

    jsr restoreStmtPtr
    ldz #stmt::decl
    neg
    neg
    nop
    lda (ptr1),z
    jsr pushQ
    jsr pushQZero
    jsr declResolve

    jsr restoreStmtPtr
    ldz #stmt::expr
    neg
    neg
    nop
    lda (ptr1),z
    jsr pushQ
    jsr pushQZero
    lda #0
    jsr pushA
    jsr exprResolve

    jsr restoreStmtPtr
    ldz #stmt::init_expr
    neg
    neg
    nop
    lda (ptr1),z
    jsr pushQ
    jsr pushQZero
    lda #0
    jsr pushA
    jsr exprResolve

    jsr restoreStmtPtr
    ldz #stmt::to_expr
    neg
    neg
    nop
    lda (ptr1),z
    jsr pushQ
    jsr pushQZero
    lda #0
    jsr pushA
    jsr exprResolve

    jsr restoreStmtPtr
    ldz #stmt::body
    neg
    neg
    nop
    lda (ptr1),z
    jsr stmtResolve

    jsr restoreStmtPtr
    ldz #stmt::else_body
    neg
    neg
    nop
    lda (ptr1),z
    jsr stmtResolve

    jsr restoreStmtPtr
    ldz #stmt::next
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    ldz #stmtOffset
    ldx #0
:   lda ptr1,x
    nop
    sta (stackPointer),z
    inz
    inx
    cpx #4
    bne :-
    jmp L1

L3: jsr popQ
    rts
.endproc

.proc resolveCaseLabel
    ldz #stmt::body
    neg
    neg
    nop
    lda (ptr1),z                ; ptr1 still contains pointer to current stmt
    jsr pushQ

L1: ldz #caseLabelOffset
    neg
    neg
    nop
    lda (stackPointer),z
    jsr isQZero
    beq L2
    stq ptr1
    ldz #stmt::expr
    neg
    neg
    nop
    lda (ptr1),z
    jsr pushQ
    jsr pushQ
    lda #0
    jsr pushA
    jsr exprResolve
    jsr restoreStmtPtr
    ldz #stmt::body
    neg
    neg
    nop
    lda (ptr1),z
    jsr stmtResolve

    jsr restoreStmtPtr
    ldz #stmt::next
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    ldz #caseLabelOffset
    ldx #0
:   lda ptr1,x
    nop
    sta (stackPointer),z
    inz
    inx
    cpx #4
    bne :-
    bra L1

L2: jsr popQ
    jsr restoreStmtPtr
    ldz #stmt::expr
    neg
    neg
    nop
    lda (ptr1),z
    jsr pushQ

L3: ldz #exprOffset
    neg
    neg
    nop
    lda (stackPointer),z
    jsr isQZero
    beq L4
    jsr pushQ
    jsr pushQZero
    lda #0
    jsr pushA
    jsr exprResolve
    ldz #expr::right
    neg
    neg
    nop
    lda (stackPointer),z
    stq ptr1
    ldz #exprOffset
    ldx #0
:   lda ptr1,x
    nop
    sta (stackPointer),z
    inz
    inx
    cpx #4
    bne :-
    bra L3

L4: jsr popQ
    jsr restoreStmtPtr
    rts
.endproc

.proc restoreStmtPtr
    ldz #stmtOffset
    neg
    neg
    nop
    lda (stackPointer),z
    stq ptr1
    rts
.endproc
