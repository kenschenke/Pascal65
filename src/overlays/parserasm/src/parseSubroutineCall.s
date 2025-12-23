.include "ast.inc"
.include "asmlib.inc"
.include "zeropage.inc"
.include "tokenizer.inc"
.include "4510macros.inc"

isWriteWritelnOffset = 0
nameOffset = 1

.export parseSubroutineCall

.import parseActualParmList, parserToken

.proc parseSubroutineCall
    ldz #nameOffset
    neg
    neg
    nop
    lda (stackPointer),z
    stq ptr1

    lda #EXPR_NAME
    jsr pushA               ; kind
    jsr pushQZero           ; left
    jsr pushQZero           ; right
    ldq ptr1
    jsr pushQ               ; name
    jsr pushQZero           ; value
    jsr exprCreate
    jsr pushQ

    lda parserToken
    cmp #tcLParen
    bne L1
    ldz #isWriteWritelnOffset
    nop
    lda (stackPointer),z
    jsr parseActualParmList
    stq ptr2
    bra L2

    ; no parms
L1: lda #0
    tax
    tay
    taz
    stq ptr2

L2: jsr popQ
    stq ptr1
    lda #EXPR_CALL
    jsr pushA               ; kind
    ldq ptr1
    jsr pushQ               ; left
    ldq ptr2
    jsr pushQ               ; right
    jsr pushQZero           ; name
    jsr pushQZero           ; value
    jsr exprCreate
    stq ptr1

    jsr popA
    jsr popQ
    ldq ptr1
    rts
.endproc
