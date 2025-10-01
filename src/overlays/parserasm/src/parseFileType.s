.include "ast.inc"
.include "error.inc"
.include "asmlib.inc"
.include "astlib.inc"
.include "zeropage.inc"
.include "tokenizer.inc"
.include "4510macros.inc"

subtypeOffset = 0

.export parseFileType

.import getToken, parseTypeSpec, parserToken

.proc parseFileType
    jsr pushQZero           ; subtype

    ; OF
    jsr getToken
    lda parserToken
    cmp #tcOF
    bne L9

    jsr getToken
    lda #0
    jsr parseTypeSpec
    stq ptr1
    ldz #subtypeOffset
    ldx #0
:   lda ptr1,x
    nop
    sta (stackPointer),z
    inx
    inz
    cpx #4
    bne :-

    ldz #type::kind
    nop
    lda (ptr1),z
    cmp #TYPE_FILE
    beq L9
    cmp #TYPE_TEXT
    beq L9
    cmp #TYPE_STRING_VAR
    beq L9
    ldx #errIncompatibleTypes
    jsr compilerError

L9: jsr popQ
    stq ptr1
    lda #TYPE_FILE
    jsr pushA               ; kind
    lda #0
    jsr pushA               ; isConst
    ldq ptr1
    jsr pushQ               ; subtype
    jsr pushQZero           ; params
    jmp typeCreate
.endproc
