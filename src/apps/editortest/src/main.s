;
; main.s
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Tests the editor. It runs the test build of the editor overlay (make
; EDITORTEST=1 in src/overlays/editorasm), which takes its keys from a script
; instead of the keyboard (see editortest.s in the overlay).
;
; Each test (see tests.inc and the testsN.s files) types its script into the
; editor. When the script runs out, or the editor quits, runs or compiles,
; editorRun returns. The test then checks the current file: the cursor,
; numLines and the text of every line, then any other checks the test has.
; It frees everything with editorTestCleanup and checks for leaked heap
; blocks.
;
; The editor uses page zero that the KERNAL and BASIC need, so page zero is
; saved once everything is set up and restored after each test, as the
; editor program does.
;
; When a check fails the test's name and what differed are printed, then
; RESULT: FAIL.
;
; With COVERAGE defined it runs an instrumented editor overlay and saves the
; coverage map to the disk once every test passes (make coverage, see
; cov/mkcov.py).

.include "cbm_kernal.inc"
.include "c64.inc"
.include "zeropage.inc"
.include "asmlib.inc"
.include "editor.inc"
.include "editoroverlay.inc"
.include "4510macros.inc"
.include "poisonbss.inc"
.include "tests.inc"

.import initLib, initEditor, backupZeroPage, restoreZeroPage
.import testInit, testPass, testFail, testMemCheck, testLeakCheck
.import brkCatch, brkCode
.import tests
.ifdef COVERAGE
.import covInit, covSave
.endif

FAIL_VALUE = 0              ; failExp and failAct differ
FAIL_LINE = 1               ; the text of line lineNum differs
FAIL_TEXT = 2               ; the text failMsg names differs

; What a test is doing, for a BRK (see onBrk)
PHASE_EDIT = 0              ; Running the editor
PHASE_CHECK = 1             ; Checking the file
PHASE_CLEANUP = 2           ; Freeing the files (editorTestCleanup)

SCREEN25 = $0800             ; Screen RAM with 25 rows (see calcRowPtrs)
SCREEN_COLS = 80

.bss

testNum: .res 1
testRec: .res 2             ; The current test record
zpSaved: .res 1             ; Non-zero once page zero is saved
loopCode: .res 1            ; What editorRun returned
compileFn: .res 2           ; The filename editorRun returned
linesLeft: .res 1
lineNum: .res 1
actualLen: .res 1
actualBuf: .res MAX_LINE_LENGTH
failMsg: .res 2
failType: .res 1
failExp: .res 2
failAct: .res 2
failText: .res 2            ; The expected text
phase: .res 1
chkNum: .res 1              ; The number of the check being made
fnTmp: .res 24              ; A filename for the KERNAL

.data

; The theme colors editorRun copies (see copyThemeColors)
theme: .byte 0, 0, 1, 7, 3, 5, 13, 14, 15, 10

strTest: .asciiz "test "
strColon: .asciiz ": "
strExpected: .asciiz " expected $"
strGot: .asciiz ", got $"
strLine: .asciiz "line "
strCheck: .asciiz "check "
strExpText: .byte 13, "expected: ", 0
strActText: .byte 13, "actual:   ", 0
strRuntime: .byte 13, "runtime error", 13, 0
strBrk: .asciiz "brk code $"
strPhase: .addr phaseEdit, phaseCheck, phaseCleanup
phaseEdit: .byte " in the editor", 13, 0
phaseCheck: .byte " checking the file", 13, 0
phaseCleanup: .byte " in editortestcleanup", 13, 0
msgNoFile: .asciiz "no file is open"
msgAFile: .asciiz "a file is open"
msgCX: .asciiz "cursor x"
msgCY: .asciiz "cursor y"
msgNumLines: .asciiz "numlines"
msgTooFew: .asciiz "number of lines"
msgTooMany: .asciiz "more lines than expected"
msgByte: .asciiz "editfile byte"
msgWord: .asciiz "editfile word"
msgNoLine: .asciiz "no such line"
msgName: .asciiz "filename"
msgFiles: .asciiz "open files"
msgScreen: .asciiz "screen"
msgDisk: .asciiz "file on disk"
msgOnDisk: .asciiz "file exists"
msgLoop: .asciiz "editorrun returned"
msgCompileFn: .asciiz "compile filename"
msgBadCheck: .asciiz "unknown check"
strRead: .asciiz ",s,r"

; The checks after a test's lines (see CHK_* in tests.inc)
checkProcs:
    .addr checkByte, checkWord, checkHL, checkName, checkFiles
    .addr checkScreen, checkDisk, checkNotOnDisk, checkLoop
    .addr checkCompileFn, checkLine

.segment "ENTRY"

main:
    poisonBss               ; Must run before anything writes BSS

    jsr testInit

    ; Disable BASIC ROM
    lda $01
    and #$f8
    ora #$06
    sta $01

    lda #0
    sta zpSaved
    sta testNum
    jsr initLib
    jsr stackInit           ; The memory checks use the runtime stack
    jsr initMemHeap
    jsr testMemCheck

    ; A runtime error (such as running out of memory) fails the test
    tsx
    stx savedStackPtr
    lda #<runtimeErr
    sta exitHandler
    lda #>runtimeErr
    sta exitHandler+1

.ifdef COVERAGE
    jsr covInit
.endif
    jsr initEditor          ; Load the editor overlay
    jsr backupZeroPage
    lda #1
    sta zpSaved

L1: lda testNum
    asl a
    tax
    lda tests,x
    sta testRec
    lda tests+1,x
    sta testRec+1
    ora testRec
    beq L2
    inc testNum
    jsr runTest
    bra L1

L2:
.ifdef COVERAGE
    jsr covSave
.endif
    jsr testPass
    rts

.code

; Points ptr3 at the current test record
.proc loadRec
    lda testRec
    sta ptr3
    lda testRec+1
    sta ptr3+1
    rts
.endproc

.proc runTest
    lda #<onBrk             ; Report a BRK (a bad free) with the test
    sta brkCatch
    lda #>onBrk
    sta brkCatch+1
    lda #PHASE_EDIT
    sta phase

    jsr loadRec
    ldy #REC_KEYS+1
    lda (ptr3),y
    tax
    dey
    lda (ptr3),y
    pha
    ldy #REC_FLAGS
    lda (ptr3),y
    and #F_PASCAL
    tay
    pla
    jsr editorTestSetup

    lda #<theme
    ldx #>theme
    jsr editorRun
    sta loopCode
    stx compileFn
    sty compileFn+1

    lda #PHASE_CHECK
    sta phase
    jsr checkFile           ; The carry is set if a check failed
    php
    lda #PHASE_CLEANUP
    sta phase
    lda loopCode
    jsr editorTestCleanup
    lda #0
    sta brkCatch
    sta brkCatch+1
    jsr restoreZeroPage
    jsr clearScreen
    plp
    bcc :+
    jsr printFailure
    jmp testFail

:   jsr testLeakCheck
    bcc :+
    jsr printTestName
    jmp testFail
:   rts
.endproc

; Fails a value check: A/X is the message. failExp and failAct must be set.
.proc failValue
    sta failMsg
    stx failMsg+1
    lda #FAIL_VALUE
    sta failType
    sec
    rts
.endproc

; Fails a text check (FAIL_TEXT): A/X is the message. ptr2 is the expected
; text and actualBuf the actual text.
.proc failStr
    sta failMsg
    stx failMsg+1
    lda #FAIL_TEXT
    sta failType
    lda ptr2
    sta failText
    lda ptr2+1
    sta failText+1
    sec
    rts
.endproc

; Stores the byte in A as failAct and the byte at offset Y of the record as
; failExp. The Z flag is set if they are the same.
.proc cmpByte
    sta failAct
    lda (ptr3),y
    sta failExp
    lda #0
    sta failAct+1
    sta failExp+1
    lda failAct
    cmp failExp
    rts
.endproc

; Reads the word at offset Z of currentFile into failAct and the word at
; offset Y of the record into failExp. The Z flag is set if they are the
; same.
.proc cmpWord
    nop
    lda (currentFile),z
    sta failAct
    inz
    nop
    lda (currentFile),z
    sta failAct+1
    lda (ptr3),y
    sta failExp
    iny
    lda (ptr3),y
    sta failExp+1
    jmp cmpFail
.endproc

; Sets the Z flag if failExp and failAct are the same
.proc cmpFail
    lda failExp+1
    cmp failAct+1
    bne :+
    lda failExp
    cmp failAct
:   rts
.endproc

; Checks the current file against the test record. The carry is clear if it
; matches. Otherwise it is set and failMsg says what differed.
.proc checkFile
    lda #0
    sta chkNum
    jsr loadRec
    ldy #REC_FLAGS
    lda (ptr3),y
    and #F_NOFILE
    beq HF

    ; No file may be open
    clc
    lda ptr3
    adc #REC_LINES
    sta ptr2
    lda ptr3+1
    adc #0
    sta ptr2+1
    ldq currentFile
    jsr isQZero
    bne :+
    jmp checkExtras
:   jsr zeroFail
    lda #<msgAFile
    ldx #>msgAFile
    jmp failValue

HF: ldq currentFile
    jsr isQZero
    bne CX
    jsr zeroFail
    lda #<msgNoFile
    ldx #>msgNoFile
    jmp failValue

    ; Cursor X
CX: ldz #EDITFILE::cx
    nop
    lda (currentFile),z
    ldy #REC_CX
    jsr cmpByte
    beq CY
    lda #<msgCX
    ldx #>msgCX
    jmp failValue

    ; Cursor Y
CY: ldz #EDITFILE::cy
    ldy #REC_CY
    jsr cmpWord
    beq NL
    lda #<msgCY
    ldx #>msgCY
    jmp failValue

    ; numLines
NL: ldz #EDITFILE::numLines
    ldy #REC_NUMLINES
    jsr cmpWord
    beq LN
    lda #<msgNumLines
    ldx #>msgNumLines
    jmp failValue

    ; The lines. ptr1 is the line and ptr2 its expected text.
LN: ldy #REC_FLAGS
    lda (ptr3),y
    and #F_SKIPLINES
    beq :+
    clc                     ; The lines aren't checked (the count is 0)
    lda ptr3
    adc #REC_LINES
    sta ptr2
    lda ptr3+1
    adc #0
    sta ptr2+1
    jmp checkExtras
:   ldz #EDITFILE::firstLine
    neg
    neg
    nop
    lda (currentFile),z
    stq ptr1
    ldy #REC_COUNT
    lda (ptr3),y
    sta linesLeft
    clc
    lda ptr3
    adc #REC_LINES
    sta ptr2
    lda ptr3+1
    adc #0
    sta ptr2+1
    lda #0
    sta lineNum

L1: lda linesLeft
    beq LE
    ldq ptr1
    jsr isQZero
    bne :+
    ldy #REC_COUNT          ; The file has too few lines
    lda lineNum
    jsr cmpByte
    lda #<msgTooFew
    ldx #>msgTooFew
    jmp failValue

:   jsr copyLine
    jsr cmpLine
    bcc :+
    lda #FAIL_LINE
    sta failType
    lda ptr2
    sta failText
    lda ptr2+1
    sta failText+1
    sec
    rts

:   jsr skipText
    ldz #EDITLINE::next
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    inc lineNum
    dec linesLeft
    bra L1

    ; There must be no more lines
LE: ldq ptr1
    jsr isQZero
    bne :+
    jmp checkExtras
:   jsr zeroFail
    lda #<msgTooMany
    ldx #>msgTooMany
    jmp failValue
.endproc

; Clears failExp and failAct
.proc zeroFail
    lda #0
    sta failExp
    sta failExp+1
    sta failAct
    sta failAct+1
    rts
.endproc

; Moves ptr2 past the text it points to and its zero. Y is the text's
; length.
.proc skipText
    tya
    sec
    adc ptr2
    sta ptr2
    bcc :+
    inc ptr2+1
:   rts
.endproc

; Returns the next byte of the checks in A and moves ptr2 past it
.proc getChk
    ldy #0
    lda (ptr2),y
    inw ptr2
    cmp #0
    rts
.endproc

; Makes the checks that follow a test's lines. ptr2 points to them. The
; carry is clear if they all pass.
.proc checkExtras
    jsr getChk
    bne :+
    clc
    rts
:   inc chkNum
    cmp #CHK_LAST+1
    bcc :+
    jsr zeroFail
    lda #<msgBadCheck
    ldx #>msgBadCheck
    jmp failValue
:   asl a
    tax
    lda checkProcs-2,x
    sta ptr4
    lda checkProcs-1,x
    sta ptr4+1
    jsr callPtr4
    bcc checkExtras
    rts
.endproc

.proc callPtr4
    jmp (ptr4)
.endproc

; CHK_BYTE: a byte of the EDITFILE
.proc checkByte
    jsr getChk
    taz
    nop
    lda (currentFile),z
    sta failAct
    jsr getChk
    sta failExp
    lda #0
    sta failAct+1
    sta failExp+1
    jsr cmpFail
    beq OK
    lda #<msgByte
    ldx #>msgByte
    jmp failValue
OK: clc
    rts
.endproc

; CHK_WORD: a word of the EDITFILE
.proc checkWord
    jsr getChk
    taz
    nop
    lda (currentFile),z
    sta failAct
    inz
    nop
    lda (currentFile),z
    sta failAct+1
    jsr getChk
    sta failExp
    jsr getChk
    sta failExp+1
    jsr cmpFail
    beq OK
    lda #<msgWord
    ldx #>msgWord
    jmp failValue
OK: clc
    rts
.endproc

; Reads a line number from the checks into lineNum and points ptr1 at the
; line. If there is no such line, the carry is set and the check fails.
.proc findLine
    jsr getChk
    sta lineNum
    ldz #EDITFILE::firstLine
    neg
    neg
    nop
    lda (currentFile),z
    stq ptr1
    lda lineNum
    sta linesLeft           ; LDQ loads X too, so count in linesLeft
L1: ldq ptr1
    jsr isQZero
    bne :+
    jsr zeroFail
    lda #<msgNoLine
    ldx #>msgNoLine
    jmp failValue
:   lda linesLeft
    bne :+
    clc
    rts
:   ldz #EDITLINE::next
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    dec linesLeft
    bra L1
.endproc

; Fails a line check (FAIL_LINE): ptr2 is the expected text
.proc failLine
    lda #FAIL_LINE
    sta failType
    lda ptr2
    sta failText
    lda ptr2+1
    sta failText+1
    sec
    rts
.endproc

; CHK_LINE: the text of a line
.proc checkLine
    jsr findLine
    bcs DN
    jsr copyLine
    jsr cmpLine
    bcs failLine
    jmp skipTextOK
DN: rts
.endproc

; CHK_HL: the syntax highlighting of a line, as digits
.proc checkHL
    jsr findLine
    bcc L2
    rts

    ; Copy its highlighting into actualBuf as digits
L2: lda #0
    sta actualLen
    ldz #EDITLINE::syntaxHL
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr4
    jsr isQZero
    beq CM                  ; No highlighting
    ldz #EDITLINE::length
    nop
    lda (ptr1),z
    sta actualLen
    ldx #0
    ldz #0
:   cpx actualLen
    beq CM
    nop
    lda (ptr4),z
    clc
    adc #'0'
    sta actualBuf,x
    inx
    inz
    bra :-

CM: jsr cmpLine
    bcs failLine
    jmp skipTextOK
.endproc

; Moves ptr2 past its text (Y is its length) and clears the carry
.proc skipTextOK
    jsr skipText
    clc
    rts
.endproc

; CHK_NAME: the file's name
.proc checkName
    ldz #EDITFILE::filename
    ldx #0
:   nop
    lda (currentFile),z
    beq :+
    sta actualBuf,x
    inx
    inz
    cpx #17
    bne :-
:   stx actualLen
    jsr cmpLine
    lbcc skipTextOK
    lda #<msgName
    ldx #>msgName
    jmp failStr
.endproc

; CHK_FILES: the number of open files
.proc checkFiles
    jsr zeroFail
    ; firstFile is the first address in the overlay's state table
    jsr editorTestState
    sta ptr4
    stx ptr4+1
    ldy #0
    lda (ptr4),y
    tax
    iny
    lda (ptr4),y
    stx ptr4
    sta ptr4+1
    ldy #3
:   lda (ptr4),y
    sta ptr1,y
    dey
    bpl :-
    ldq ptr1
L1: stq ptr1
    jsr isQZero
    beq L2
    inc failAct
    ldz #EDITFILE::nextFile ; LDQ loads Z too
    neg
    neg
    nop
    lda (ptr1),z
    bra L1
L2: jsr getChk
    sta failExp
    jsr cmpFail
    beq OK
    lda #<msgFiles
    ldx #>msgFiles
    jmp failValue
OK: clc
    rts
.endproc

; CHK_SCREEN: text on the screen at a row and column
.proc checkScreen
    ; ptr4 = row * 80 (64 + 16) + column
    jsr getChk
    sta ptr4
    lda #0
    sta ptr4+1
    asl ptr4                ; * 16
    rol ptr4+1
    asl ptr4
    rol ptr4+1
    asl ptr4
    rol ptr4+1
    asl ptr4
    rol ptr4+1
    lda ptr4                ; Keep row * 16
    sta tmp1
    lda ptr4+1
    sta tmp2
    asl ptr4                ; * 64
    rol ptr4+1
    asl ptr4
    rol ptr4+1
    clc
    lda ptr4
    adc tmp1
    sta ptr4
    lda ptr4+1
    adc tmp2
    sta ptr4+1
    jsr getChk
    clc
    adc ptr4
    sta ptr4
    lda ptr4+1
    adc #0
    sta ptr4+1
    clc
    lda ptr4
    adc #<SCREEN25
    sta ptr4
    lda ptr4+1
    adc #>SCREEN25
    sta ptr4+1
    ; Copy as many characters as the expected text has, as PETSCII
    ldy #0
:   lda (ptr2),y
    beq :+
    lda (ptr4),y
    jsr screenToPetscii
    sta actualBuf,y
    iny
    bne :-
:   sty actualLen
    jsr cmpLine
    lbcc skipTextOK
    lda #<msgScreen
    ldx #>msgScreen
    jmp failStr
.endproc

; Converts the screen code in A to PETSCII. Reversed characters are shown
; as they are.
.proc screenToPetscii
    and #$7f
    cmp #$20
    bcs :+
    ora #$40                ; $00-$1f: @, a-z and so on
    rts
:   cmp #$40
    bcc DN                  ; $20-$3f: the same
    cmp #$60
    bcs :+
    ora #$80                ; $40-$5f: A-Z and so on
    rts
:   clc
    adc #$40                ; $60-$7f
DN: rts
.endproc

; Copies the filename at ptr2 to fnTmp and sets it with SETNAM, with ",s,r"
; after it if C is set. Moves ptr2 past the name.
.proc setFileName
    php
    ldy #0
:   lda (ptr2),y
    beq :+
    sta fnTmp,y
    iny
    bne :-
:   jsr skipText
    plp
    bcc DN
    ldx #0
:   lda strRead,x
    beq DN
    sta fnTmp,y
    iny
    inx
    bne :-
DN: tya
    ldx #<fnTmp
    ldy #>fnTmp
    jmp SETNAM
.endproc

; CHK_DISK: the contents of a file on the disk
.proc checkDisk
    sec
    jsr setFileName
    lda #2
    ldx DEVNUM
    ldy #2
    jsr SETLFS
    jsr OPEN
    ldx #2
    jsr CHKIN
    ldx #0
L1: phx
    jsr CHRIN
    plx
    pha
    jsr READST
    sta tmp1
    pla
    ldy tmp1
    beq :+
    cpy #$40
    bne L2                  ; An error: the byte isn't good
:   sta actualBuf,x
    inx
    lda tmp1
    bne L2                  ; The end of the file
    cpx #MAX_LINE_LENGTH
    bne L1
L2: stx actualLen
    lda #2
    jsr CLOSE
    jsr CLRCHN
    jsr cmpLine
    lbcc skipTextOK
    lda #<msgDisk
    ldx #>msgDisk
    jmp failStr
.endproc

; CHK_NOTONDISK: a file that must not be on the disk
.proc checkNotOnDisk
    ldy #0
:   lda (ptr2),y
    beq :+
    sta fnTmp,y
    iny
    bne :-
:   sta fnTmp,y
    jsr skipText
    lda ptr2                ; doesFileExist changes ptr2
    pha
    lda ptr2+1
    pha
    lda #<fnTmp
    ldx #>fnTmp
    ldy #0
    ldz #0
    jsr doesFileExist
    plx
    stx ptr2+1
    plx
    stx ptr2
    cmp #0                  ; Z is set if the file doesn't exist
    beq OK
    jsr zeroFail
    inc failAct
    lda #<msgOnDisk
    ldx #>msgOnDisk
    jmp failValue
OK: clc
    rts
.endproc

; CHK_LOOP: the code editorRun returned
.proc checkLoop
    jsr zeroFail
    lda loopCode
    sta failAct
    jsr getChk
    sta failExp
    jsr cmpFail
    beq OK
    lda #<msgLoop
    ldx #>msgLoop
    jmp failValue
OK: clc
    rts
.endproc

; CHK_COMPILEFN: the filename editorRun returned
.proc checkCompileFn
    lda compileFn
    sta ptr4
    lda compileFn+1
    sta ptr4+1
    ldy #0
:   lda (ptr4),y
    beq :+
    sta actualBuf,y
    iny
    cpy #MAX_LINE_LENGTH
    bne :-
:   sty actualLen
    jsr cmpLine
    lbcc skipTextOK
    lda #<msgCompileFn
    ldx #>msgCompileFn
    jmp failStr
.endproc

; Copies the line at ptr1 into actualBuf (up to MAX_LINE_LENGTH bytes) and
; its length into actualLen.
.proc copyLine
    ldz #EDITLINE::length
    nop
    lda (ptr1),z
    sta actualLen
    beq DN
    ldz #EDITLINE::buffer
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr4
    ldx #0
    ldz #0
:   nop
    lda (ptr4),z
    sta actualBuf,x
    inz
    inx
    cpx actualLen
    beq DN
    cpx #MAX_LINE_LENGTH
    bne :-
DN: rts
.endproc

; Compares actualBuf to the expected text at ptr2. The carry is set if they
; differ. If they are the same Y is the length of the text.
.proc cmpLine
    ldy #0
L1: lda (ptr2),y
    beq L2
    cpy actualLen
    beq NE                  ; The line is shorter
    cmp actualBuf,y
    bne NE
    iny
    bra L1
L2: cpy actualLen
    bne NE                  ; The line is longer
    clc
    rts
NE: sec
    rts
.endproc

.proc printFailure
    jsr printTestName
    lda chkNum
    beq :+
    lda #<strCheck
    ldx #>strCheck
    jsr printStr
    lda chkNum
    jsr printHex
    lda #<strColon
    ldx #>strColon
    jsr printStr
:   lda failType
    cmp #FAIL_VALUE
    bne LT
    lda failMsg
    ldx failMsg+1
    jsr printStr
    lda #<strExpected
    ldx #>strExpected
    jsr printStr
    lda failExp+1
    jsr printHex
    lda failExp
    jsr printHex
    lda #<strGot
    ldx #>strGot
    jsr printStr
    lda failAct+1
    jsr printHex
    lda failAct
    jsr printHex
    lda #13
    jmp CHROUT

    ; Text differs
LT: cmp #FAIL_LINE
    bne :+
    lda #<strLine
    ldx #>strLine
    jsr printStr
    lda lineNum
    jsr printHex
    bra :++
:   lda failMsg
    ldx failMsg+1
    jsr printStr
:   lda #<strExpText
    ldx #>strExpText
    jsr printStr
    lda failText
    sta ptr4
    lda failText+1
    sta ptr4+1
    ldy #0
:   lda (ptr4),y
    beq :+
    jsr printSafe
    iny
    bne :-
:   lda #<strActText
    ldx #>strActText
    jsr printStr
    ldx #0
:   cpx actualLen
    beq :+
    cpx #MAX_LINE_LENGTH
    beq :+
    lda actualBuf,x
    jsr printSafe
    inx
    bra :-
:   lda #13
    jmp CHROUT
.endproc

; Prints "test <name>: "
.proc printTestName
    lda #<strTest
    ldx #>strTest
    jsr printStr
    jsr loadRec
    ldy #REC_NAME+1
    lda (ptr3),y
    tax
    dey
    lda (ptr3),y
    jsr printStr
    lda #<strColon
    ldx #>strColon
    jmp printStr
.endproc

; A BRK during a test ends up here (see brkCatch in testresult.s)
.proc onBrk
    lda #0
    sta brkCatch
    sta brkCatch+1
    jsr restoreZeroPage
    jsr clearScreen
    jsr printTestName
    lda #<strBrk
    ldx #>strBrk
    jsr printStr
    lda brkCode
    jsr printHex
    lda phase
    asl a
    tax
    lda strPhase+1,x
    pha
    lda strPhase,x
    plx
    jsr printStr
    jmp testFail
.endproc

; A runtime error ends up here (see exitHandler)
.proc runtimeErr
    lda zpSaved
    beq :+
    jsr restoreZeroPage
    jsr clearScreen
:   lda #<strRuntime
    ldx #>strRuntime
    jsr printStr
    lda testNum
    beq :+
    jsr printTestName
:   jmp testFail
.endproc

; Clears the editor's screen and leaves the cursor on row 4. testPass and
; testFail print the result on row 0, and BASIC's READY and cursor follow.
.proc clearScreen
    lda #CH_CLRSCR
    jsr CHROUT
    lda #13
    jsr CHROUT
    jsr CHROUT
    jsr CHROUT
    jmp CHROUT
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

; Prints the character in A, or a "." if it is a control code. A line that
; has been written over can hold anything.
.proc printSafe
    cmp #$20
    bcc DOT
    cmp #$80
    bcc PR
    cmp #$a0
    bcs PR
DOT:
    lda #'.'
PR: jmp CHROUT
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
