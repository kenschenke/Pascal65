.include "ast.inc"
.include "asmlib.inc"
.include "parser.inc"
.include "error.inc"
.include "zeropage.inc"
.include "tokenizer.inc"
.include "4510macros.inc"

firstDeclOffset = 4
lastDeclOffset = 0

.export parseConstantDefinitions

.import parserToken, getToken, condGetToken, doResync, parseConstant, parserString
.import tlDeclarationFollow, tlDeclarationStart, tlStatementStart, appendDecl

.bss

name: .res 4
type: .res 4

.code

.proc parseConstantDefinitions
    ; Loop to parse a list of constant definitions
    ; separated by semicolons.

L1: lda parserToken
    cmp #tcIdentifier
    beq :+
    jmp L2
:   lda #<parserString
    ldx #>parserString
    jsr nameCreate
    stq name

    ; =
    jsr getToken
    lda #tcEqual
    ldx #errMissingEqual
    jsr condGetToken

    ; <constant>
    lda #<type
    ldx #>type
    jsr parseConstant
    stq ptr1
    lda #DECL_CONST
    jsr pushA               ; kind
    ldq name
    jsr pushQ               ; name
    ldq type
    jsr pushQ               ; type
    ldq ptr1
    jsr pushQ               ; value
    jsr declCreate
    stq ptr2
    ; Append the new declaration to the chain
    jsr appendDecl
    ; Set lastDecl to ptr2
    ldz #lastDeclOffset
    ldx #0
:   lda ptr2,x
    nop
    sta (stackPointer),z
    inz
    inx
    cpx #4
    bne :-

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
