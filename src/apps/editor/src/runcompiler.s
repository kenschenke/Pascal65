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
.include "editoroverlay.inc"
.include "4510macros.inc"

.export runCompiler, unitList

.import initTokenizer, initParser, initResolver, initTypeCheck
.import initBuildResult, finishBuildResult, buildHasErrors
.import initIcode, initCodeGen, initLinker, freeUnits, tokenizeAndParseUnits

.bss

globalSlots: .res 2

loopCode: .res 1
sourceFn: .res 17
tokens: .res 4
astRoot: .res 4
unitList: .res 4
runtimeStackSize: .res 2
runtimeMode: .res 1             ; RT_MODE_* (asm.inc)

.data

compilingMsg: .asciiz "Compiling "
strTokenizing: .asciiz "Tokenizing"
strParsing: .asciiz "Parsing"
strResolving: .asciiz "Resolving"
strTypeChecking: .asciiz "Type Checking"
strIcode: .asciiz "Intermediate Code"
strCodeGen: .asciiz "Generating Object Code"
strLinking: .asciiz "Linking"
strRunFn: .asciiz "zzprg"
strEditorFn: .asciiz "pascal65"

.code

; This routine loads the compiler modules, one by one, and runs them.
; A contains either EDITOR_LOOP_COMPILE or EDITOR_LOOP_RUN.
; The null-terminated filename is passed in X/Y.
.proc runCompiler
    sta loopCode
    ; Copy the source filename into sourceFn
    stx ptr1
    sty ptr1+1
    ldy #0
:   lda (ptr1),y
    sta sourceFn,y
    beq :+
    iny
    bne :-
    ; Clear the screen and home the cursor
:   lda #147
    jsr CHROUT
    ; Print a couple CRs
    lda #13
    jsr CHROUT
    jsr CHROUT
    ; Print the compiling message
    ldx #0
:   lda compilingMsg,x
    beq :+
    jsr CHROUT
    inx
    bne :-
:   ; Print the filename
    ldx #0
:   lda sourceFn,x
    beq :+
    jsr CHROUT
    inx
    bne :-
:   lda #13
    jsr CHROUT

    ; Forget the last build. logError and logWarning record this one's
    ; errors and warnings.
    jsr initBuildResult

    ; Tokenize the source file
    lda #<strTokenizing
    ldx #>strTokenizing
    jsr printLine
    jsr initTokenizer
    lda #<sourceFn
    ldx #>sourceFn
    jsr tokenize
    stq tokens

    jsr isQZero
    bne :+
    jmp DN

    ; Clear the unit list
:   lda #0
    tax
    tay
    taz
    stq unitList
    
    ; Parse the tokens
    lda #<strParsing
    ldx #>strParsing
    jsr printLine
    jsr initParser
    jsr parserInit
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
    jsr getParserRuntimeMode
    sta runtimeMode

    ; Free the tokens
    ldq tokens
    jsr freeMemBuf

    ; Check the error count
    jsr buildHasErrors
    beq :+

    ; Error - so don't continue
    ldq astRoot
    jsr astFree
    jmp DN

:   jsr tokenizeAndParseUnits

    ; Check the error count
    jsr buildHasErrors
    beq :+
    ldq astRoot
    jsr astFree
    jmp DN

:   lda #<strResolving
    ldx #>strResolving
    jsr printLine
    jsr initResolver
    ldq unitList
    jsr setResolverUnitsList
    jsr initScopeStack
    jsr initStandardRoutines
    jsr injectSystemUnit
    jsr resolveUnits

    ; resolveUnits reports errors in each unit's file. The rest are in
    ; the program's.
    lda #<sourceFn
    ldx #>sourceFn
    jsr setCompilerFilename

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
    ; The program's own level 1 slots, for the icode header
    sta globalSlots
    stx globalSlots+1
    jsr setUnitOffsets
    ldq astRoot
    jsr fixGlobalOffsets
    ldq astRoot
    jsr verifyFwdDeclarations
    jsr getResolverUnitsList
    stq unitList

    ; Check the error count
    jsr buildHasErrors
    beq :+

    ; Error - so don't continue
    ldq astRoot
    jsr astFree
    jsr scopeExit
    jsr freeSymtab
    jsr freeUnits
    jmp DN

:   lda #<strTypeChecking
    ldx #>strTypeChecking
    jsr printLine
    jsr initTypeCheck
    ldq astRoot
    jsr declTypeCheck
    ldq unitList
    jsr typeCheckUnits
    lda #<sourceFn
    ldx #>sourceFn
    jsr setCompilerFilename

    ; Generate the intermediate code
    lda #<strIcode
    ldx #>strIcode
    jsr printLine
    jsr initIcode
    ldq unitList
    jsr setIcodeUnitsList
    lda runtimeStackSize
    ldx runtimeStackSize+1
    jsr setIcodeStackSize
    lda globalSlots
    ldx globalSlots+1
    jsr setIcodeGlobalSlots
    lda runtimeMode
    jsr setIcodeRuntimeMode
    ldq astRoot
    jsr icodeWrite

    ; Free the PROGRAM scope symbol table
    jsr scopeExit
    jsr freeSymtab

    ; Check the error count
    jsr buildHasErrors
    beq :+

    ; Error - so don't continue
    ldq astRoot
    jsr astFree
    jsr freeUnits
    jmp DN

:   lda #<strCodeGen
    ldx #>strCodeGen
    jsr printLine
    jsr initCodeGen
    lda loopCode
    cmp #3 ; EDITOR_LOOP_RUN
    bne L1
    lda #<strEditorFn
    ldx #>strEditorFn
    ldy #1
    bra L2
L1: lda #0
    tax
    tay
L2: jsr setCodeGenProgramChain
    jsr objCodeGen

    ldq astRoot
    jsr astFree

    jsr freeUnits

    ; Check the error count (a code generation error)
    jsr buildHasErrors
    beq :+

    ; Error - so don't link
    jmp DN

:   lda #<strLinking
    ldx #>strLinking
    jsr printLine
    jsr initLinker

    ; If running, use a different filename and set a chain program call.
    lda loopCode
    cmp #3 ; EDITOR_LOOP_RUN
    bne L4
    lda #<strRunFn
    ldx #>strRunFn
    jsr genPrgFile
    bra DN

L4: lda #<sourceFn
    ldx #>sourceFn
    jsr genPrgFile

    ; The errors and warnings are in the build result. The editor shows
    ; them, so go straight back to it.
DN: jmp finishBuildResult
.endproc

.proc printLine
    sta ptr1
    stx ptr1+1
    ldy #0
:   lda (ptr1),y
    beq :+
    jsr CHROUT
    iny
    bne :-
:   lda #13
    jsr CHROUT
    rts
.endproc
