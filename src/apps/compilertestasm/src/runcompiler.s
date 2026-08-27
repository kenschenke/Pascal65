;
; runcompiler.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; runCompiler routine

.include "zeropage.inc"
.include "cbm_kernal.inc"
.include "tokenizer.inc"
.include "linker.inc"
.include "codegen.inc"
.include "asmlib.inc"
.include "parser.inc"
.include "typecheck.inc"
.include "icode.inc"
.include "resolver.inc"
.include "4510macros.inc"

.export runCompiler, unitList

.import initTokenizer, initParser, initResolver, initTypeCheck, errorCount
.import initIcode, initCodeGen, initLinker, freeUnits, tokenizeAndParseUnits
.import nextTestPrg

.bss

sourceFn: .res 2
tokens: .res 4
astRoot: .res 4
unitList: .res 4
runtimeStackSize: .res 2

.code

; This routine loads the compiler modules, one by one, and runs them.
; The null-terminated filename is passed in A/X.
.proc runCompiler
    sta sourceFn
    sta ptr1
    stx sourceFn+1
    stx ptr1+1

    ; Print the filename
    ldy #0
:   lda (ptr1),y
    beq :+
    jsr CHROUT
    iny
    bne :-
    ; Print three spaces
:   lda #' '
    jsr CHROUT
    jsr CHROUT
    jsr CHROUT

    ; Tokenize the source file
    lda #'T'
    jsr CHROUT
    jsr initTokenizer
    lda sourceFn
    ldx sourceFn+1
    jsr tokenize
    stq tokens

    ; Clear the unit list
    lda #0
    tax
    tay
    taz
    stq unitList
    
    ; Parse the tokens
    lda #'P'
    jsr CHROUT
    jsr initParser
    ldq unitList
    jsr setParserUnitsList
    ldq tokens
    jsr parse
    stq astRoot
    jsr getParserUnitsList
    stq unitList
    jsr getParserStackSize
    sta runtimeStackSize
    stx runtimeStackSize+1

    ; Check the error count
    lda errorCount
    beq :+

    ; Error - so don't continue
    rts

    ; Free the tokens
:   ldq tokens
    jsr freeMemBuf

    ; Reset error count
    lda #0
    sta errorCount

    jsr tokenizeAndParseUnits

    lda #'R'
    jsr CHROUT
    jsr initResolver
    ldq unitList
    jsr setResolverUnitsList
    jsr initScopeStack
    jsr initStandardRoutines
    jsr injectSystemUnit
    jsr resolveUnits

    ldq astRoot

    jsr pushQ
    jsr pushQZero
    jsr declResolve

    ldq astRoot
    jsr pushQ
    lda #0
    tax
    jsr pushAX
    lda #0
    jsr pushA
    jsr setDeclOffsets
    jsr setUnitOffsets
    ldq astRoot
    jsr fixGlobalOffsets
    ldq astRoot
    jsr verifyFwdDeclarations
    jsr getResolverUnitsList
    stq unitList

    ; Check the error count
    lda errorCount
    beq :+

    ; Error - so don't continue
    rts

    ; Reset the error count
:   lda #0
    sta errorCount

    lda #'K'
    jsr CHROUT
    jsr initTypeCheck
    ldq astRoot
    jsr declTypeCheck
    ldq unitList
    jsr typeCheckUnits

    ; Generate the intermediate code
    lda #'I'
    jsr CHROUT
    jsr initIcode
    ldq unitList
    jsr setIcodeUnitsList
    ldq astRoot
    jsr icodeWrite

    ; Free the PROGRAM scope symbol table
    jsr scopeExit
    jsr freeSymtab

    ; Check the error count
    lda errorCount
    beq :+

    ; Error - so don't continue
    rts

:   lda #'G'
    jsr CHROUT
    jsr initCodeGen
    ldq unitList
    jsr setCodeGenUnitList
    lda runtimeStackSize
    ldx runtimeStackSize+1
    jsr setCodeGenStackSize
    lda nextTestPrg
    beq L1
    lda #<nextTestPrg
    ldx #>nextTestPrg
    ldy #0
    bra L2
L1: lda #0
    tax
    tay
L2: jsr setCodeGenProgramChain
    ldq astRoot
    jsr objCodeGen

    ldq astRoot
    jsr astFree

    jsr freeUnits

    lda #'L'
    jsr CHROUT
    jsr initLinker
    lda sourceFn
    ldx sourceFn+1
    jsr genPrgFile
    jsr freeLinkerTags

    lda #13
    jsr CHROUT
    
    rts
.endproc
