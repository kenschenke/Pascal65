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
.include "tpu.inc"
.include "ast.inc"
.include "error.inc"
.include "4510macros.inc"

.export runCompiler, unitList
.ifdef __HEAPPROFILE__
.export profileExit
.endif

.import initTokenizer, initParser, initResolver, initTypeCheck, errorCount
.import initIcode, initCodeGen, initLinker, freeUnits, tokenizeAndParseUnits
.import freeUnitBodies
.import initTpu
.ifdef __HEAPPROFILE__
.import initMemInfo
.endif

.bss

globalSlots: .res 2

sourceFn: .res 2
tokens: .res 4
astRoot: .res 4
unitList: .res 4
runtimeStackSize: .res 2
runtimeMode: .res 1             ; RT_MODE_* (asm.inc)
unitMode: .res 1                ; non-zero for a unit compiled to its TPU
unitName: .res 13
makeRoot: .res 2                ; runCompiler's file
makeFn: .res 17                 ; a unit's source, from tpuMake

.data

compilingMsg: .asciiz "Compiling "
strTokenizing: .asciiz "Tokenizing"
strParsing: .asciiz "Parsing"
strResolving: .asciiz "Resolving"
strTypeChecking: .asciiz "Type Checking"
strIcode: .asciiz "Intermediate Code"
strCodeGen: .asciiz "Generating Object Code"
strLinking: .asciiz "Linking"
strTpu: .asciiz "Writing Unit File"

.code

; This routine compiles the file named at A/X (null-terminated). First it
; compiles each unit the file needs whose TPU isn't current, on its own
; (unit mode), in the order tpuMake names them, as Turbo Pascal's Make
; did.
.proc runCompiler
    sta makeRoot
    stx makeRoot+1
    lda #0
    sta makeFn
    sta errorCount
L1: jsr initTpu
    lda #<makeFn
    ldx #>makeFn
    jsr pushAX
    lda makeRoot
    ldx makeRoot+1
    jsr tpuMake
    bcs DN
    cmp #0
    beq FL
    lda #<makeFn
    ldx #>makeFn
    jsr compileFile
    lda errorCount
    beq L1
DN: rts
FL: lda makeRoot
    ldx makeRoot+1
    ; Fall through
.endproc

; This routine loads the compiler modules, one by one, and runs them.
; The null-terminated filename is passed in A/X.
.proc compileFile
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

    ; A unit compiled on its own (unit mode) is written to its TPU. Its
    ; interface is written now, as the parser made it.
    jsr checkUnitMode
    lda unitMode
    beq :+
    jsr initTpu
    ldq unitList
    jsr pushQ
    lda sourceFn
    ldx sourceFn+1
    jsr pushAX
    ldq astRoot
    jsr tpuBegin
    bcc :+
    jmp tpuError

:   lda #<strResolving
    ldx #>strResolving
    jsr printLine
    jsr initResolver
    ldq unitList
    jsr setResolverUnitsList
    jsr initScopeStack
    jsr initStandardRoutines
    jsr injectSystemUnit

    ; The unit goes in the units list, after injectSystemUnit, and is
    ; resolved with the units it uses. Its slots are numbered from 0.
    lda unitMode
    beq :+
    ldq astRoot
    jsr addModuleUnit
:   jsr resolveUnits
    lda unitMode
    beq :+
    lda #0
    sta globalSlots
    sta globalSlots+1
    tax
    jsr setUnitOffsets
    jsr getResolverUnitsList
    stq unitList
    jmp RD

    ; resolveUnits reports errors in each unit's file. The rest are in
    ; the program's.
:   lda sourceFn
    ldx sourceFn+1
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
RD:

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
    lda unitMode                ; a unit is type checked with the units
    bne :+
    ldq astRoot
    jsr declTypeCheck
:   ldq unitList
    jsr typeCheckUnits
    lda sourceFn
    ldx sourceFn+1
    jsr setCompilerFilename

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

    ; A unit's TPU: what tpuBegin wrote, then the unit's icode. It has no
    ; code generation. Its root is in the units list, which frees it.
:   lda unitMode
    beq :+
    lda #<strTpu
    ldx #>strTpu
    jsr printLine
    jsr initTpu
    lda #<unitName
    ldx #>unitName
    jsr tpuFinish
    php
    jsr freeUnits
    plp
    bcc DN
    jmp tpuError
DN: rts

:   ; The statements and expressions have been turned into intermediate
    ; code. Free them to make room for code generation.
    ldq astRoot
    jsr astFreeBodies
    jsr freeUnitBodies

    lda #<strCodeGen
    ldx #>strCodeGen
    jsr printLine
    jsr initCodeGen
    lda #0
    tax
    tay
    jsr setCodeGenProgramChain
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

    ; Check the error count (a code generation error)
    lda errorCount
    beq :+

    ; Error - so don't link
    rts

:   lda #<strLinking
    ldx #>strLinking
    jsr printLine
    jsr initLinker
    lda sourceFn
    ldx sourceFn+1
    jmp genPrgFile
.endproc

; This routine sets unitMode if the source parsed into astRoot is a unit,
; to be compiled on its own to its TPU, and keeps its name in unitName
.proc checkUnitMode
    lda #0
    sta unitMode
    ldq astRoot
    stq ptr1
    ldz #decl::type
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr2
    ldz #type::kind
    nop
    lda (ptr2),z
    cmp #TYPE_UNIT
    beq :+
    rts
:   inc unitMode
    ldz #decl::name
    ldx #0
:   nop
    lda (ptr1),z
    sta unitName,x
    beq :+
    inz
    inx
    cpx #12
    bne :-
    lda #0
    sta unitName,x
:   rts
.endproc

; This routine reports that the unit's TPU couldn't be written
.proc tpuError
    lda #errUnitNotWritten
    ldx #0
    ldy #0
    jmp compilerError
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
