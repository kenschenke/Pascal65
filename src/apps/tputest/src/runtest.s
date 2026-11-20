;
; runtest.s
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Routines to run a TPU test. A test whose source is a unit compiles it on
; its own to its TPU as compilerasm compiles one (runcompiler.s): tpuBegin
; after parsing, then resolving, type checking and icode, then tpuFinish.
; checkTpu checks the TPU's CRCs and lengths, and the dumpicode overlay
; dumps it (dumpTpu). A test whose source is a program compiles it to icode
; as icodetest does, with the units it uses loaded from their TPUs where
; they have them, and dumpIcode dumps it and each unit's code, from a TPU
; for a unit loaded from it. The dump is compared to the dump at the start
; of the source file, which must be formatted as shown:
;
; (* TestXXX
; Dump of the TPU or icode
; ...
; *)
;
; The first line of the file is ignored. The dump starts on the second
; line and continues until "*)" is found at the start of a line.

.include "c64.inc"
.include "ast.inc"
.include "tpu.inc"
.include "icode.inc"
.include "asmlib.inc"
.include "parser.inc"
.include "zeropage.inc"
.include "resolver.inc"
.include "dumpicode.inc"
.include "tokenizer.inc"
.include "typecheck.inc"
.include "cbm_kernal.inc"
.include "4510macros.inc"

.export runTest, unitList, printLine, unitName, sourceFn
.import testFail

.import initTokenizer, initParser, errorCount, errorNum, errorLine
.import tokenizeAndParseUnits, initResolver, freeUnits, resetTicks, getTicks
.import initTypeCheck, initDumpIcode, initIcode, initTpu
.import printMilliseconds, totalTicks, checkTpu

.bss

ch: .res 1
unitMode: .res 1            ; non-zero if the source is a unit
globalSlots: .res 2         ; a program's own level 1 slots
testNum: .res 2
sourceFn: .res 16
intBuf: .res 14
tokens: .res 4
astRoot: .res 4
stackSize: .res 2           ; the parser's, for the icode file's header
runtimeMode: .res 1
dumpMemBuf: .res 4
sourceBuf: .res 81
dumpBuf: .res 81
eofReached: .res 1
lineNumber: .res 2
foundDiff: .res 1
unitList: .res 4
unitName: .res 13           ; the unit's name

.data

strFnPrefix: .asciiz "test"
strFnSuffix: .asciiz ".pas"
strDOSSuffix: .asciiz ",s,r"
strEof: .byte "*)", $0d, $0
strDiff: .byte "A line was different. The source line is shown", $0d
         .byte "followed by the dump of the TPU.", $0d, $0d, $0
strLineNum: .asciiz "Line number: "
strTitle: .asciiz "Test "
strBadEof: .asciiz "Unequal number of lines"
strTokenizing: .asciiz " : Tokenizing, "
strParsing: .asciiz "Parsing, "
strResolving: .asciiz "Resolving, "
strTypeChecking: .asciiz "Type Check, "
strIcode: .asciiz "Icode, "
strTpu: .asciiz "TPU, "
strDumping: .asciiz "Dumping, "
strPass: .asciiz "Pass"
strErrorCount: .asciiz "Errors encountered"
strErrorNum: .asciiz "Error "
strErrorLine: .asciiz " on line "
strNoTpu: .asciiz "The TPU wasn't written"
.ifdef SAVEDUMP
strDumpPrefix: .asciiz "dump"
strWriteSuffix: .asciiz ",s,w"
.endif

.code

; This routine runs the TPU test numbered in A/X
.proc runTest
    sta testNum
    sta intOp1
    stx testNum+1
    stx intOp1+1

    lda #0
    sta errorCount
    tax
    tay
    taz
    stq unitList

    lda #<strTitle
    ldx #>strTitle
    jsr printLine
    lda #<intBuf
    ldx #>intBuf
    jsr writeInt16
    lda #<intBuf
    ldx #>intBuf
    jsr printLine

    jsr makeSourceFn
    jsr resetTicks

    ; Tokenize and parse the unit, then the units it uses
    lda #<strTokenizing
    ldx #>strTokenizing
    jsr printLine
    jsr initTokenizer
    lda #<sourceFn
    ldx #>sourceFn
    jsr tokenize
    stq tokens

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
    sta stackSize
    stx stackSize+1
    jsr getParserRuntimeMode
    sta runtimeMode
    jsr checkErrors
    ldq tokens
    jsr freeMemBuf
    jsr checkUnitMode

    jsr tokenizeAndParseUnits
    jsr checkErrors

    ; A unit's TPU: the first part, as the parser made the interface
    lda unitMode
    beq RS
    lda #<strTpu
    ldx #>strTpu
    jsr printLine
    jsr initTpu
    ldq unitList
    jsr pushQ
    lda #<sourceFn
    ldx #>sourceFn
    jsr pushAX
    ldq astRoot
    jsr tpuBegin
    bcc RS
    jmp noTpu

    ; A unit is resolved with the units it uses, in the units list, and
    ; its slots are numbered from 0. A program's are numbered first.
RS: lda #<strResolving
    ldx #>strResolving
    jsr printLine
    jsr initResolver
    ldq unitList
    jsr setResolverUnitsList
    jsr initScopeStack
    jsr initStandardRoutines
    jsr injectSystemUnit
    lda #0
    sta globalSlots
    sta globalSlots+1
    lda unitMode
    beq :+
    ldq astRoot
    jsr addModuleUnit
:   jsr resolveUnits
    lda unitMode
    beq :+
    lda #0
    tax
    jsr setUnitOffsets
    bra RD
:   jsr resolveProgram
RD: jsr getResolverUnitsList
    stq unitList
    jsr checkErrors

    lda #<strTypeChecking
    ldx #>strTypeChecking
    jsr printLine
    jsr initTypeCheck
    lda unitMode
    bne :+
    ldq astRoot
    jsr declTypeCheck
:   ldq unitList
    jsr typeCheckUnits
    jsr checkErrors

    lda #<strIcode
    ldx #>strIcode
    jsr printLine
    jsr initIcode
    ldq unitList
    jsr setIcodeUnitsList
    lda stackSize
    ldx stackSize+1
    jsr setIcodeStackSize
    lda globalSlots
    ldx globalSlots+1
    jsr setIcodeGlobalSlots
    lda runtimeMode
    jsr setIcodeRuntimeMode
    ldq astRoot
    jsr icodeWrite

    ; The program's scope, as the compiler frees it once icode is written
    jsr scopeExit
    jsr freeSymtab
    jsr checkErrors

    lda unitMode
    bne :+
    jsr dumpProgram
    bra CM

    ; The rest of the TPU: its icode section
:   jsr initTpu
    lda #<unitName
    ldx #>unitName
    jsr tpuFinish
    bcc :+
    jmp noTpu

    ; The root is the unit's, which freeUnits frees
:   jsr freeUnits

    lda testNum
    jsr checkTpu

    lda #<strDumping
    ldx #>strDumping
    jsr printLine
    jsr initDumpIcode
    lda #<unitName
    ldx #>unitName
    jsr dumpTpu
    stq dumpMemBuf
CM: ldq dumpMemBuf
    stq ptr1
    lda #0
    tax
    jsr setMemBufPos

    lda #0
    sta foundDiff
.ifdef SAVEDUMP
    jsr saveDump
.else
    jsr openSourceFile
    jsr compareLines
.endif

    lda foundDiff
    beq :+
    jmp testFail
:   lda #<strPass
    ldx #>strPass
    jsr printLine

    ldq dumpMemBuf
    jsr freeMemBuf

    jsr getTicks
    stq intOp1
    clc
    adcq totalTicks
    stq totalTicks
    jsr printMilliseconds
    lda #13
    jmp CHROUT
.endproc

; This routine resolves the program in astRoot, once its units are, as
; icodetest does: its slots first, then the units'
.proc resolveProgram
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
    sta globalSlots
    stx globalSlots+1
    jsr setUnitOffsets
    ldq astRoot
    jsr fixGlobalOffsets
    ldq astRoot
    jmp verifyFwdDeclarations
.endproc

; This routine dumps the program's icode file and each unit's code into
; dumpMemBuf, then erases the program's file and frees the program
.proc dumpProgram
    lda #<strDumping
    ldx #>strDumping
    jsr printLine
    jsr initDumpIcode
    jsr dumpIcode
    stq dumpMemBuf
    jsr initIcode
    jsr icodeFileErase
    ldq astRoot
    jsr astFree
    jmp freeUnits
.endproc

.proc noTpu
    lda #13
    jsr CHROUT
    lda #<strNoTpu
    ldx #>strNoTpu
    jsr printLine
    jmp testFail
.endproc

.ifdef SAVEDUMP
; With SAVEDUMP defined, a test writes its dump to the file dumpN (N is the
; test number) in place of comparing it (make savedump, see the Makefile).
.proc saveDump
    ldx #0
:   lda strDumpPrefix,x
    beq :+
    sta sourceFn,x
    inx
    bne :-
:   phx
    lda testNum
    sta intOp1
    lda testNum+1
    sta intOp1+1
    lda #<intBuf
    ldx #>intBuf
    jsr writeInt16
    plx
    ldy #0
:   lda intBuf,y
    beq :+
    sta sourceFn,x
    inx
    iny
    bne :-
:   ldy #0
:   lda strWriteSuffix,y
    sta sourceFn,x
    beq :+
    inx
    iny
    bne :-
:   txa
    ldx #<sourceFn
    ldy #>sourceFn
    jsr SETNAM
    lda #1
    ldx workDevice
    ldy #2
    jsr SETLFS
    jsr OPEN
    ldx #1
    jsr CHKOUT

L1: ldq dumpMemBuf
    jsr isMemBufAtEnd
    beq L2
    jsr readByte
    lda ch
    jsr CHROUT
    bra L1

L2: jsr CLRCHN
    lda #1
    jmp CLOSE
.endproc
.endif

; This routine fails the test if a stage reported an error, naming the
; first error and its line
.proc checkErrors
    lda errorCount
    bne :+
    rts
:   lda #13
    jsr CHROUT
    lda #<strErrorCount
    ldx #>strErrorCount
    jsr printLine
    lda #13
    jsr CHROUT
    lda #<strErrorNum
    ldx #>strErrorNum
    jsr printLine
    lda errorNum
    sta intOp1
    lda #0
    sta intOp1+1
    jsr printInt
    lda #<strErrorLine
    ldx #>strErrorLine
    jsr printLine
    lda errorLine
    sta intOp1
    lda errorLine+1
    sta intOp1+1
    jsr printInt
    jmp testFail
.endproc

; This routine prints the integer in intOp1.
.proc printInt
    lda #<intBuf
    ldx #>intBuf
    jsr writeInt16
    lda #<intBuf
    ldx #>intBuf
    jmp printLine
.endproc

.proc compareLines
L1: lda eofReached
    bne L2

    jsr readSourceLine
    lda eofReached
    bne L2
    jsr readDumpLine
    lda foundDiff
    bne L2
    jsr compareLine
    bcc L1

    lda #1
    sta foundDiff

L2: lda #1
    jsr CLOSE
    ldx #0
    jsr CHKIN
    jmp checkMemBufEof
.endproc

; This routine reads lines from the dump membuf until the end of the
; buffer is reached. If a non-empty line is found it flags an error.
.proc checkMemBufEof
L1: ldq dumpMemBuf
    jsr isMemBufAtEnd
    beq L3

    jsr readDumpLine

    lda dumpBuf
    cmp #13
    bne L2
    lda dumpBuf+1
    bne L2
    bra L1

L2: lda #13
    jsr CHROUT
    jsr CHROUT
    lda #<strBadEof
    ldx #>strBadEof
    jsr printLine
    lda #13
    jsr CHROUT
    lda #1
    sta foundDiff

L3: rts
.endproc

; This routine compares sourceBuf with dumpBuf. If they differ it shows
; both lines and the line number and fails the test.
.proc compareLine
    ldx #0

L1: lda sourceBuf,x
    beq L2
    cmp dumpBuf,x
    bne L3
    inx
    bne L1

L2: lda dumpBuf,x
    bne L3
    clc
    rts

L3: lda #$0d
    jsr CHROUT
    lda #<strDiff
    ldx #>strDiff
    jsr printLine

    lda #<strLineNum
    ldx #>strLineNum
    jsr printLine

    lda lineNumber
    sta intOp1
    lda lineNumber+1
    sta intOp1+1
    jsr printInt
    lda #13
    jsr CHROUT
    jsr CHROUT

    lda #<sourceBuf
    ldx #>sourceBuf
    jsr printLine

    lda #<dumpBuf
    ldx #>dumpBuf
    jsr printLine

    jmp testFail
.endproc

; This routine prints a null-terminated string. The address
; for the line is in A/X.
.proc printLine
    sta ptr1
    stx ptr1+1
    ldy #0

L1: lda (ptr1),y
    beq L2
    jsr CHROUT
    iny
    bne L1

L2: rts
.endproc

; This routine opens the source file and reads the first line
; to reach the dump.
.proc openSourceFile
    jsr appendDOSSuffix

    ldx workDevice
    lda #1
    tay
    iny
    jsr SETLFS

    jsr setSourceFn

    jsr OPEN
    ldx #1
    jsr CHKIN

    lda #0
    sta eofReached

    jsr readSourceLine
    lda #0
    sta lineNumber
    sta lineNumber+1

    rts
.endproc

; This routine formats the source filename using the test number.
; The format is testXXXX.pas and the buffer is null-terminated.
.proc makeSourceFn
    ldx #0
:   lda strFnPrefix,x
    beq :+
    sta sourceFn,x
    inx
    bne :-
:   phx
    lda testNum
    sta intOp1
    lda testNum+1
    sta intOp1+1
    lda #<intBuf
    ldx #>intBuf
    jsr writeInt16
    plx
    ldy #0
:   lda intBuf,y
    beq :+
    sta sourceFn,x
    inx
    iny
    bne :-
:   ldy #0
:   lda strFnSuffix,y
    beq :+
    sta sourceFn,x
    inx
    iny
    bne :-
:   lda #0
    sta sourceFn,x
    rts
.endproc

; This routine appends the DOS suffix of ",s,r" to the source filename.
.proc appendDOSSuffix
    ldx #0
:   lda sourceFn,x
    beq :+
    inx
    bne :-
:   ldy #0
:   lda strDOSSuffix,y
    beq :+
    sta sourceFn,x
    inx
    iny
    bne :-
:   lda #0
    sta sourceFn,x
    rts
.endproc

; This routine calls the Kernal SETNAM routine.
.proc setSourceFn
    ldx #0
:   lda sourceFn,x
    beq :+
    inx
    bne :-
:   txa
    ldx #<sourceFn
    ldy #>sourceFn
    jmp SETNAM
.endproc

; This routine reads a source line from the file. It stops when it finds
; a carriage return. The line is stored in sourceBuf, null-terminated.
.proc readSourceLine
    lda eofReached
    beq :+
    rts

:   ldy #0

L1: jsr CHRIN
    cmp #13
    bne L2
    sta sourceBuf,y
    iny
    lda #0
    sta sourceBuf,y
    inc lineNumber
    bne :+
    inc lineNumber+1
:   jmp lookForEof

L2: sta sourceBuf,y
    iny
    bra L1
.endproc

; This routine sets eofReached if the last source line is "*)<cr>", the
; end of the dump at the start of the source file.
.proc lookForEof
    ldx #0
L1: lda sourceBuf,x
    beq L3
    cmp strEof,x
    bne L2
    inx
    bne L1

L2: rts

L3: lda strEof,x
    bne :+
    lda #1
    sta eofReached
:   rts
.endproc

; This routine reads a byte from the dump membuf into ch
.proc readByte
    ldq dumpMemBuf
    stq ptr1

    lda #<ch
    sta ptr2
    lda #>ch
    sta ptr2+1
    lda #0
    sta ptr2+2
    sta ptr2+3

    lda #1
    ldx #0
    jmp readFromMemBuf
.endproc

; This routine reads a line from the dump membuf. It reads until it
; reaches a carriage return then null-terminates the buffer.
.proc readDumpLine
    lda #0
    pha

L1: ldq dumpMemBuf
    jsr isMemBufAtEnd
    bne :+
    lda #13
    jsr CHROUT
    jsr CHROUT
    lda #<strBadEof
    ldx #>strBadEof
    jsr printLine
    lda #13
    jsr CHROUT
    lda #1
    sta foundDiff
    pla
    rts
:   jsr readByte
    lda ch
    cmp #13
    bne :+

    plx
    sta dumpBuf,x
    inx
    lda #0
    sta dumpBuf,x
    rts

:   plx
    sta dumpBuf,x
    inx
    phx
    bra L1
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
