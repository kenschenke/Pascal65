;
; exprLiteral.s
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

typePtrOffset = 0
exprPtrOffset = typePtrOffset + 4

.export exprLiteral

.import loadStackValue

.bss

kind: .res 1

.code

.proc exprLiteral
    ldz #exprPtrOffset
    jsr loadStackValue
    stq ptr1
    ldz #expr::kind
    nop
    lda (ptr1),z
    cmp #EXPR_BOOLEAN_LITERAL
    bne :+
    lda #TYPE_BOOLEAN
    ldx #1
    jsr setTypeInfo
    jmp DN
:   cmp #EXPR_BYTE_LITERAL
    bne :+
    jsr setByteInfo
    jmp DN
:   cmp #EXPR_WORD_LITERAL
    bne :+
    jsr setWordInfo
    jmp DN
:   cmp #EXPR_DWORD_LITERAL
    bne :+
    jsr setDWordInfo
    jmp DN
:   cmp #EXPR_STRING_LITERAL
    bne :+
    lda #TYPE_STRING_LITERAL
    ldx #2
    jsr setTypeInfo
    jmp DN
:   cmp #EXPR_CHARACTER_LITERAL
    bne :+
    lda #TYPE_CHARACTER
    ldx #1
    jsr setTypeInfo
    jmp DN
:   cmp #EXPR_REAL_LITERAL
    bne DN
    lda #TYPE_REAL
    ldx #4
    jsr setTypeInfo

DN: jsr popQ
    jsr popQ
    rts
.endproc

; This routine sets the kind, flags, and size in the type field
; for the expression.
; The kind is passed in A and the size in X.
.proc setTypeInfo
    phx
    pha
    ldz #typePtrOffset
    jsr loadStackValue
    stq ptr1
    ldz #type::kind
    pla
    nop
    sta (ptr1),z
    ldz #type::flags
    lda #TYPE_FLAG_ISCONST
    nop
    sta (ptr1),z
    ldz #type::size
    pla
    nop
    sta (ptr1),z
    inz
    lda #0
    nop
    sta (ptr1),z
    rts
.endproc

; This routine sets the type fields for a byte literal.
; It expects the expression is still in ptr1.
.proc setByteInfo
    ldz #expr::neg
    nop
    lda (ptr1),z
    bne L1
    ldz #expr::value
    nop
    lda (ptr1),z
    bpl L1
    lda #TYPE_BYTE
    bra L2

L1: lda #TYPE_SHORTINT
L2: sta kind
    ldz #expr::neg
    nop
    lda (ptr1),z
    beq L3
    ldz #expr::value
    nop
    lda (ptr1),z
    bpl L3
    lda #EXPR_WORD_LITERAL
    ldz #expr::kind
    nop
    sta (ptr1),z
    lda #TYPE_INTEGER
    sta kind
    ldx #2
    bra L4

L3: ldx #1
L4: lda kind
    jmp setTypeInfo
.endproc

; This routine sets the type fields for the word literal.
; It expects the expression is still in ptr1
.proc setWordInfo
    ldz #expr::neg
    nop
    lda (ptr1),z
    bne L1
    ldz #expr::value+1
    nop
    lda (ptr1),z
    bpl L1
    lda #TYPE_WORD
    bra L2

L1: lda #TYPE_INTEGER
L2: sta kind
    ldz #expr::neg
    nop
    lda (ptr1),z
    beq L3
    ldz #expr::value+1
    nop
    lda (ptr1),z
    bpl L3
    lda #EXPR_DWORD_LITERAL
    ldz #expr::kind
    nop
    sta (ptr1),z
    lda #TYPE_LONGINT
    sta kind
    ldx #4
    bra L4

L3: ldx #2
L4: lda kind
    jmp setTypeInfo
.endproc

; This routine sets the type fields for the double-word literal.
; It expects the expression is still in ptr1
.proc setDWordInfo
    ldz #expr::neg
    nop
    lda (ptr1),z
    bne L1
    ldz #expr::value+3
    nop
    lda (ptr1),z
    bpl L1
    lda #TYPE_CARDINAL
    bra L2

L1: lda #TYPE_LONGINT
L2: ldx #4
    jmp setTypeInfo
.endproc
