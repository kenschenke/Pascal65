.include "ast.inc"
.include "error.inc"
.include "asmlib.inc"
.include "astlib.inc"
.include "zeropage.inc"
.include "tokenizer.inc"
.include "4510macros.inc"

nameOffset = 2
limitOffset = 0

.export parseSubrangeLimit

.import tlUnaryOps, parserToken, getToken, tokenIn, parserString, parserType, parserValue

.bss

sign: .res 1
limitType: .res 1
value: .res 4
exprKind: .res 1

.code

; This routine parses a subrange limit.
; Inputs are on runtime stack, bottom to top:
;    name - 4 bytes
;    limit pointer - 2 bytes
.proc parseSubrangeLimit
    lda #tcDummy
    sta sign
    
    ldz #nameOffset
    neg
    neg
    nop
    lda (stackPointer),z
    jsr isQZero
    beq L1
    lda #<parserString
    ldx #>parserString
    jsr nameCreate
    stq ptr1
    lda #EXPR_NAME
    jsr pushA               ; kind
    jsr pushQZero           ; left
    jsr pushQZero           ; right
    ldq ptr1
    jsr pushQ               ; name
    jsr pushQZero           ; value
    jsr exprCreate
    stq ptr1
    jsr storeLimit
    lda #TYPE_DECLARED
    sta limitType
    jmp L4

    ; Unary + or -
L1: lda #<tlUnaryOps
    ldx #>tlUnaryOps
    jsr tokenIn
    bne L2
    lda parserToken
    cmp #tcMinus
    bne :+
    sta sign
:   jsr getToken

L2: lda parserToken
    cmp #tcNumber
    bne :+
    jsr parseNumberLimit
    bra L3
:   cmp #tcString
    bne :+
    jsr parseStringLimit
    bra L3
:   cmp #tcIdentifier
    bne :+
    jsr parseIdentifierLimit
    bra L3
:   lda #errMissingConstant
    jsr compilerError

L3: jsr getToken

L4: jsr popQ
    jsr popAX
    lda limitType
    rts
.endproc

; This routine stores the limit expression in ptr1
; to the limit memory supplied by the caller.
.proc storeLimit
    ldz #limitOffset
    nop
    lda (stackPointer),z
    sta ptr2
    inz
    nop
    lda (stackPointer),z
    sta ptr2+1
    ldy #0
:   lda ptr1,y
    sta (ptr2),y
    iny
    cpy #4
    bne :-
    rts
.endproc

.proc parseNumberLimit
    ldq parserValue
    stq value

    lda parserType
    cmp #tyByte
    bne L1
    lda #EXPR_BYTE_LITERAL
    sta exprKind
    lda #TYPE_BYTE
    sta limitType
    jmp L7
L1: cmp #tyShortInt
    bne L2
    lda sign
    cmp #tcMinus
    bne :+
    ; Invert the 8-bit value using two's complement
    lda value
    eor #$ff
    clc
    adc #1
    sta value
:   lda #EXPR_BYTE_LITERAL
    sta exprKind
    lda #TYPE_SHORTINT
    sta limitType
    jmp L7
L2: cmp #tyWord
    bne L3
    lda #EXPR_WORD_LITERAL
    sta exprKind
    lda #TYPE_WORD
    sta limitType
    jmp L7
L3: cmp #tyInteger
    bne L4
    lda sign
    cmp #tcMinus
    bne :+
    lda value
    sta intOp1
    lda value+1
    sta intOp1+1
    jsr invertInt16
    lda intOp1
    sta value
    lda intOp1+1
    sta value+1
    lda #EXPR_WORD_LITERAL
    sta exprKind
    lda #TYPE_INTEGER
    sta limitType
    jmp L7
L4: cmp #tyCardinal
    bne L5
    lda #EXPR_DWORD_LITERAL
    sta exprKind
    lda #TYPE_CARDINAL
    sta limitType
    jmp L7
L5: cmp #tyLongInt
    bne L6
    lda sign
    cmp #tcMinus
    bne :+
    ldq value
    stq intOp32
    jsr invertInt32
    ldq intOp32
    stq value
:   lda #EXPR_DWORD_LITERAL
    sta exprKind
    lda #TYPE_CARDINAL
    sta limitType
    jmp L7
L6: lda #errInvalidSubrangeType
    jsr compilerError
    lda #EXPR_DWORD_LITERAL
    sta exprKind
    lda #TYPE_VOID
    sta limitType
L7: lda exprKind
    jsr pushA           ; kind
    jsr pushQZero       ; left
    jsr pushQZero       ; right
    jsr pushQZero       ; name
    ldq value
    jsr pushQ           ; value
    jsr exprCreate
    stq ptr1
    jsr storeLimit
    lda sign
    cmp #tcMinus
    bne :+
    ldz #expr::neg
    lda #1
    nop
    sta (ptr1),z
:   rts
.endproc

.proc parseStringLimit
    lda sign
    cmp #tcDummy
    beq L1
    lda #errInvalidConstant
    jsr compilerError

L1: ldx #0
:   lda parserString,x
    beq :+
    inx
    bne :-
:   cpx #3
    beq :+
    ; length includes quotes
    lda #errInvalidSubrangeType
    jsr compilerError
:   lda #TYPE_CHARACTER
    sta limitType
    lda #EXPR_CHARACTER_LITERAL
    jsr pushA               ; kind
    lda parserString+1
    sta value
    jsr pushQZero           ; left
    jsr pushQZero           ; right
    jsr pushQZero           ; name
    ldq value
    jsr pushQ               ; value
    jsr exprCreate
    stq ptr1
    jsr storeLimit
    rts
.endproc

.proc parseIdentifierLimit
    lda #<parserString
    ldx #>parserString
    jsr nameCreate
    stq ptr1
    lda #EXPR_NAME
    jsr pushA               ; kind
    jsr pushQZero           ; left
    jsr pushQZero           ; right
    ldq ptr1
    jsr pushQ               ; name
    jsr pushQZero           ; value
    jsr exprCreate
    stq ptr1
    jsr storeLimit
    rts
.endproc
