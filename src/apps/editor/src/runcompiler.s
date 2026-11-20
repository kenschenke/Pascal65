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
.include "tpu.inc"
.include "ast.inc"
.include "error.inc"
.include "4510macros.inc"

.export runCompiler, unitList

.import initTokenizer, initParser, initResolver, initTypeCheck
.import initBuildResult, finishBuildResult, buildHasErrors
.import initIcode, initCodeGen, initLinker, freeUnits, tokenizeAndParseUnits
.import initTpu

.bss

globalSlots: .res 2

loopCode: .res 1
rootFn: .res 17                 ; runCompiler's file
makeFn: .res 17                 ; a unit's source, from tpuMake
sourceFn: .res 17               ; compileFile's file
tokens: .res 4
astRoot: .res 4
unitList: .res 4
runtimeStackSize: .res 2
runtimeMode: .res 1             ; RT_MODE_* (asm.inc)
unitMode: .res 1                ; non-zero for a unit compiled to its TPU
unitName: .res 13

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
strTpu: .asciiz "Writing Unit File"

.code

; This routine compiles a file. A contains either EDITOR_LOOP_COMPILE or
; EDITOR_LOOP_RUN. The null-terminated filename is passed in X/Y. First
; it compiles each unit the file needs whose TPU isn't current, on its
; own (unit mode), in the order tpuMake names them, as Turbo Pascal's
; Make did. The build result holds the errors and warnings of them all.
; EDITOR_LOOP_REBUILD first erases the TPU of every unit make can compile
; (tpuClean), so it compiles them all. Returns the carry set if a program
; was linked to run: not after an error, nor for a unit.
.proc runCompiler
    sta loopCode
    ; Copy the source filename into rootFn
    stx ptr1
    sty ptr1+1
    ldy #0
:   lda (ptr1),y
    sta rootFn,y
    beq :+
    iny
    bne :-
    ; Clear the screen and home the cursor
:   lda #147
    jsr CHROUT

    ; Forget the last build. logError and logWarning record this one's
    ; errors and warnings.
    jsr initBuildResult

    lda #0
    sta makeFn
    sta unitMode
    lda loopCode
    cmp #6 ; EDITOR_LOOP_REBUILD (editor.inc)
    bne L1
    jsr initTpu
    lda #<rootFn
    ldx #>rootFn
    jsr tpuClean
    bcs DN
L1: jsr initTpu
    lda #<makeFn
    ldx #>makeFn
    jsr pushAX
    lda #<rootFn
    ldx #>rootFn
    jsr tpuMake
    bcs DN
    cmp #0
    beq FL
    lda #<makeFn
    ldx #>makeFn
    jsr compileFile
    jsr buildHasErrors
    bne DN
    bra L1
FL: lda #<rootFn
    ldx #>rootFn
    jsr compileFile

    ; The errors and warnings are in the build result. The editor shows
    ; them, so go straight back to it.
DN: jsr finishBuildResult
    lda unitMode
    bne NR
    jsr buildHasErrors
    bne NR
    sec
    rts
NR: clc
    rts
.endproc

; This routine loads the compiler modules, one by one, and runs them.
; The null-terminated filename is passed in A/X.
.proc compileFile
    ; Copy the source filename into sourceFn
    sta ptr1
    stx ptr1+1
    ldy #0
:   lda (ptr1),y
    sta sourceFn,y
    beq :+
    iny
    bne :-
    ; Print a couple CRs
:   lda #13
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

    ; A unit compiled on its own (unit mode) is written to its TPU
:   jsr checkUnitMode
    lda unitMode
    beq :+
    jmp compileUnit

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

DN: rts
.endproc

; This routine compiles the unit in astRoot on its own to its TPU, as
; compilerasm does (unit mode), once it and the units it uses are parsed.
; Its interface is written first, as the parser made it. An error erases
; the temporary files and leaves the heap to editorLoop, which clears it.
.proc compileUnit
    jsr initTpu
    ldq unitList
    jsr pushQ
    lda #<sourceFn
    ldx #>sourceFn
    jsr pushAX
    ldq astRoot
    jsr tpuBegin
    bcc :+
    jmp tpuError

    ; It is resolved with the units it uses, and numbered from slot 0
:   lda #<strResolving
    ldx #>strResolving
    jsr printLine
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
    jsr buildHasErrors
    bne AB

    lda #<strTypeChecking
    ldx #>strTypeChecking
    jsr printLine
    jsr initTypeCheck
    ldq unitList
    jsr typeCheckUnits
    lda #<sourceFn
    ldx #>sourceFn
    jsr setCompilerFilename

    lda #<strIcode
    ldx #>strIcode
    jsr printLine
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
    jsr buildHasErrors
    bne AB

    ; Its TPU. Its root is in the units list, which frees it.
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
    bcs tpuError
    rts
AB: jmp abortUnit
.endproc

; This routine reports that the unit's TPU couldn't be written
.proc tpuError
    jsr abortUnit
    lda #errUnitNotWritten
    ldx #0
    ldy #0
    jmp compilerError
.endproc

; This routine erases the temporary files of the unit's compile, which
; failed (tpuAbort)
.proc abortUnit
    jsr initTpu
    lda #<unitName
    ldx #>unitName
    jmp tpuAbort
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
