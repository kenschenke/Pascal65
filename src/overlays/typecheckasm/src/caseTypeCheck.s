;
; caseTypeCheck.s
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
exprOffset = typeOffset + .sizeof(type)
labelExprOffset = exprOffset + 4
subtypeOffset = labelExprOffset + 4
exprKindOffset = subtypeOffset + 4

.export caseTypeCheck

.import loadStackValue, currentLineNumber, exprTypeCheck, typeCheckError
.import getTypeConversion, stmtTypeCheck

.proc caseTypeCheck
    lda #.sizeof(type)
    jsr pushBlock
    jsr pushQZero               ; store the current expression within each label

    ; Loop through the case labels
L1: ldz #labelExprOffset
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

    ldz #stmt::expr
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    ; Copy it on the expr spot on the stack
    ldz #exprOffset
    ldx #0
:   lda ptr1,x
    nop
    sta (stackPointer),z
    inz
    inx
    cpx #4
    bne :-

    ; Loop through the expressions for this label
L2: ldz #exprOffset
    jsr loadStackValue
    jsr isQZero
    bne :+
    bra NL
:   jsr checkExpr

    ; Move to the next expression
NE: ldz #exprOffset
    jsr loadStackValue
    stq ptr1
    ldz #expr::right
    neg
    neg
    nop
    lda (ptr1),z
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
    bra L2

    ; Type check the statements in the branch body
NL: ldz #labelExprOffset
    jsr loadStackValue
    stq ptr1
    ldz #stmt::body
    neg
    neg
    nop
    lda (ptr1),z
    jsr stmtTypeCheck

    ; Move to the next label
    ldz #labelExprOffset
    jsr loadStackValue
    stq ptr1
    ldz #stmt::next
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    ldz #labelExprOffset
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
    jsr popQ
    jsr popQ
    jsr popA
    rts
.endproc

.proc checkExpr
    ldz #exprOffset
    jsr loadStackValue
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

    ldz #type::flags
    nop
    lda (stackPointer),z
    and #TYPE_FLAG_ISCONST
    bne :+
    lda #errNotAConstantIdentifier
    jsr typeCheckError
:   ldz #exprKindOffset
    nop
    sta (stackPointer),z
    cmp #TYPE_ENUMERATION
    bne L3
    ldz #type::kind
    nop
    lda (stackPointer),z
    cmp #TYPE_ENUMERATION
    beq L1
    cmp #TYPE_ENUMERATION_VALUE
    bne L3
L1: ldz #type::subtype
    neg
    neg
    nop
    lda (stackPointer),z
    stq ptr1
    ldz #subtypeOffset
    jsr loadStackValue
    stq ptr2
    ldx #0
:   lda ptr1,x
    cmp ptr2,x
    bne L2
    inx
    cpx #4
    bne :-
    rts

L2: lda #errIncompatibleTypes
    jsr typeCheckError
    rts

L3: ldz #type::kind
    nop
    lda (stackPointer),z
    cmp #TYPE_CHARACTER
    bne L4
    ldz #exprKindOffset
    nop
    lda (stackPointer),z
    cmp #TYPE_CHARACTER
    bne L4
    rts

L4: ldz #type::kind
    nop
    lda (stackPointer),z
    sta tmp1
    ldz #exprKindOffset
    nop
    lda (stackPointer),z
    tax
    lda tmp1
    jsr getTypeConversion
    cmp #TYPE_VOID
    bne :+
    lda #errIncompatibleTypes
    jsr typeCheckError
:   rts
.endproc
