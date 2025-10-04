.include "ast.inc"
.include "error.inc"
.include "asmlib.inc"
.include "zeropage.inc"
.include "tokenizer.inc"
.include "4510macros.inc"

lastArgOffset = 0
firstArgOffset = 4
isWriteWritennOffset = 8

.export parseActualParmList

.import getToken, parserToken, parseActualParm

.proc parseActualParmList
    jsr pushA               ; isWriteWriteln
    jsr pushQZero           ; firstArg
    jsr pushQZero           ; lastArg

L1: jsr getToken

    lda parserToken
    cmp #tcRParen
    beq L8

    ldz #isWriteWritennOffset
    nop
    lda (stackPointer),z
    jsr parseActualParm
    stq ptr1

    ldz #firstArgOffset
    neg
    neg
    nop
    lda (stackPointer),z
    jsr isQZero
    bne L2
    ; firstArg is null
    ldz #firstArgOffset
    ldx #0
:   lda ptr1,x
    nop
    sta (stackPointer),z
    inz
    inx
    cpx #4
    bne :-
    bra L3
L2: ; append new arg to lastArg
    ldz #lastArgOffset
    neg
    neg
    nop
    lda (stackPointer),z
    stq ptr2
    ldz #expr::right
    ldx #0
:   lda ptr1,x
    nop
    sta (ptr2),z
    inz
    inx
    cpx #4
    bne :-

    ; Set lastArg to new arg
L3: ldz #lastArgOffset
    ldx #0
:   lda ptr1,x
    nop
    sta (stackPointer),z
    inz
    inx
    cpx #4
    bne :-

    lda parserToken
    cmp #tcComma
    beq L1

L8: lda parserToken
    cmp #tcRParen
    beq :+
    lda #errMissingRightParen
    jsr compilerError
    bra L9
:   jsr getToken

L9: jsr popQ            ; lastArg
    jsr popQ            ; firstArg
    stq ptr1
    jsr popA            ; isWriteWriteln
    ldq ptr1
    rts
.endproc
