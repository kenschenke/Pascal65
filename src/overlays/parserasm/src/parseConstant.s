.include "ast.inc"
.include "asmlib.inc"
.include "tokenizer.inc"
.include "error.inc"
.include "zeropage.inc"
.include "4510macros.inc"

.export parseConstant

.import tokenIn, getToken, parserValue, parserString, parserToken, parserType
.import copyQuotedString, parserError
.import tlUnaryOps

.bss

sign: .res 1
type: .res 4
expr: .res 4
typePtr: .res 2
typeKind: .res 1
exprKind: .res 1

.code

.proc parseConstant
    sta typePtr
    stx typePtr+1
    lda #tcDummy
    sta sign

    lda #<tlUnaryOps
    ldx #>tlUnaryOps
    jsr tokenIn
    bne :+
    lda parserToken
    cmp #tcMinus
    lda #tcMinus
    sta sign
    jsr getToken

:   lda parserToken
    cmp #tcIdentifier
    bne :+
    jmp parseIdentifierConst
:   cmp #tcNumber
    bne :+
    jmp parseNumberConst
:   cmp #tcString
    bne :+
    jmp parseStringConst
:   cmp #tcTRUE
    bne :+
    jmp parseBooleanConst
:   cmp #tcFALSE
    bne :+
    jmp parseBooleanConst
:   cmp #tcNIL
    bne :+
    jmp parseNilConst
:   lda #errInvalidConstant
    jsr parserError
    jsr getToken
    lda #0
    tax
    tay
    taz
    rts
.endproc

; This routine stores the pointer in Q to the value
; pointed at by typePtr.
.proc setTypePtr
    stq ptr2
    lda typePtr
    sta ptr1
    lda typePtr+1
    sta ptr1+1
    ldx #0
    ldy #0
:   lda ptr2,x
    sta (ptr1),y
    inx
    iny
    cpx #4
    bne :-
    rts
.endproc

.proc parseIdentifierConst
    lda #TYPE_DECLARED
    jsr pushA
    lda #1
    jsr pushA
    jsr pushQZero
    jsr pushQZero
    jsr typeCreate
    stq type
    jsr setTypePtr
    lda #<parserString
    ldx #>parserString
    jsr nameCreate
    stq ptr1
    lda #EXPR_NAME
    jsr pushA
    jsr pushQZero
    jsr pushQZero
    ldq ptr1
    jsr pushQ
    lda #0
    tax
    tay
    taz
    stq parserValue
    jsr exprCreate
    stq expr
    lda #<parserString
    ldx #>parserString
    jsr nameCreate
    stq ptr3
    ldq type
    stq ptr1
    ldz #type::name
    ldx #0
:   lda ptr3,x
    nop
    sta (ptr1),z
    inz
    inx
    cpx #4
    bne :-
    jsr getToken
    ldq expr
    rts
.endproc

.proc parseNumberConst
    lda parserType
    cmp #tyByte
    bne :+
    lda #TYPE_BYTE
    sta typeKind
    lda #EXPR_BYTE_LITERAL
    sta exprKind
    bra L1
:   cmp #tyWord
    bne :+
    lda #TYPE_WORD
    sta typeKind
    lda #EXPR_WORD_LITERAL
    sta exprKind
    bra L1
:   cmp #tyReal
    bne :+
    lda #TYPE_REAL
    sta typeKind
    lda #EXPR_REAL_LITERAL
    sta exprKind
    bra L1
:   lda #TYPE_CARDINAL
    sta typeKind
    lda #EXPR_DWORD_LITERAL
    sta exprKind
L1: lda typeKind
    jsr pushA
    lda #1
    jsr pushA
    jsr pushQZero
    jsr pushQZero
    jsr typeCreate
    jsr setTypePtr
    lda parserType
    cmp #tyReal
    bne :+
    lda #<parserString
    ldx #>parserString
    jsr nameCreate
    stq parserValue
:   lda exprKind
    jsr pushA
    jsr pushQZero
    jsr pushQZero
    jsr pushQZero
    ldq parserValue
    jsr pushQ
    jsr exprCreate
    stq expr
    lda sign
    cmp #tcMinus
    bne :+
    ldq expr
    stq ptr1
    ldz #expr::neg
    lda #1
    nop
    sta (ptr1),z
:   jsr getToken
    ldq expr
    rts
.endproc

.proc parseNilConst
    lda #0
    tax
    tay
    taz
    stq parserValue
    lda #EXPR_WORD_LITERAL
    jsr pushA
    jsr pushQZero
    jsr pushQZero
    jsr pushQZero
    jsr exprCreate
    stq expr
    lda #TYPE_ADDRESS
    jsr pushA
    lda #1
    jsr pushA
    jsr pushQZero
    jsr pushQZero
    jsr typeCreate
    jsr setTypePtr
    jsr getToken
    ldq expr
    rts
.endproc

.proc parseBooleanConst
    lda #0
    tax
    tay
    taz
    stq parserValue
    lda parserToken
    cmp #tcTRUE
    beq :+
    lda #1
    sta parserValue
:   lda #EXPR_BOOLEAN_LITERAL
    jsr pushA
    jsr pushQZero
    jsr pushQZero
    jsr pushQZero
    jsr exprCreate
    stq expr
    lda #TYPE_BOOLEAN
    jsr pushA
    lda #1
    jsr pushA
    jsr pushQZero
    jsr pushQZero
    jsr typeCreate
    jsr setTypePtr
    jsr getToken
    ldq expr
    rts
.endproc

.proc parseStringConst
    lda sign
    cmp #tcDummy
    beq :+
    lda #errInvalidConstant
    jsr parserError
    ; Calculate the length of parserString (minus the quotes)
:   ldx #0
:   lda parserString,x
    beq :+
    inx
    bne :-
:   dex
    dex

    cpx #1
    bne L1
    ; Single character
    lda parserString+1
    sta parserValue
    lda #0
    sta parserValue+1
    sta parserValue+2
    sta parserValue+3
    lda #TYPE_CHARACTER
    jsr pushA
    lda #1
    jsr pushA
    jsr pushQZero
    jsr pushQZero
    jsr typeCreate
    jsr setTypePtr
    lda #EXPR_CHARACTER_LITERAL
    jsr pushA
    jsr pushQZero
    jsr pushQZero
    jsr pushQZero
    ldq parserValue
    jsr pushQ
    jsr exprCreate
    stq expr
    bra L2

L1: ; String
    jsr copyQuotedString
    lda #TYPE_STRING_VAR
    jsr pushA
    lda #1
    jsr pushA
    jsr pushQZero
    jsr pushQZero
    jsr typeCreate
    jsr setTypePtr
    lda #EXPR_STRING_LITERAL
    jsr pushA
    jsr pushQZero
    jsr pushQZero
    jsr pushQZero
    ldq parserValue
    jsr pushQ
    jsr exprCreate
    stq expr

L2: jsr getToken
    ldq expr
    rts
.endproc
