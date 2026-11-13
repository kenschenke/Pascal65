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

.bss

forKind: .res 1             ; kind of a For loop's control variable
caseKind: .res 1            ; kind of a Case selector's base type
caseFields: .res 4          ; its enumeration's values, or zero

.code

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

; The control variable of a For loop can be an integer, a Char or an
; enumeration, including subranges of them. The final value must be of
; the same kind. The kinds come from the evalTypeKind of the expressions,
; which is the kind of the base type. The kind of the initial assignment
; isn't used because an enumeration assignment has no result type.
.proc checkFor
    ldz #stmt::init_expr
    jsr callExprTypeCheck
    ldz #stmtOffset
    jsr loadStackValue
    stq ptr1
    ldz #stmt::init_expr
    jsr loadExprPtr
    stq ptr1
    ldz #expr::left         ; the control variable
    jsr loadExprPtr
    jsr getForKind
    sta forKind
    bne :+
    lda #errInvalidType
    jsr typeCheckError
:   ldz #stmtOffset
    jsr loadStackValue
    stq ptr1
    ldz #stmt::to_expr
    jsr callExprTypeCheck
    ldz #stmtOffset
    jsr loadStackValue
    stq ptr1
    ldz #stmt::to_expr
    jsr loadExprPtr
    jsr getForKind
    ldx forKind
    beq :++                 ; the control variable was already reported
    tax
    bne :+
    lda #errInvalidType
    jsr typeCheckError
    bra :++
:   cmp forKind
    beq :+
    lda #errIncompatibleTypes
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

; Loads the pointer at offset Z of ptr1 into Q
.proc loadExprPtr
    neg
    neg
    nop
    lda (ptr1),z
    rts
.endproc

; Classifies the expression in Q for a For loop. Returns TYPE_INTEGER for
; any integer type, TYPE_CHARACTER or TYPE_ENUMERATION, or zero if the
; type can't control a For loop. The flags are set from A.
.proc getForKind
    stq ptr4
    ldz #expr::evalTypeKind
    nop
    lda (ptr4),z
    jsr isTypeInteger
    bne :+
    lda #TYPE_INTEGER
    rts
:   cmp #TYPE_CHARACTER
    beq L1
    cmp #TYPE_ENUMERATION
    beq L1
    cmp #TYPE_ENUMERATION_VALUE
    bne :+
    lda #TYPE_ENUMERATION
    bra L1
:   lda #0
L1: ora #0                  ; set the flags from A for the caller
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

; The selector of a Case statement is an integer, a Char or an enumeration,
; including subranges of them. caseTypeCheck gets the kind of its base type
; and, for an enumeration, the enumeration's values (the paramFields of the
; base type's subtype), which every label must be one of.
.proc checkCase
    ldz #stmt::expr
    jsr callExprTypeCheck
    lda #0
    ldx #3
:   sta caseFields,x
    dex
    bpl :-
    ldq stackPointer
    jsr getBaseType
    stq ptr4
    ldz #type::kind
    nop
    lda (ptr4),z
    sta caseKind
    jsr isTypeInteger
    beq L2
    lda caseKind
    cmp #TYPE_CHARACTER
    beq L2
    cmp #TYPE_ENUMERATION
    beq L1
    cmp #TYPE_ENUMERATION_VALUE
    beq L1
    lda #errIncompatibleTypes
    jsr typeCheckError
    bra L2
L1: lda #TYPE_ENUMERATION
    sta caseKind
    ldz #type::subtype
    neg
    neg
    nop
    lda (ptr4),z
    stq ptr1
    ldz #type::paramFields
    neg
    neg
    nop
    lda (ptr1),z
    stq caseFields
L2: ldz #stmtOffset
    jsr loadStackValue
    stq ptr2
    ldz #stmt::body
    neg
    neg
    nop
    lda (ptr2),z
    stq ptr2
    lda caseKind
    jsr pushA
    ldq caseFields
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
