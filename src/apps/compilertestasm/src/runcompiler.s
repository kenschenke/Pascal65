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
.include "asm.inc"
.include "ast.inc"
.include "tpu.inc"

.export runCompiler, unitList, madeUnits, makeRebuild

.import initTokenizer, initParser, initResolver, initTypeCheck, errorCount
.import initIcode, initCodeGen, initLinker, freeUnits, tokenizeAndParseUnits
.import freeUnitBodies
.import initTpu
.import nextTestPrg, failTests, expectedError, lastError

.data

objFilename: .asciiz "zztmp"
tempFilename: .asciiz "zztpu"         ; tpuBegin's (tpu.s)
unitPrefix: .asciiz ICODE_UNIT_PREFIX

.bss

globalSlots: .res 2

sourceFn: .res 2
tokens: .res 4
astRoot: .res 4
unitList: .res 4
runtimeStackSize: .res 2
runtimeMode: .res 1             ; RT_MODE_* (asm.inc)
prgName: .res 17                ; checkExpectedError: the PRG's name
unitMode: .res 1                ; non-zero for a unit compiled to its TPU
unitName: .res 13
makeRoot: .res 2                ; runCompiler's file
makeFn: .res 17                 ; a unit's source, from tpuMake
MADE_MAX = 64
madeUnits: .res MADE_MAX + 1    ; the units runCompiler compiled
madeLen: .res 1
makeRebuild: .res 1             ; non-zero: rebuild every unit, then clear

.code

; This routine compiles the file named at A/X (null-terminated), as
; compilerasm does: first each unit it needs whose TPU isn't current, on
; its own (unit mode), in the order tpuMake names them. madeUnits gets
; each unit's source name, without ".pas", and a space. A make error is
; checked as an error test's, if one is expected, and so is a unit's.
; With makeRebuild set, it first erases every unit's TPU (tpuClean), as
; the editor's Rebuild all does.
.proc runCompiler
    sta makeRoot
    stx makeRoot+1
    lda #0
    sta makeFn
    sta madeLen
    sta madeUnits
    sta errorCount
    lda makeRebuild
    beq L1
    lda #0
    sta makeRebuild
    jsr initTpu
    lda makeRoot
    ldx makeRoot+1
    jsr tpuClean
    bcs ER
L1: jsr initTpu
    lda #<makeFn
    ldx #>makeFn
    jsr pushAX
    lda makeRoot
    ldx makeRoot+1
    jsr tpuMake
    bcs ER
    cmp #0
    beq FL
    jsr addMade
    lda #<makeFn
    ldx #>makeFn
    jsr compileFile
    lda errorCount              ; a unit's error (compileUnit)
    bne ER
    bra L1
FL: lda makeRoot
    ldx makeRoot+1
    jmp compileFile

ER: lda expectedError
    bne :+
    jmp failTests
:   lda makeRoot
    sta sourceFn
    lda makeRoot+1
    sta sourceFn+1
    jmp checkExpectedError
.endproc

; This routine adds makeFn's name, without ".pas", and a space to
; madeUnits, as far as it holds them
.proc addMade
    ldx madeLen
    cpx #MADE_MAX - 1
    bcc :+
    rts
:   ldy #0
:   lda makeFn,y
    beq :+
    cmp #'.'
    beq :+
    cpx #MADE_MAX - 1
    bcs :+
    sta madeUnits,x
    inx
    iny
    bra :-
:   lda #' '
    sta madeUnits,x
    inx
    lda #0
    sta madeUnits,x
    stx madeLen
    rts
.endproc

; This routine loads the compiler modules, one by one, and runs them.
; The null-terminated filename is passed in A/X.
.proc compileFile
    sta sourceFn
    sta ptr1
    stx sourceFn+1
    stx ptr1+1

    ; Clear the error count
    lda #0
    sta errorCount

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
.ifdef FORCESTATIC
    ; This set runs every test with the static runtime (see the
    ; Makefile), so static mode keeps the coverage it had
    lda #RT_MODE_STATIC
.else
    jsr getParserRuntimeMode
.endif
    sta runtimeMode

    ; Check the error count
    lda errorCount
    beq :+

    ; Error - so don't continue
    jmp failTests

    ; Free the tokens
:   ldq tokens
    jsr freeMemBuf

    ; Reset error count
    lda #0
    sta errorCount

    jsr tokenizeAndParseUnits

    ; A unit (unitTests in compiletests.s) is compiled to its TPU
    jsr checkUnitMode
    lda unitMode
    beq :+
    jmp compileUnit

:   lda #'R'
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
    lda errorCount
    beq :+

    ; A program the compiler must refuse may be refused by the resolver
    ; (errTooManyVariables). Free it as resolvertest does, then check.
    lda expectedError
    bne RE

    ; Error - so don't continue
    jmp failTests

RE: jsr scopeExit
    jsr freeSymtab
    ldq astRoot
    jsr astFree
    jsr freeUnits
    jmp checkExpectedError

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
    lda errorCount
    beq :+

    ; Error - so don't continue
    jmp failTests

:   ; Free what code generation doesn't need
    ldq astRoot
    jsr astFreeBodies
    jsr freeUnitBodies

    lda #'G'
    jsr CHROUT
    jsr initCodeGen
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
    jsr objCodeGen

    ldq astRoot
    jsr astFree

    jsr freeUnits

    ; A program the compiler must refuse may be refused by the linker
    lda expectedError
    beq L3
    lda errorCount
    bne :+
    jsr initLinker
    lda sourceFn
    ldx sourceFn+1
    jsr genPrgFile
:   jmp checkExpectedError

L3: lda #'L'
    jsr CHROUT
    jsr initLinker
    lda sourceFn
    ldx sourceFn+1
    jsr genPrgFile

    ; An error or warning from code generation or linking fails the test
    lda errorCount
    beq :+
    jmp failTests
:

    lda #13
    jsr CHROUT

    rts

.endproc

; This routine sets unitMode if the source parsed into astRoot is a unit,
; and keeps its name in unitName
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

; This routine compiles the unit in astRoot on its own to its TPU, as
; compilerasm does (unit mode, runcompiler.s there), once it and the units
; it uses are parsed. An error in resolving, type checking or icode frees
; the unit, erases its temporary files (tpuAbort) and returns, with
; errorCount set, for runCompiler to check as an error test's.
.proc compileUnit
    lda #'U'
    jsr CHROUT
    jsr initTpu
    ldq unitList
    jsr pushQ
    lda sourceFn
    ldx sourceFn+1
    jsr pushAX
    ldq astRoot
    jsr tpuBegin
    bcc :+
    jmp failTests
:

    ; It is resolved with the units it uses, and numbered from slot 0
    lda #'R'
    jsr CHROUT
    jsr initResolver
    ldq unitList
    jsr setResolverUnitsList
    jsr initScopeStack
    jsr initStandardRoutines
    jsr injectSystemUnit
    ldq astRoot
    jsr addModuleUnit
    jsr resolveUnits
    lda #0
    tax
    jsr setUnitOffsets
    jsr getResolverUnitsList
    stq unitList
    lda errorCount
    beq :+
    jsr scopeExit
    jsr freeSymtab
    jmp UF
:

    lda #'K'
    jsr CHROUT
    jsr initTypeCheck
    ldq unitList
    jsr typeCheckUnits

    lda #'I'
    jsr CHROUT
    jsr initIcode
    ldq unitList
    jsr setIcodeUnitsList
    lda runtimeStackSize
    ldx runtimeStackSize+1
    jsr setIcodeStackSize
    lda #0
    tax
    jsr setIcodeGlobalSlots
    lda runtimeMode
    jsr setIcodeRuntimeMode
    ldq astRoot
    jsr icodeWrite
    jsr scopeExit
    jsr freeSymtab
    lda errorCount
    bne UF

    ; Its TPU. Its root is in the units list, which frees it.
    jsr initTpu
    lda #<unitName
    ldx #>unitName
    jsr tpuFinish
    php
    jsr freeUnits
    plp
    bcs FL
    lda #13
    jmp CHROUT

FL: jmp failTests

UF: jsr freeUnits
    jmp abortUnit
.endproc

; This routine erases the temporary files of the unit's compile, which
; failed, and fails the tests unless they're gone: zztpu and its icode
; file (ICODE_UNIT_PREFIX and its name)
.proc abortUnit
    jsr initTpu
    lda #<unitName
    ldx #>unitName
    jsr tpuAbort
    lda #<tempFilename
    ldx #>tempFilename
    ldy #0
    ldz #0
    jsr doesFileExist
    bne FL
    ldx #0
:   lda unitPrefix,x
    beq :+
    sta prgName,x
    inx
    bra :-
:   ldy #0
:   lda unitName,y
    sta prgName,x
    beq :+
    inx
    iny
    bra :-
:   lda #<prgName
    ldx #>prgName
    ldy #0
    ldz #0
    jsr doesFileExist
    bne FL
    rts
FL: jmp failTests
.endproc

; This routine finishes a program the compiler must refuse. It fails the
; tests unless the resolver, code generation or the linker reported
; exactly one error,
; expectedError, and left no object file and no PRG.
.proc checkExpectedError
    lda errorCount
    cmp #1
    bne FL
    lda lastError
    cmp expectedError
    bne FL

    ; The object file must be gone
    lda #<objFilename
    ldx #>objFilename
    ldy #0
    ldz #0
    jsr doesFileExist
    bne FL

    ; Nor a PRG: the source's name without ".pas"
    lda sourceFn
    sta ptr1
    lda sourceFn+1
    sta ptr1+1
    ldy #0
:   lda (ptr1),y
    sta prgName,y
    beq :+
    iny
    cpy #16
    bne :-
:   cpy #4
    bcc FL
    lda #0
    sta prgName-4,y
    lda #<prgName
    ldx #>prgName
    ldy #0
    ldz #0
    jsr doesFileExist
    bne FL

    lda #13
    jsr CHROUT
    rts

FL: jmp failTests
.endproc
