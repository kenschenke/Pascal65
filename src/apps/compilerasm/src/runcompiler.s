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
.include "meminfo.inc"
.include "4510macros.inc"

.export runCompiler, unitList
.ifdef __HEAPPROFILE__
.export profileExit
.endif

.import initTokenizer, initParser, initResolver, initTypeCheck, errorCount
.import initIcode, initCodeGen, initLinker, freeUnits, tokenizeAndParseUnits
.import freeUnitBodies
.ifdef __HEAPPROFILE__
.import initMemInfo
.endif

.bss

sourceFn: .res 2
tokens: .res 4
astRoot: .res 4
unitList: .res 4
runtimeStackSize: .res 2
runtimeFeatures: .res 1         ; runtime packages to link (RTF_*)
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

.code

; This routine loads the compiler modules, one by one, and runs them.
; The null-terminated filename is passed in A/X.
.proc runCompiler
    sta sourceFn
    sta ptr1
    stx sourceFn+1
    stx ptr1+1
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
    ldy #0
:   lda (ptr1),y
    beq :+
    jsr CHROUT
    iny
    bne :-
:   lda #13
    jsr CHROUT

    ; Reset the error count
    lda #0
    sta errorCount

    ; Tokenize the source file
    lda #<strTokenizing
    ldx #>strTokenizing
    jsr printLine
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

    ; Check the error count
    lda errorCount
    beq :+

    ; Error - so don't continue
    rts

    ; Free the tokens
:   ldq tokens
    jsr freeMemBuf

    jsr tokenizeAndParseUnits

    lda #<strResolving
    ldx #>strResolving
    jsr printLine
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

.ifdef __HEAPPROFILE__
    ; Profile before type checking (shows as "Resolving")
:   jsr initMemInfo
    jsr heapProfile
.endif

.ifdef __HEAPPROFILE__
    lda #<strTypeChecking
.else
:   lda #<strTypeChecking
.endif
    ldx #>strTypeChecking
    jsr printLine
    jsr initTypeCheck
    ldq astRoot
    jsr declTypeCheck
    ldq unitList
    jsr typeCheckUnits

.ifdef __HEAPPROFILE__
    ; Profile after type checking (shows as "Type checking")
    jsr initMemInfo
    jsr heapProfile
.endif

    ; Generate the intermediate code
    lda #<strIcode
    ldx #>strIcode
    jsr printLine
    jsr initIcode
    ldq unitList
    jsr setIcodeUnitsList
    ldq astRoot
    jsr icodeWrite
    jsr getIcodeRuntimeFeatures
    sta runtimeFeatures

.ifdef __HEAPPROFILE__
    ; Build with PROFILEFLAGS="-D __HEAPPROFILE__" to show a heap profile
    ; once the AST is complete. The meminfo overlay replaces icode in
    ; overlay space, which is fine because icode is finished.
    jsr initMemInfo
    jsr heapProfile
.endif

    ; Free the PROGRAM scope symbol table
    jsr scopeExit
    jsr freeSymtab

    ; Check the error count
    lda errorCount
    beq :+

    ; Error - so don't continue
    rts

:   ; The statements and expressions have been turned into intermediate
    ; code. Free them to make room for code generation.
    ldq astRoot
    jsr astFreeBodies
    jsr freeUnitBodies

    lda #<strCodeGen
    ldx #>strCodeGen
    jsr printLine
    jsr initCodeGen
    ldq unitList
    jsr setCodeGenUnitList
    lda runtimeStackSize
    ldx runtimeStackSize+1
    jsr setCodeGenStackSize
    lda runtimeFeatures
    jsr setCodeGenRuntimeFeatures
    lda runtimeMode
    jsr setCodeGenRuntimeMode
    lda #0
    tax
    tay
    jsr setCodeGenProgramChain
    ldq astRoot
    jsr objCodeGen

.ifdef __HEAPPROFILE__
    ; Second profile: the AST is still allocated and code generation is done.
    jsr initMemInfo
    jsr heapProfile
.endif

    ldq astRoot
    jsr astFree

    jsr freeUnits

.ifdef __HEAPPROFILE__
    ; Third profile: everything is freed except what linking needs.
    jsr initMemInfo
    jsr heapProfile
.endif

    ; Check the error count (code generation reports a program too large)
    lda errorCount
    beq :+

    ; Error - so don't link
    jmp freeLinkerTags

:   lda #<strLinking
    ldx #>strLinking
    jsr printLine
    jsr initLinker
    lda sourceFn
    ldx sourceFn+1
    jsr genPrgFile
    jsr freeLinkerTags
    rts
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

.ifdef __HEAPPROFILE__
; Exit handler for profiling builds
.proc profileExit
    jsr initMemInfo
    jsr heapProfile
    rts
.endproc
.endif
