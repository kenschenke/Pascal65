.include "ast.inc"
.include "parser.inc"
.include "asmlib.inc"
.include "tokenizer.inc"
.include "error.inc"
.include "zeropage.inc"
.include "4510macros.inc"

; savedParserString must be the top item on the stack
savedParserStringOffset = 0
lastDeclOffset = savedParserStringOffset + NAMELEN
firstDeclOffset = lastDeclOffset + 4

.export parseTypeDefinitions

.import parserToken, parserString, getToken, condGetToken, parseTypeSpec, parserValue
.import appendDecl, tlDeclarationFollow, tlDeclarationStart, tlStatementStart, doResync
.import loadStackValue

.proc parseTypeDefinitions
    ; Reserve a block for the saved parser string
    lda #NAMELEN
    jsr pushBlock
    ; Loop to parse a list of type definitions
    ; separated by semicolons
L1: lda parserToken
    cmp #tcIdentifier
    beq :+
    jmp L2

    ; <id>
:   jsr fillSavedParserString

    ; =
    jsr getToken
    lda #tcEqual
    ldx #errMissingEqual
    jsr condGetToken

    ; <type>
    lda #0
    jsr parseTypeSpec
    stq ptr1
    ldq stackPointer
    stq ptr2
    lda #DECL_TYPE
    jsr pushA               ; kind
    ldq ptr2
    jsr pushQ               ; name
    ldq ptr1
    jsr pushQ               ; type
    jsr pushQZero           ; value
    jsr declCreate
    stq ptr2
    ldz #lastDeclOffset
    jsr loadStackValue
    stq ptr1
    ldz #firstDeclOffset
    jsr loadStackValue
    jsr pushQ
    ldq ptr1
    jsr pushQ
    jsr appendDecl
    jsr popQ
    stq ptr1                ; save appendDecl's lastDecl value
    jsr popQ
    ; Copy last decl
    ldz #lastDeclOffset
    ldx #0
:   lda ptr1,x
    nop
    sta (stackPointer),z
    inz
    inx
    cpx #4
    bne :-

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

L2: lda #NAMELEN
    jsr popBlock
    jsr popQ
    stq ptr1
    jsr popQ
    ldq ptr1
    rts
.endproc

; This routine copies parserString to the saved parser string on the stack.
.proc fillSavedParserString
    ldx #0
    ldz #savedParserStringOffset
L1: lda parserString,x
    beq L2
    nop
    sta (stackPointer),z
    inz
    inx
    bne L1
L2: nop
    sta (stackPointer),z
    rts
.endproc
