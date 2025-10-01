.include "ast.inc"
.include "error.inc"
.include "asmlib.inc"
.include "astlib.inc"
.include "zeropage.inc"
.include "tokenizer.inc"
.include "4510macros.inc"

.export parseRecordType

.import getToken, parseFieldDeclarations, condGetToken

.proc parseRecordType
    jsr getToken

    lda #TYPE_RECORD
    jsr pushA               ; kind
    lda #0
    jsr pushA               ; isConst
    jsr pushQZero           ; subtype
    jsr pushQZero           ; params
    jsr typeCreate
    jsr pushQ
    jsr parseFieldDeclarations
    stq ptr2
    jsr popQ
    stq ptr1
    ldz #type::paramFields
    ldx #0
:   lda ptr2,x
    nop
    sta (ptr1),z
    inx
    inz
    cpx #4
    bne :-
    ldq ptr1
    jsr pushQ
    lda #tcEND
    ldx #errMissingEND
    jsr condGetToken
    jsr popQ
    rts
.endproc
