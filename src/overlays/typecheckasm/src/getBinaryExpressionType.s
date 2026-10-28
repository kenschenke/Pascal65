;
; getBinaryExpressionType.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

.include "ast.inc"
.include "asmlib.inc"
.include "zeropage.inc"
.include "4510macros.inc"

resultTypeOffset = 0
rightExprOffset = resultTypeOffset + 4
leftExprOffset = rightExprOffset + 4

.export getBinaryExpressionType

.import loadStackValue, getTypeConversion

.bss

literalSize: .res 1
declarationSize: .res 1

.code

; This routine returns the type of a binary expression based on the
; types of the two operands.
;
; The following rules are used to determine the expression type.
;    1) If at least operand is a real literal or real declaration, the result is real.
;    2) If both operands are literals or constants, the result is the next largest
;       size of the largest value. This is determined by getTypeConversion.
;    3) If one operand is a declaration and the other is a literal
;       or a constant, the resulting data type is that of the declaration.
;       If the declaration is smaller than the literal then the result of the
;       expression is made big enough to accommodate the literal.
;    4) If both operands are a declaration then the resulting data type is
;       the widest of the two declarations.
;          A) If both are signed or both are unsigned, the result matches the sign.
;          B) If one is signed and the other is unsigned, the result is signed.
;
;    A declaration is in the above rules can be a variable or a function return type.
;
; Parameters are passed on the runtime stack, bottom to top:
;    Left operand expression
;    Right operand expression
;    Pointer to the result type
.proc getBinaryExpressionType
    ; Rule #1 - left or right is real - result is real
    ldz #leftExprOffset
    jsr isExprReal
    beq Real
    ldz #rightExprOffset
    jsr isExprReal
    beq Real

    ; Rule #2 - left and right are both literals or constants
    ldz #leftExprOffset
    jsr isExprLiteral
    beq Rule3
    ldz #rightExprOffset
    jsr isExprLiteral
    beq Rule3
    ldz #leftExprOffset
    jsr loadStackValue
    stq ptr1
    ldz #expr::evalTypeKind
    nop
    lda (ptr1),z
    pha
    ldz #rightExprOffset
    jsr loadStackValue
    stq ptr1
    ldz #expr::evalTypeKind
    nop
    lda (ptr1),z
    tax
    pla
    jsr getTypeConversion
    pha
    jsr getExprSizeAndSign
    plx
    jsr setResultType
    bra DN

Rule3:
    ; Rule #3 - if one is a literal, type is other operand
    ldz #leftExprOffset
    jsr isExprLiteral
    bne LeftIsLiteral
    ldz #rightExprOffset
    jsr isExprLiteral
    bne RightIsLiteral

Rule4:
    ; Rule #4 - both operands are declarations - use the widest
    jsr handleRule4
    bra DN

Real:
    ; One of the operands is a real, which means the result is a real.
    lda #4
    ldx #TYPE_REAL
    jsr setResultType
    bra DN

LeftIsLiteral:
    ; The left operand is a literal, which means the result is
    ; the same type as the right declaration.
    ldz #rightExprOffset
    bra UseDeclarationType

RightIsLiteral:
    ; The right operand is a literal, which means the result is
    ; the same type as the left declaration.
    ldz #leftExprOffset
UseDeclarationType:
    jsr setExprKindAndSize
    ; This next routine checks if the expression needs to be bigger
    ; (the literal is bigger than the declaration).
    jsr checkExprSize
    ; Fall through to DN

DN: jsr popQ
    jsr popQ
    jsr popQ
    rts
.endproc

; This routine handles rule #3 as described above.
.proc handleRule4
    ldz #leftExprOffset
    jsr loadStackValue
    stq ptr1
    ldz #expr::evalTypeKind
    nop
    lda (ptr1),z
    jsr getExprSizeAndSign
    sta tmp1
    ldz #rightExprOffset
    jsr loadStackValue
    stq ptr1
    ldz #expr::evalTypeKind
    nop
    lda (ptr1),z
    jsr getExprSizeAndSign
    cmp tmp1
    bcc LeftIsBigger
    ldz #rightExprOffset
    jsr setExprKindAndSize
    bra CheckSigns
LeftIsBigger:
    ldz #leftExprOffset
    jsr setExprKindAndSize
CheckSigns:
    ldz #leftExprOffset
    jsr loadStackValue
    stq ptr1
    ldz #expr::evalTypeKind
    nop
    lda (ptr1),z
    jsr getExprSizeAndSign
    stx tmp1
    ldz #rightExprOffset
    jsr loadStackValue
    stq ptr1
    ldz #expr::evalTypeKind
    nop
    lda (ptr1),z
    jsr getExprSizeAndSign
    cpx tmp1
    bne SignsAreDifferent
    rts
SignsAreDifferent:
    ; The signs are different so the expression type is the signed
    ; variant of the largest size (currently set in result type).
    ldz #resultTypeOffset
    jsr loadStackValue
    stq ptr1
    ldz #type::kind
    nop
    lda (ptr1),z
    cmp #TYPE_SHORTINT
    beq DN
    cmp #TYPE_BYTE
    bne :+
    lda #TYPE_SHORTINT
    bra ChangeType
:   cmp #TYPE_INTEGER
    beq DN
    cmp #TYPE_WORD
    bne :+
    lda #TYPE_INTEGER
    bra ChangeType
:   cmp #TYPE_LONGINT
    beq DN
    lda #TYPE_LONGINT
    ; Fall through to ChangeType
ChangeType:
    ldz #type::kind
    nop
    sta (ptr1),z
DN: rts
.endproc

; This routine determines if an expression is a real declaration or real literal.
; Input:
;    Z - offset on stack of expression - leftExprOffset or rightExprOffset
; Output:
;    Z flag is set if the expression is real
.proc isExprReal
    jsr loadStackValue
    stq ptr1
    ldz #expr::evalTypeKind
    nop
    lda (ptr1),z
    cmp #TYPE_REAL
    rts
.endproc

; This routine determines if an expression is a constant or literal.
; Input:
;    Z - offset on stack of expression - leftExprOffset or rightExprOffset
; Output:
;    Z flag is cleared if the expression is a literal
.proc isExprLiteral
    jsr loadStackValue
    stq ptr1
    ldz #expr::evalTypeFlags
    nop
    lda (ptr1),z
    and #TYPE_FLAG_ISCONST
    rts
.endproc

; This routine returns the size of the expression's data type
; Inputs:
;    A - type kind
; Output:
;    A - size of data type
;    X - zero if unsigned, 1 if signed
.proc getExprSizeAndSign
    cmp #TYPE_BYTE
    bne :+
    lda #1
    ldx #0
    rts
:   cmp #TYPE_SHORTINT
    bne :+
    lda #1
    tax
    rts
:   cmp #TYPE_WORD
    bne :+
    lda #2
    ldx #0
    rts
:   cmp #TYPE_INTEGER
    bne :+
    lda #2
    ldx #1
    rts
:   cmp #TYPE_CARDINAL
    bne :+
    lda #4
    ldx #0
    rts
:   cmp #TYPE_LONGINT
    bne :+
    lda #4
    ldx #1
    rts
:   lda #0
    rts
.endproc

; This routine sets the expression's kind and size to the result type.
; Inputs:
;    Z - Offset of expression on the stack
.proc setExprKindAndSize
    jsr loadStackValue
    stq ptr1
    ldz #expr::evalTypeKind
    nop
    lda (ptr1),z
    tax
    ldz #expr::evalTypeSize
    nop
    lda (ptr1),z
    jsr setResultType
    rts
.endproc

; This routine stores the size and kind values in the result type.
;
; Inputs:
;    A - size
;    X - kind
.proc setResultType
    pha
    phx
    ldz #resultTypeOffset
    jsr loadStackValue
    stq ptr1
    pla
    ldz #type::kind
    nop
    sta (ptr1),z
    pla
    ldz #type::size
    nop
    sta (ptr1),z
    inz
    lda #0
    nop
    sta (ptr1),z
    rts
.endproc

; This routine is called when one side of the expression is a
; literal and the other is a declaration. It looks at the sizes
; of the literal and declaration. If the declaration is smaller
; than the literal then the result of the expression is made
; big enough to accomodate the literal.
.proc checkExprSize
    ldz #leftExprOffset
    jsr isExprLiteral
    bne LeftIsLiteral

    ; The right is literal
    ldz #rightExprOffset
    jsr setLiteralSize
    ldz #leftExprOffset
    jsr setDeclarationSize
    bra CompareSizes

LeftIsLiteral:
    ldz #leftExprOffset
    jsr setLiteralSize
    ldz #rightExprOffset
    jsr setDeclarationSize

CompareSizes:
    lda declarationSize
    cmp literalSize
    bcs DN
    ; The literal is bigger than the declaration.
    jsr upgradeDeclarationSize
DN: rts
.endproc

.proc setLiteralSize
    jsr loadStackValue
    stq ptr1
    ldz #expr::kind
    nop
    lda (ptr1),z
    cmp #EXPR_BYTE_LITERAL
    bne :+
    lda #1
    bra DN
:   cmp #EXPR_WORD_LITERAL
    bne :+
    lda #2
    bra DN
:   cmp #EXPR_DWORD_LITERAL
    bne :+
    lda #4
    bra DN
:   lda #0
DN: sta literalSize
    rts
.endproc

.proc setDeclarationSize
    jsr loadStackValue
    stq ptr1
    ldz #expr::evalTypeKind
    nop
    lda (ptr1),z
    cmp #TYPE_SHORTINT
    bne :+
    lda #1
    bra DN
:   cmp #TYPE_BYTE
    bne :+
    lda #1
    bra DN
:   cmp #TYPE_INTEGER
    bne :+
    lda #2
    bra DN
:   cmp #TYPE_WORD
    bne :+
    lda #2
    bra DN
:   cmp #TYPE_LONGINT
    bne :+
    lda #4
    bra DN
:   cmp #TYPE_CARDINAL
    bne :+
    lda #4
    bra DN
:   lda #0
DN: sta declarationSize
    rts
.endproc

.proc upgradeDeclarationSize
    ldz #resultTypeOffset
    jsr loadStackValue
    stq ptr1
    ldz #type::kind
    nop
    lda (ptr1),z
    cmp #TYPE_BYTE
    bne TypeShortInt
    lda literalSize
    cmp #2
    bne :+
    lda #TYPE_WORD
    ldx #2
    bra SetType
:   lda #TYPE_CARDINAL
    ldx #4
    bra SetType
TypeShortInt:
    cmp #TYPE_SHORTINT
    bne TypeWord
    lda literalSize
    cmp #2
    bne :+
    lda #TYPE_INTEGER
    ldx #2
    bra SetType
:   lda #TYPE_LONGINT
    ldx #4
    bra SetType
TypeWord:
    cmp #TYPE_WORD
    bne TypeInteger
    lda #TYPE_CARDINAL
    ldx #4
    bra SetType
TypeInteger:
    lda #TYPE_LONGINT
SetType:
    ldz #type::kind
    nop
    sta (ptr1),z
    ldz #type::size
    txa
    nop
    sta (ptr1),z
    rts
.endproc
