;
; buildtest.s
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Tests the IDE's build result (builderrors.s in the editor app, see
; buildresult.inc). It links builderrors.s on its own and reports made-up
; errors and warnings to logError and logWarning, as the compiler does
; through rtCompilerError: the message pointer on the runtime stack, the
; line in A/X and the file from setCompilerFilename.
;
; Each test is a list of steps (OP_*): calls into builderrors.s and checks
; of the bytes of buildResult. The runtime stack must be as it was after
; each test, since logError and logWarning pop the message.

.include "cbm_kernal.inc"
.include "zeropage.inc"
.include "asmlib.inc"
.include "4510macros.inc"
.include "poisonbss.inc"
.include "buildresult.inc"

.import initLib
.import testInit, testPass, testFail, testMemCheck, testLeakCheck
.import initBuildResult, finishBuildResult, logError, logWarning
.import buildResult

OP_END = 0
OP_INIT = 1                 ; initBuildResult
OP_FILE = 2                 ; .asciiz filename: setCompilerFilename
OP_ERROR = 3                ; .word line, .dword msg: logError
OP_WARN = 4                 ; .word line, .dword msg: logWarning
OP_MANY = 5                 ; .byte kind, count: that many, line = msg =
                            ; a counter from 1 (reset by OP_INIT)
OP_FINISH = 6               ; finishBuildResult
OP_SETWORD = 7              ; .word offset, value: write to buildResult
OP_CHECK = 8                ; .word offset, .byte length, the bytes
OP_LAST = 8

; The stack sentinel each test pushes before its steps
SENTINEL = $5aa5c33c

.macro INIT
    .byte OP_INIT
.endmacro

.macro SETFILE name
    .byte OP_FILE
    .asciiz name
.endmacro

.macro LOGERR line, msg
    .byte OP_ERROR
    .word line
    .dword msg
.endmacro

.macro LOGWARN line, msg
    .byte OP_WARN
    .word line
    .dword msg
.endmacro

.macro MANY kind, count
    .byte OP_MANY, kind, count
.endmacro

.macro FINISH
    .byte OP_FINISH
.endmacro

.macro SETWORD offset, value
    .byte OP_SETWORD
    .word offset, value
.endmacro

.macro CHKBYTE offset, value
    .byte OP_CHECK
    .word offset
    .byte 1, value
.endmacro

.macro CHKWORD offset, value
    .byte OP_CHECK
    .word offset
    .byte 2
    .word value
.endmacro

; The header: state, counts, entries, files and current
.macro CHKHEAD st, errs, warns, ents, fils
    .byte OP_CHECK
    .word 0
    .byte BUILDRESULT::files
    .byte st
    .word errs, warns
    .byte ents, fils, BUILD_SUMMARY
.endmacro

.macro CHKFILE n, name
    .byte OP_CHECK
    .word BUILDRESULT::files + (n) * BUILD_FILENAME_SIZE
    .byte .strlen(name) + 1
    .asciiz name
.endmacro

.macro CHKENTRY n, msg, line, file, kind
    .byte OP_CHECK
    .word BUILDRESULT::entries + (n) * .sizeof(BUILDENTRY)
    .byte .sizeof(BUILDENTRY)
    .dword msg
    .word line
    .byte file, kind
.endmacro

.macro ENDTEST
    .byte OP_END
.endmacro

.bss

testNum: .res 1
opPtr: .res 2               ; The next step
opNum: .res 1               ; The step being run, from 1
counter: .res 2             ; OP_MANY's line and message
manyKind: .res 1
manyLeft: .res 1
valQ: .res 4
line: .res 2
chkAddr: .res 2
chkOff: .res 2
chkLen: .res 1
chkIdx: .res 1
expByte: .res 1
actByte: .res 1
fnBuf: .res 24

.data

strTest: .asciiz "test "
strStep: .asciiz " step "
strOffset: .asciiz " offset $"
strExpected: .asciiz ": expected $"
strGot: .asciiz ", got $"
strStack: .byte ": runtime stack not balanced", 13, 0
strBadOp: .byte ": unknown step", 13, 0
strRuntime: .byte "runtime error", 13, 0

opProcs:
    .addr opInit, opFile, opError, opWarn, opMany, opFinish, opSetWord
    .addr opCheck

.rodata

tests:
    .addr testInitClears, testOrder, testWarnOnly, testNoErrors
    .addr testCap, testFileTable, testLongName, testSaturate
    .addr 0

; initBuildResult clears the whole result, the last byte too
testInitClears:
    .asciiz "init clears"
    SETWORD BUILDRESULT::numErrors, $1234
    SETWORD BUILDRESULT::numWarns, $5678
    SETWORD BUILDRESULT::numEntries, $0505
    SETWORD BUILDRESULT::state, $ffff
    SETWORD .sizeof(BUILDRESULT) - 2, $abcd
    INIT
    CHKHEAD BUILD_NONE, 0, 0, 0, 0
    CHKWORD .sizeof(BUILDRESULT) - 2, 0
    ENDTEST

; Errors and warnings are kept in order, each file gets one slot
testOrder:
    .asciiz "order"
    INIT
    SETFILE "prog.pas"
    LOGERR 5, $11223344
    LOGWARN 7, $55667788
    SETFILE "unit1.pas"
    LOGERR 0, $0000aabb
    SETFILE "prog.pas"
    LOGWARN $1234, $ccddeeff
    FINISH
    CHKHEAD BUILD_FAILED, 2, 2, 4, 2
    CHKFILE 0, "prog.pas"
    CHKFILE 1, "unit1.pas"
    CHKBYTE BUILDRESULT::files + 2 * BUILD_FILENAME_SIZE, 0
    CHKENTRY 0, $11223344, 5, 0, BUILD_ERROR
    CHKENTRY 1, $55667788, 7, 0, BUILD_WARNING
    CHKENTRY 2, $0000aabb, 0, 1, BUILD_ERROR
    CHKENTRY 3, $ccddeeff, $1234, 0, BUILD_WARNING
    ENDTEST

; Warnings alone are a success
testWarnOnly:
    .asciiz "warnings only"
    INIT
    SETFILE "a.pas"
    LOGWARN 3, 1
    FINISH
    CHKHEAD BUILD_SUCCESS, 0, 1, 1, 1
    CHKENTRY 0, 1, 3, 0, BUILD_WARNING
    ENDTEST

testNoErrors:
    .asciiz "no errors"
    INIT
    FINISH
    CHKHEAD BUILD_SUCCESS, 0, 0, 0, 0
    ENDTEST

; Past MAX_BUILD_ENTRIES an error or warning is counted but not kept
testCap:
    .asciiz "cap"
    INIT
    SETFILE "prog.pas"
    MANY BUILD_ERROR, 30
    MANY BUILD_WARNING, 3
    MANY BUILD_ERROR, 2
    FINISH
    CHKHEAD BUILD_FAILED, 32, 3, MAX_BUILD_ENTRIES, 1
    CHKENTRY 0, 1, 1, 0, BUILD_ERROR
    CHKENTRY 29, 30, 30, 0, BUILD_ERROR
    CHKENTRY 30, 31, 31, 0, BUILD_WARNING
    CHKENTRY 31, 32, 32, 0, BUILD_WARNING
    ENDTEST

; Past MAX_BUILD_FILES names, a new name gets BUILD_FILE_UNKNOWN. A name
; already in the table still finds its slot, and no name is unknown.
testFileTable:
    .asciiz "file table"
    INIT
    .repeat 9, i
    SETFILE {.sprintf("file%d.pas", i + 1)}
    LOGERR i + 1, i + 1
    .endrep
    SETFILE "file3.pas"
    LOGERR 10, 10
    SETFILE ""
    LOGWARN 11, 11
    FINISH
    CHKHEAD BUILD_FAILED, 10, 1, 11, MAX_BUILD_FILES
    CHKFILE 0, "file1.pas"
    CHKFILE 7, "file8.pas"
    CHKBYTE BUILDRESULT::files + BUILD_FILE_UNKNOWN * BUILD_FILENAME_SIZE, 0
    CHKENTRY 0, 1, 1, 0, BUILD_ERROR
    CHKENTRY 7, 8, 8, 7, BUILD_ERROR
    CHKENTRY 8, 9, 9, BUILD_FILE_UNKNOWN, BUILD_ERROR
    CHKENTRY 9, 10, 10, 2, BUILD_ERROR
    CHKENTRY 10, 11, 11, BUILD_FILE_UNKNOWN, BUILD_WARNING
    ENDTEST

; No name takes no slot. A 16-character name fills a slot.
testLongName:
    .asciiz "long name"
    INIT
    SETFILE ""
    LOGERR 1, 1
    SETFILE "abcdefghijklmnopq"        ; setCompilerFilename keeps 16
    LOGERR 2, 2
    SETFILE "abcdefghijklmnop"
    LOGWARN 3, 3
    CHKHEAD BUILD_NONE, 2, 1, 3, 1
    CHKFILE 0, "abcdefghijklmnop"
    CHKENTRY 0, 1, 1, BUILD_FILE_UNKNOWN, BUILD_ERROR
    CHKENTRY 1, 2, 2, 0, BUILD_ERROR
    CHKENTRY 2, 3, 3, 0, BUILD_WARNING
    ENDTEST

; The counts stop at $FFFF
testSaturate:
    .asciiz "saturate"
    INIT
    SETWORD BUILDRESULT::numErrors, $fffe
    SETWORD BUILDRESULT::numWarns, $ffff
    SETFILE "a.pas"
    MANY BUILD_ERROR, 2
    MANY BUILD_WARNING, 1
    FINISH
    CHKHEAD BUILD_FAILED, $ffff, $ffff, 3, 1
    ENDTEST

.segment "ENTRY"

main:
    poisonBss               ; Must run before anything writes BSS

    jsr testInit

    ; Disable BASIC ROM
    lda $01
    and #$f8
    ora #$06
    sta $01

    jsr initLib
    jsr stackInit
    jsr initMemHeap
    jsr testMemCheck

    ; A runtime error (such as popping an empty stack) fails the test
    tsx
    stx savedStackPtr
    lda #<runtimeErr
    sta exitHandler
    lda #>runtimeErr
    sta exitHandler+1

    lda #0
    sta testNum
L1: lda testNum
    asl a
    tax
    lda tests,x
    sta opPtr
    lda tests+1,x
    sta opPtr+1
    ora opPtr
    beq L2
    jsr runTest
    inc testNum
    bra L1

L2: jsr testLeakCheck
    bcc :+
    jmp testFail
:   jmp testPass

.code

; Returns the next byte of the steps in A, with N and Z set by it
.proc getByte
    lda opPtr
    sta ptr3
    lda opPtr+1
    sta ptr3+1
    ldy #0
    lda (ptr3),y
    inc opPtr
    bne :+
    inc opPtr+1
:   cmp #0
    rts
.endproc

; Reads the next four bytes of the steps into valQ
.proc getQ
    ldx #0
:   phx
    jsr getByte
    plx
    sta valQ,x
    inx
    cpx #4
    bne :-
    rts
.endproc

; Runs the test opPtr points to. It fails the test run if a step fails.
.proc runTest
    ; Skip the name
:   jsr getByte
    bne :-

    ; Push the sentinel
    lda #<SENTINEL
    ldx #>SENTINEL
    ldy #^SENTINEL
    ldz #(SENTINEL >> 24)
    jsr pushQ

    lda #0
    sta opNum
L1: inc opNum
    jsr getByte
    beq DN
    cmp #OP_LAST+1
    bcc :+
    jsr printTestStep
    lda #<strBadOp
    ldx #>strBadOp
    jsr printStr
    jmp testFail
:   asl a
    tax
    lda opProcs-2,x
    sta ptr4
    lda opProcs-1,x
    sta ptr4+1
    jsr callPtr4
    bra L1

    ; The sentinel must be next on the runtime stack
DN: jsr popQ
    stq valQ
    lda valQ
    cmp #<SENTINEL
    bne BD
    lda valQ+1
    cmp #>SENTINEL
    bne BD
    lda valQ+2
    cmp #^SENTINEL
    bne BD
    lda valQ+3
    cmp #(SENTINEL >> 24)
    bne BD
    rts
BD: jsr printTestName
    lda #<strStack
    ldx #>strStack
    jsr printStr
    jmp testFail
.endproc

.proc callPtr4
    jmp (ptr4)
.endproc

.proc opInit
    lda #0
    sta counter
    sta counter+1
    jmp initBuildResult
.endproc

.proc opFile
    ldx #0
:   phx
    jsr getByte
    plx
    sta fnBuf,x
    cmp #0
    beq :+
    inx
    bne :-
:   lda #<fnBuf
    ldx #>fnBuf
    jmp setCompilerFilename
.endproc

; Reads a step's line and message and pushes the message
.proc getLineMsg
    jsr getByte
    sta line
    jsr getByte
    sta line+1
    jsr getQ
    ldq valQ
    jmp pushQ
.endproc

.proc opError
    jsr getLineMsg
    lda line
    ldx line+1
    ldy #1
    jmp logError
.endproc

.proc opWarn
    jsr getLineMsg
    lda line
    ldx line+1
    ldy #1
    jmp logWarning
.endproc

.proc opMany
    jsr getByte
    sta manyKind
    jsr getByte
    sta manyLeft
L1: inc counter
    bne :+
    inc counter+1
:   lda counter
    ldx counter+1
    ldy #0
    ldz #0
    jsr pushQ
    lda manyKind
    cmp #BUILD_WARNING
    beq :+
    lda counter
    ldx counter+1
    ldy #1
    jsr logError
    bra :++
:   lda counter
    ldx counter+1
    ldy #1
    jsr logWarning
:   dec manyLeft
    bne L1
    rts
.endproc

.proc opFinish
    jmp finishBuildResult
.endproc

; Points ptr4 at buildResult plus the offset in the next two bytes and
; keeps the offset in chkOff
.proc getAddr
    jsr getByte
    sta chkOff
    jsr getByte
    sta chkOff+1
    clc
    lda chkOff
    adc #<buildResult
    sta ptr4
    lda chkOff+1
    adc #>buildResult
    sta ptr4+1
    rts
.endproc

.proc opSetWord
    jsr getAddr
    lda ptr4
    sta chkAddr
    lda ptr4+1
    sta chkAddr+1
    jsr getByte
    pha
    jsr getByte
    tax
    lda chkAddr
    sta ptr4
    lda chkAddr+1
    sta ptr4+1
    ldy #1
    txa
    sta (ptr4),y
    dey
    pla
    sta (ptr4),y
    rts
.endproc

.proc opCheck
    jsr getAddr
    lda ptr4
    sta chkAddr
    lda ptr4+1
    sta chkAddr+1
    jsr getByte
    sta chkLen
    lda #0
    sta chkIdx
L1: lda chkIdx
    cmp chkLen
    beq DN
    jsr getByte
    sta expByte
    lda chkAddr
    sta ptr4
    lda chkAddr+1
    sta ptr4+1
    ldy chkIdx
    lda (ptr4),y
    sta actByte
    cmp expByte
    bne BD
    inc chkIdx
    bra L1
DN: rts

    ; test <name> step <n> offset $xxxx: expected $xx, got $xx
BD: jsr printTestStep
    lda #<strOffset
    ldx #>strOffset
    jsr printStr
    clc
    lda chkOff
    adc chkIdx
    pha
    lda chkOff+1
    adc #0
    jsr printHex
    pla
    jsr printHex
    lda #<strExpected
    ldx #>strExpected
    jsr printStr
    lda expByte
    jsr printHex
    lda #<strGot
    ldx #>strGot
    jsr printStr
    lda actByte
    jsr printHex
    lda #13
    jsr CHROUT
    jmp testFail
.endproc

; Prints "test <name>"
.proc printTestName
    lda #<strTest
    ldx #>strTest
    jsr printStr
    lda testNum
    asl a
    tax
    lda tests+1,x
    pha
    lda tests,x
    plx
    jmp printStr
.endproc

; Prints "test <name> step <n>"
.proc printTestStep
    jsr printTestName
    lda #<strStep
    ldx #>strStep
    jsr printStr
    lda opNum
    jmp printHex
.endproc

; A runtime error ends up here (see exitHandler)
.proc runtimeErr
    lda #<strRuntime
    ldx #>strRuntime
    jsr printStr
    jsr printTestName
    jmp testFail
.endproc

; Prints the zero-terminated string in A/X
.proc printStr
    sta ptr4
    stx ptr4+1
    ldy #0
:   lda (ptr4),y
    beq :+
    jsr CHROUT
    iny
    bne :-
:   rts
.endproc

; Prints A as two hex digits
.proc printHex
    pha
    lsr a
    lsr a
    lsr a
    lsr a
    jsr digit
    pla
    and #$0f
digit:
    cmp #10
    bcc :+
    adc #'a'-10-1           ; The carry is set
    jmp CHROUT
:   adc #'0'
    jmp CHROUT
.endproc
