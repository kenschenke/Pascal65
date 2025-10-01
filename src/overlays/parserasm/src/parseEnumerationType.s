.include "ast.inc"
.include "error.inc"
.include "asmlib.inc"
.include "astlib.inc"
.include "parser.inc"
.include "zeropage.inc"
.include "tokenizer.inc"
.include "4510macros.inc"

.export parseEnumerationType

.import parserValue, getToken, doResync, parserString, parserToken
.import condGetToken, parserError
.import tlEnumConstStart, tlEnumConstFollow

.bss

firstEnum: .res 4
lastEnum: .res 4

.code

.proc parseEnumerationType
    ; Start the value at 0. It gets incremented during each iteration.
    lda #0
    tax
    tay
    taz
    stq parserValue
    stq firstEnum

    jsr getToken
    resync tlEnumConstStart

L1: lda parserToken
    cmp #tcIdentifier
    beq :+
    jmp L9

:   lda #EXPR_WORD_LITERAL
    jsr pushA
    jsr pushQZero
    jsr pushQZero
    jsr pushQZero
    jsr exprCreate
    jsr pushQ
    ; Create a declaration
    lda #<parserString
    ldx #>parserString
    jsr nameCreate
    stq ptr1
    jsr popQ
    stq ptr2
    lda #DECL_TYPE
    jsr pushA
    ldq ptr1
    jsr pushQ
    jsr pushQZero
    ldq ptr2
    jsr pushQ
    jsr declCreate
    stq ptr2
    ldq firstEnum
    jsr isQZero
    bne :+
    ; firstNum is null
    ldq ptr2
    stq firstEnum
    bra L2
:   ; firstEnum is not null
    ldq lastEnum
    stq ptr1
    ldz #decl::next
    ldx #0
:   lda ptr2,x
    nop
    sta (ptr1),z
    inz
    inx
    cpx #4
    bne :-
L2: ; comma
    jsr getToken
    resync tlEnumConstFollow
    lda parserToken
    cmp #tcComma
    beq L3
    cmp #tcIdentifier
    bne :+
    jmp L1
:   lda #errMissingComma
    jsr parserError
    jmp L1
L3: ; Saw comma. Skip extra commas and look for an identifier.
    jsr getToken
    resync tlEnumConstStart, tlEnumConstFollow
    lda parserToken
    cmp #tcComma
    bne :+
    lda #errMissingIdentifier
    jsr parserError
    bra L3
:   lda parserToken
    cmp #tcIdentifier
    bne :+
    lda #errMissingIdentifier
    jsr parserError

:   inc parserValue
    bne :+
    inc parserValue+1
:   jmp L1

    ; right paren
L9: lda #tcRParen
    ldx #errMissingRightParen
    jsr condGetToken

    ; Create the enumeration type
    lda #TYPE_ENUMERATION
    jsr pushA
    lda #0
    jsr pushA
    jsr pushQZero
    ldq firstEnum
    jsr pushQ
    jsr typeCreate
    jsr pushQ
    ; Create the expression for the maximum value
    lda #EXPR_WORD_LITERAL
    jsr pushQ
    jsr pushQZero
    jsr pushQZero
    jsr pushQZero
    jsr exprCreate
    stq ptr1
    jsr popQ
    sta ptr2
    ldz #type::max
    ldx #0
:   lda ptr2,x
    nop
    sta (ptr1),z
    inz
    inx
    cpx #4
    bne :-
    ldq ptr1
    rts
.endproc
