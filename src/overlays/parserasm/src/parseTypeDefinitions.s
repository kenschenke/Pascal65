;
; parseTypeDefinitions.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Parse the type definitions of a TYPE section

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
.import saveParserString, lastParserString, currentLineNumber

.bss

typeLine: .res 2

.code

.proc parseTypeDefinitions
    ; Loop to parse a list of type definitions
    ; separated by semicolons
L1: lda parserToken
    cmp #tcIdentifier
    beq :+
    jmp L2

    ; <id>
:   jsr saveParserString
    lda currentLineNumber
    sta typeLine
    lda currentLineNumber+1
    sta typeLine+1

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
    ; The declaration is on the line with the type's name
    ldz #decl::lineNumber
    lda typeLine
    nop
    sta (ptr2),z
    inz
    lda typeLine+1
    nop
    sta (ptr2),z
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
