.include "parser.inc"
.include "asmlib.inc"
.include "error.inc"
.include "tokenizer.inc"
.include "4510macros.inc"
.include "ast.inc"
.include "zeropage.inc"

.export parseModule

.import parseModuleHeader, parserToken, currentLineNumber, parserModuleType, getToken
.import parseBlock, condGetToken, parserValue, tokenIn, runtimeStackSize
.import tlHeaderFollow, tlDeclarationStart, tlStatementStart, tlProgramEnd
.import tlGlobalDirectives, doResync, isInUnitInterface, parserError

.bss

progDecl: .res 4

.code

.proc parseModule
    jsr parseModuleHeader
    stq progDecl

    ; Semicolon
    resync tlHeaderFollow, tlDeclarationStart, tlStatementStart
    lda parserToken
    cmp #tcSemicolon                ; if (parserToken == tcSemicolon)
    bne :+
    jsr getToken
    bra L1
:   lda #<tlDeclarationStart
    ldx #>tlDeclarationStart
    jsr tokenIn                     ; if (tokenIn(tlDeclarationStart))
    bne L1
    lda #<tlStatementStart
    ldx #>tlStatementStart
    jsr tokenIn                     ; if (tokenIn(tlStatementStart))
    bne L1
    lda #errMissingSemicolon
    jsr parserError

L1: lda parserModuleType
    cmp #TYPE_UNIT                  ; if (parserModuleType == TYPE_UNIT)
    bne L2
    lda #tcINTERFACE
    ldx #errMissingINTERFACE
    jsr condGetToken
    lda #1
    sta isInUnitInterface

    ; Look for compiler directives
L2: lda #<tlGlobalDirectives
    ldx #>tlGlobalDirectives
    jsr tokenIn                     ; if (tokenIn(tlGlobalDirectives))
    bne L3
    lda parserToken                 ; if (parserToken == tcSTACKSIZE)
    cmp #tcSTACKSIZE
    bne L2
    jsr getToken
    lda parserToken
    cmp #tcNumber                   ; if (parserToken != tcNumber)
    bne :+
    lda #errInvalidNumber
    jsr parserError
    bra L2
:   lda parserValue
    sta runtimeStackSize            ; runtimeStackSize = parserValue
    lda parserValue+1
    sta runtimeStackSize+1
    jsr getToken
    bra L2

    ; <block>
L3: lda #1
    jsr parseBlock
    stq ptr1
    ldq progDecl
    stq ptr2
    ldz #decl::code+3               ; decl.code = parseBlock()
    ldx #3
:   lda ptr1,x
    nop
    sta (ptr2),z
    dez
    dex
    bpl :-

    ; isLibrary
    jsr popA
    ldz #decl::isLibrary
    nop
    sta (ptr2),z

    lda parserModuleType
    cmp #TYPE_UNIT                  ; if (parserModuleType == TYPE_UNIT)
    bne :+
    lda #tcEND
    ldx #errMissingEND
    jsr condGetToken

    ; period
:   resync tlProgramEnd
    lda #tcPeriod
    ldx #errMissingPeriod
    jsr condGetToken

    ldq progDecl
    rts
.endproc
