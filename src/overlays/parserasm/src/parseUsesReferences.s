.include "asmlib.inc"
.include "parser.inc"
.include "tokenizer.inc"
.include "zeropage.inc"
.include "error.inc"
.include "4510macros.inc"

.export parseUsesReferences

.import getToken, condGetToken, parserToken, doResync, addUnit, parserString
.import tlDeclarationFollow, tlDeclarationStart, tlStatementStart

firstDeclOffset = 4
lastDeclOffset = 0

.proc parseUsesReferences
    ; Loop to parse a list of units
L1: lda parserToken
    cmp #tcIdentifier
    bne L2
    ; Add the unit
    ldz #firstDeclOffset
    neg
    neg
    nop
    lda (stackPointer),z
    stq ptr1
    ldz #lastDeclOffset
    neg
    neg
    nop
    lda (stackPointer),z
    stq ptr2
    lda #<parserString
    ldx #>parserString
    jsr pushAX
    ldq ptr1
    jsr pushQ
    ldq ptr2
    jsr pushQ
    jsr addUnit
    stq ptr1
    ldz #lastDeclOffset
    ldx #0
:   lda ptr1,x
    nop
    sta (stackPointer),z
    inz
    inx
    cpx #4
    bne :-
    jsr getToken
    lda parserToken
    cmp #tcComma
    bne L1
    jsr getToken
    bra L1

L2: resync tlDeclarationFollow, tlDeclarationStart, tlStatementStart
    lda #tcSemicolon
    ldx #errMissingSemicolon
    jsr condGetToken

    ; Skip extra semicolons
L3: lda parserToken
    cmp #tcSemicolon
    bne L4
    jsr getToken
    bra L3

L4: jsr popQ
    stq ptr1
    jsr popQ
    ldq ptr1
    rts
.endproc
