.include "ast.inc"
.include "parser.inc"
.include "asmlib.inc"
.include "astlib.inc"
.include "tokenizer.inc"
.include "error.inc"
.include "zeropage.inc"
.include "4510macros.inc"

firstDeclOffset = 4
lastDeclOffset = 0

.export parseTypeDefinitions

.import parserToken, parserString, getToken, condGetToken, parseTypeSpec, parserValue
.import appendDecl, tlDeclarationFollow, tlDeclarationStart, tlStatementStart, doResync

.bss

name: .res 4

.code

.proc parseTypeDefinitions
    ; Loop to parse a list of type definitions
    ; separated by semicolons
L1: lda parserToken
    cmp #tcIdentifier
    beq :+
    jmp L2

    ; <id>
:   lda #<parserString
    ldx #>parserString
    stq name

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
    jsr pushA
    ldq name
    jsr pushQ
    ldq ptr1
    jsr pushQ
    jsr pushQZero
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

L2: ldz #lastDeclOffset
    neg
    neg
    nop
    lda (stackPointer),z
    stq ptr1
    jsr popQ
    jsr popQ
    ldq ptr1
    rts
.endproc
