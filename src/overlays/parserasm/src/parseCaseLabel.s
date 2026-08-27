.include "ast.inc"
.include "asmlib.inc"
.include "error.inc"
.include "zeropage.inc"
.include "tokenizer.inc"
.include "4510macros.inc"

.export parseCaseLabel

.import tokenIn, getToken, parserToken, parseExpression, parserError
.import tlUnaryOps

.bss

signFlag: .res 1

.code

.proc parseCaseLabel
    lda #0
    sta signFlag

    ; Unary + or -
    lda #<tlUnaryOps
    ldx #>tlUnaryOps
    jsr tokenIn
    bne L1
    lda #1
    sta signFlag
    jsr getToken

L1: lda parserToken
    cmp #tcIdentifier
    bne L2
    lda signFlag
    beq L2
    lda #errInvalidConstant
    jsr parserError

L2: lda #0
    jsr parseExpression
    stq ptr1

    ldz #expr::kind
    nop
    lda (ptr1),z
    cmp #EXPR_BYTE_LITERAL
    bne L3
    lda signFlag
    beq L9
    ldz #expr::value
    nop
    lda (ptr1),z
    eor #$ff
    clc
    adc #1
    nop
    sta (ptr1),z
    bra L9

L3: cmp #EXPR_WORD_LITERAL
    bne L4
    lda signFlag
    beq L9
    ldz #expr::value
    nop
    lda (ptr1),z
    sta intOp1
    inz
    nop
    lda (intOp1),z
    sta intOp1+1
    jsr invertInt16
    ldz #expr::value
    lda intOp1
    nop
    sta (ptr1),z
    lda intOp1+1
    inz
    nop
    sta (ptr1),z
    bra L9

L4: cmp #EXPR_WORD_LITERAL
    bne L9
    lda signFlag
    beq L9
    ldz #expr::value
    ldx #0
:   nop
    lda (ptr1),z
    sta intOp32,x
    inz
    inx
    cpx #4
    bne :-
    jsr invertInt32
    ldz #expr::value
    ldx #0
:   lda intOp32,x
    nop
    sta (ptr1),z
    inz
    inx
    cpx #4
    bne :-

L9: ldq ptr1
    rts
.endproc
