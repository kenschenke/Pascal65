.include "tokenizer.inc"
.include "error.inc"
.include "4510macros.inc"
.include "ast.inc"
.include "parser.inc"
.include "asmlib.inc"
.include "zeropage.inc"

.export parseModuleHeader

.import parserToken, currentLineNumber, getToken, condGetToken, isInUnitInterface
.import tlProgProcIdFollow, tlDeclarationStart, tlStatementStart
.import tlFormalParmsFollow, parserString, doResync, parserModuleType, parserError
.import saveParserString, lastParserString

.bss

paramList: .res 4
lastArg: .res 4

.code

.proc parseModuleHeader
    lda #0
    sta isInUnitInterface

    lda parserToken
    cmp #tcPROGRAM              ; if (parserToken == tcPROGRAM)
    bne :+
    lda #TYPE_PROGRAM
    sta parserModuleType        ; parserModuleType = TYPE_PROGRAM
    bra L1
:   cmp #tcUNIT                 ; else if (parserToken == tcUNIT)
    bne :+
    lda #TYPE_UNIT
    sta parserModuleType        ; parserModuleType = TYPE_UNIT
    bra L1
:   lda #errMissingPROGRAM
    jsr parserError

L1: ; Zero out lastArg and paramList
    lda #0
    ldx #3
:   sta lastArg,x
    sta paramList,x
    dex
    bpl :-
    jsr getToken

    lda parserToken
    cmp #tcIdentifier           ; if (parserToken != tcIdentifier)
    beq :+
    lda #errMissingIdentifier
    jsr parserError

:   jsr saveParserString

    ; ( or ;
    jsr getToken
    resync tlProgProcIdFollow, tlDeclarationStart, tlStatementStart

    ; Optional (file list)
    lda parserModuleType
    cmp #TYPE_PROGRAM           ; if (parserModuleType == TYPE_PROGRAM)
    bne L4
    lda parserToken             ; if (parserToken == tcLParen)
    cmp #tcLParen
    bne L4

    ; Parse the module parameters
L2: jsr getToken
    lda #<parserString
    ldx #>parserString
    jsr paramListCreate
    stq ptr2
    ; Is paramList null?
    lda paramList
    ora paramList+1
    ora paramList+2
    ora paramList+3
    bne :+
    ldq ptr2
    stq paramList
    stq lastArg
    bra L3
:   ldq lastArg
    stq ptr1
    ldz #param_list::next+3
    ldx #3
:   lda ptr2,x
    nop
    sta (ptr1),z
    dez
    dex
    bpl :-
    ldq ptr2
    stq lastArg

L3: jsr getToken
    lda parserToken
    cmp #tcComma                ; if (parserToken == tcComma)
    beq L2

    ; closing paren
    resync tlFormalParmsFollow, tlDeclarationStart, tlStatementStart
    lda #tcRParen
    ldx #errMissingRightParen
    jsr condGetToken

    ; Create the decl struct
L4: lda parserModuleType
    jsr pushA
    lda #0
    jsr pushA
    jsr pushQZero
    ldq paramList
    jsr pushQ
    jsr typeCreate
    stq ptr1

    lda #DECL_TYPE
    jsr pushA
    lda #<lastParserString
    ldx #>lastParserString
    ldy #0
    ldz #0
    jsr pushQ
    ldq ptr1
    jsr pushQ
    jsr pushQZero
    jmp declCreate
.endproc
