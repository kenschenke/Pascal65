;
; parseModule.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Parse a program or unit module

.include "parser.inc"
.include "asmlib.inc"
.include "error.inc"
.include "tokenizer.inc"
.include "4510macros.inc"
.include "ast.inc"
.include "zeropage.inc"
.include "asm.inc"

.export parseModule

.import parseModuleHeader, parserToken, currentLineNumber, parserModuleType, getToken
.import parseBlock, condGetToken, parserValue, tokenIn, runtimeStackSize
.import runtimeMode, runtimeModeSeen
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
    beq :+
    lda #<tlStatementStart
    ldx #>tlStatementStart
    jsr tokenIn                     ; if (tokenIn(tlStatementStart))
    bne L1
:   lda #errMissingSemicolon
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
    beq :+
    jsr parseRuntimeDirective       ; $StaticRuntime or $DynamicRuntime
    bra L2
:   jsr getToken
    lda parserToken
    cmp #tcNumber                   ; if (parserToken != tcNumber)
    beq :+
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

; This routine handles the $StaticRuntime or $DynamicRuntime directive in
; parserToken and gets the next token. They choose how the program gets
; its runtime (runtimeMode), so they're allowed only in a program, and not
; both of them. Repeating one is harmless.
.proc parseRuntimeDirective
    ldx #RT_MODE_STATIC
    lda parserToken
    cmp #tcSTATICRUNTIME
    beq :+
    ldx #RT_MODE_DYNAMIC
:   lda parserModuleType
    cmp #TYPE_PROGRAM
    beq :+
    lda #errDirectiveProgramOnly    ; In a unit or a library
    bra ER
:   lda runtimeModeSeen
    beq ST
    cpx runtimeMode
    beq DN                          ; The same one again
    lda #errConflictingDirectives
ER: jsr parserError
    bra DN
ST: stx runtimeMode
    lda #1
    sta runtimeModeSeen
DN: jmp getToken
.endproc
