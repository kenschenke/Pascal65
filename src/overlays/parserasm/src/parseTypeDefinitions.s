.include "ast.inc"
.include "parser.inc"
.include "asmlib.inc"
.include "tokenizer.inc"
.include "error.inc"
.include "zeropage.inc"
.include "4510macros.inc"

.export parseTypeDefinitions

.import parserToken, parserString, getToken, condGetToken, parseTypeSpec, parserValue
.import appendDecl, tlDeclarationFollow, tlDeclarationStart, tlStatementStart, doResync
.import saveParserString, lastParserString

.proc parseTypeDefinitions
    ; Loop to parse a list of type definitions
    ; separated by semicolons
L1: lda parserToken
    cmp #tcIdentifier
    beq :+
    jmp L2

    ; <id>
:   jsr saveParserString

    ; =
    jsr getToken
    lda #tcEqual
    ldx #errMissingEqual
    jsr condGetToken

    ; <type>
    lda #0
    jsr parseTypeSpec
    stq ptr1
    lda #DECL_TYPE
    jsr pushA               ; kind
    lda #<lastParserString
    ldx #>lastParserString
    ldy #0
    ldz #0
    jsr pushQ               ; name
    ldq ptr1
    jsr pushQ               ; type
    jsr pushQZero           ; value
    jsr declCreate
    stq ptr2
    jsr appendDecl

    ; Semicolon
    resync tlDeclarationFollow, tlDeclarationStart, tlStatementStart
    lda #tcSemicolon
    ldx #errMissingSemicolon
    jsr condGetToken

    ; Skip extra semicolons
:   lda parserToken
    cmp #tcSemicolon
    bne :+
    jsr getToken
    bra :-

:   resync tlDeclarationFollow, tlDeclarationStart, tlStatementStart
    jmp L1

L2: jsr popQ
    stq ptr1
    jsr popQ
    ldq ptr1
    rts
.endproc
