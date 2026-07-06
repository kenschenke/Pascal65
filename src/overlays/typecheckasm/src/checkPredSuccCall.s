;
; checkPredSuccCall.s
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

retnTypeOffset = 0
argOffset = retnTypeOffset + 4

.export checkPredSuccCall

.import loadStackValue, typeCheckError, isTypeInteger

.proc checkPredSuccCall
    ; Needs to have the first parameter
    ldz #argOffset
    jsr loadStackValue
    jsr isQZero
    bne :+
    lda #errWrongNumberOfParams
    jsr typeCheckError
    lda #TYPE_VOID
    jmp DN

    ; It can't have more than one parameter.
:   stq ptr1
    ldz #expr::right
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    beq :+
    lda #errWrongNumberOfParams
    jsr typeCheckError
    lda #TYPE_VOID
    jmp DN

    ; Look at the argument.
:   ldz #expr::left
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    ldz #expr::kind
    nop
    lda (ptr1),z
    cmp #EXPR_WORD_LITERAL
    bne :+
    lda #TYPE_INTEGER
    jmp DN
:   cmp #EXPR_CHARACTER_LITERAL
    bne :+
    lda #TYPE_CHARACTER
    jmp DN
:   cmp #EXPR_NAME
    beq :+
    lda #errInvalidType
    jsr typeCheckError
    lda #TYPE_VOID
    jmp DN
:   ldz #expr::name
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr4
    jsr scopeLookup
    jsr isQZero
    bne :+
    lda #errUndefinedIdentifier
    jsr typeCheckError
    lda #TYPE_VOID
    jmp DN
:   stq ptr1
    ldz #symbol::type
    neg
    neg
    nop
    lda (ptr1),z
    jsr getBaseType
    stq ptr1
    ldz #type::kind
    nop
    lda (ptr1),z
    cmp #TYPE_CHARACTER
    beq L1
    jsr isTypeInteger
    bne L2
L1: ldz #type::kind
    nop
    lda (ptr1),z
    jmp DN
L2: ldz #type::kind
    nop
    lda (ptr1),z
    cmp #TYPE_ENUMERATION
    beq L3
    cmp #TYPE_ENUMERATION_VALUE
    beq L3
    lda #errIncompatibleTypes
    jsr typeCheckError
    lda #TYPE_VOID
    jmp DN
L3: ldz #retnTypeOffset
    jsr loadStackValue
    stq ptr1
    ldz #type::kind
    lda #TYPE_ENUMERATION
    nop
    sta (ptr1),z
    ldz #type::flags
    lda #TYPE_FLAG_ISCONST
    nop
    sta (ptr1),z
    bra RT

DN: pha
    ldz #retnTypeOffset
    jsr loadStackValue
    stq ptr1
    ldz #type::kind
    pla
    nop
    sta (ptr1),z
RT: jsr popQ
    jsr popQ
    rts
.endproc
