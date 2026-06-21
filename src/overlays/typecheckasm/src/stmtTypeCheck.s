;
; stmtTypeCheck.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

.include "ast.inc"
.include "error.inc"
.include "asmlib.inc"
.include "zeropage.inc"
.include "4510macros.inc"

typeOffset = 0
stmtOffset = typeOffset + .sizeof(type)

.export stmtTypeCheck

.import loadStackValue, currentLineNumber, exprTypeCheck
.import typeCheckError, isTypeInteger, caseTypeCheck, declTypeCheck

; stmt passed in Q
.proc stmtTypeCheck
    jsr pushQ
    lda #.sizeof(type)
    jsr pushBlock

    ; Loop through the stmts
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

    ldz #stmt::kind
    nop
    lda (ptr1),z
    cmp #STMT_EXPR
    bne :+
    jsr checkExpr
    jmp NX
:   cmp #STMT_IF_ELSE
    bne :+
    jsr checkIfElse
    jmp NX
:   cmp #STMT_FOR
    bne :+
    jsr checkFor
    jmp NX
:   cmp #STMT_WHILE
    bne :+
    jsr checkWhileRepeat
    jmp NX
:   cmp #STMT_REPEAT
    bne :+
    jsr checkWhileRepeat
    jmp NX
:   cmp #STMT_CASE
    bne :+
    jsr checkCase
    jmp NX
:   cmp #STMT_BLOCK
    bne NX
    jsr checkBlock

NX: ldz #stmtOffset
    jsr loadStackValue
    stq ptr1
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

DN: lda #.sizeof(type)
    jsr popBlock
    jsr popQ
    rts
.endproc

; This routine calls exprTypeCheck.
; The offset of the expression in the stmt is passed in Z.
; Ptr1 already contains stmt
.proc callExprTypeCheck
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    ldq stackPointer
    stq ptr2
    ldq ptr1
    jsr pushQ
    jsr pushQZero
    ldq ptr2
    jsr pushQ
    lda #0
    jsr pushA
    jsr exprTypeCheck
    rts
.endproc

.proc checkExpr
    ldz #stmt::expr
    jsr callExprTypeCheck
    rts
.endproc

.proc checkIfElse
    ldz #stmt::expr
    jsr callExprTypeCheck
    ldz #type::kind
    nop
    lda (stackPointer),z
    cmp #TYPE_BOOLEAN
    beq :+
    lda #errInvalidType
    jsr typeCheckError

:   ldz #stmtOffset
    jsr loadStackValue
    stq ptr1
    ldz #stmt::body
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    beq :+
    jsr stmtTypeCheck
    ldz #stmtOffset
    jsr loadStackValue
    stq ptr1
:   ldz #stmt::else_body
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    beq :+
    jsr stmtTypeCheck
:   rts
.endproc

.proc checkFor
    ldz #stmt::init_expr
    jsr callExprTypeCheck
    ldz #type::kind
    nop
    lda (stackPointer),z
    jsr isTypeInteger
    beq :+
    lda #errInvalidType
    jsr typeCheckError
:   ldz #stmtOffset
    jsr loadStackValue
    stq ptr1
    ldz #stmt::to_expr
    jsr callExprTypeCheck
    ldz #type::kind
    nop
    lda (stackPointer),z
    jsr isTypeInteger
    beq :+
    lda #errInvalidType
    jsr typeCheckError
:   ldz #stmtOffset
    jsr loadStackValue
    stq ptr1
    ldz #stmt::body
    neg
    neg
    nop
    lda (ptr1),z
    jsr stmtTypeCheck
    rts
.endproc

.proc checkWhileRepeat
    ldz #stmt::expr
    jsr callExprTypeCheck
    ldz #type::kind
    nop
    lda (stackPointer),z
    cmp #TYPE_BOOLEAN
    beq :+
    lda #errInvalidType
    jsr typeCheckError
:   ldz #stmtOffset
    jsr loadStackValue
    stq ptr1
    ldz #stmt::body
    neg
    neg
    nop
    lda (ptr1),z
    jsr stmtTypeCheck
    rts
.endproc

.proc checkCase
    ldz #stmt::expr
    jsr callExprTypeCheck
    ldz #type::kind
    nop
    lda (stackPointer),z
    jsr isTypeInteger
    beq :+
    ldq stackPointer
    jsr getBaseType
    stq ptr4
    ldz #type::kind
    nop
    lda (ptr4),z
    cmp #TYPE_CHARACTER
    beq :+
    cmp #TYPE_ENUMERATION
    beq :+
    lda #errIncompatibleTypes
    jsr typeCheckError
:   lda #type::kind
    nop
    lda (ptr4),z
    sta tmp1
    ldz #type::typeId
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    ldz #stmtOffset
    jsr loadStackValue
    stq ptr2
    ldz #stmt::body
    neg
    neg
    nop
    lda (ptr2),z
    stq ptr2
    lda tmp1
    jsr pushA
    ldq ptr1
    jsr pushQ
    ldq ptr2
    jsr pushQ
    jsr caseTypeCheck
    rts
.endproc

.proc checkBlock
    ldz #stmt::body
    neg
    neg
    nop
    lda (ptr1),z
    jsr stmtTypeCheck
    ldz #stmtOffset
    jsr loadStackValue
    stq ptr1
    ldz #stmt::decl
    neg
    neg
    nop
    lda (ptr1),z
    jsr declTypeCheck
    rts
.endproc
