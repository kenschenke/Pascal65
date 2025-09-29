.include "ast.inc"
.include "error.inc"
.include "parser.inc"
.include "asmlib.inc"
.include "astlib.inc"
.include "zeropage.inc"
.include "tokenizer.inc"
.include "4510macros.inc"

.export parseIdSublist

.import parserToken, parserValue, doResync, getToken, parserString
.import tlIdentifierFollow, tlIdentifierStart

.bss

declKind: .res 1
firstId: .res 4
lastId: .res 4
newDecl: .res 4

.code

.proc parseIdSublist
    sta declKind

    lda #0
    tax
    tay
    taz
    stq firstId

    ; Loop to parse each identifier in the sublist
L1: lda parserToken
    cmp #tcIdentifier
    beq :+
    jmp L6

    ; Create a decl node
:   lda declKind
    jsr pushA               ; kind
    lda #<parserString
    ldx #>parserString
    jsr nameCreate
    jsr pushQ               ; name
    jsr pushQZero           ; type
    jsr pushQZero           ; value
    jsr declCreate
    stq newDecl

    ; Add the new declaration to the list
    ldq firstId
    jsr isQZero
    beq L2
    ldq lastId
    stq ptr1
    ldz #decl::next
    ldx #0
:   lda newDecl,x
    nop
    sta (ptr1),z
    inz
    inx
    cpx #4
    bne :-
    bra L3
L2: ; firstId is null
    ldq newDecl
    stq firstId
L3: ldq newDecl
    stq lastId

    ; comma
    jsr getToken
    resync tlIdentifierFollow
    lda parserToken
    cmp #tcComma
    beq L4
    cmp #tcIdentifier
    beq :+
    lda #errMissingComma
    jsr compilerError
:   jmp L1

L4: ; Saw comma
    ; Skip extra commas and look for an identifier
    jsr getToken
    resync tlIdentifierStart, tlIdentifierFollow
    lda parserToken
    cmp #tcComma
    bne L5
    lda #errMissingIdentifier
    jsr compilerError
L5: lda parserToken
    cmp #tcComma
    beq L4
    jmp L1

L6: ldq firstId
    rts
.endproc
