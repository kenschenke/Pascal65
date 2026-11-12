;
; runerrortests.s
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Routines to test the parser error handling. This is done by running
; the parser and capturing errors.
;
; Each test, errorN.pas, names the first error the parser must report and
; its line. A test that gets a different error, or none, doesn't stop the
; others. Its number is listed once all of them have run, and
; runErrorTests returns with the carry set. A test that makes the parser
; hang never finishes: the emulator is stopped before it can save the
; screen, so run the tests in parts to find it (see the Makefile).

.include "c64.inc"
.include "error.inc"
.include "asmlib.inc"
.include "parser.inc"
.include "dumpast.inc"
.include "zeropage.inc"
.include "tokenizer.inc"
.include "cbm_kernal.inc"
.include "4510macros.inc"

.export runErrorTests

.import initTokenizer, initParser
.import errorCount, errorLine, errorNum
.import freeUnits, unitList

MAX_FAILURES = 20           ; The most failed tests listed at the end

.bss

testNum: .res 2
sourceFn: .res 16
intBuf: .res 10
tokens: .res 4
astRoot: .res 4
pErrors: .res 2         ; Pointer to current test in "errors"
failCount: .res 1       ; Number of tests that failed
failList: .res MAX_FAILURES * 2

.data

strFnPrefix: .asciiz "error"
strFnSuffix: .asciiz ".pas"
strTitle: .asciiz "Running error test "
strTokenizing: .asciiz " : Tokenizing, "
strParsing: .asciiz "Parsing, "
strPass: .asciiz "Pass"
strNoError: .asciiz "  FAIL: no error reported"
strGot: .asciiz "  FAIL: error "
strExpected: .asciiz ", expected error "
strLine: .asciiz " line "
strFailed: .asciiz "Error tests failed:"

; The expected errors, by test number (errortests.inc, made by
; mkerrortests.py from the tests' header comments). Each element is
; three bytes:
;      1) Line number (low byte)
;      2) Line number (high byte)
;      3) Error code
.include "errortests.inc"

; Only some of the tests can be run, to find one that hangs:
; make test ERRTESTS="-D FIRST_ERROR_TEST=n -D LAST_ERROR_TEST=m"
.ifndef FIRST_ERROR_TEST
FIRST_ERROR_TEST = 1
.endif
.ifndef LAST_ERROR_TEST
LAST_ERROR_TEST = NUM_ERROR_TESTS
.endif

.code

.proc runErrorTests
    lda #0
    sta failCount

    lda #.LOBYTE(FIRST_ERROR_TEST)
    sta testNum
    lda #.HIBYTE(FIRST_ERROR_TEST)
    sta testNum+1

    ; Initialize pErrors
    lda #.LOBYTE(errors + (FIRST_ERROR_TEST - 1) * 3)
    sta pErrors
    lda #.HIBYTE(errors + (FIRST_ERROR_TEST - 1) * 3)
    sta pErrors+1

L1: jsr runErrorTest

    lda testNum
    cmp #.LOBYTE(LAST_ERROR_TEST)
    bne L2
    lda testNum+1
    cmp #.HIBYTE(LAST_ERROR_TEST)
    beq L3

L2: lda pErrors
    clc
    adc #3
    sta pErrors
    lda pErrors+1
    adc #0
    sta pErrors+1

    inc testNum
    bne L1
    inc testNum+1
    bra L1

L3: lda failCount
    bne :+
    clc
    rts
:   jsr listFailures
    sec
    rts
.endproc

; This routine runs the parser test numbered testNum.
.proc runErrorTest
    lda testNum
    sta intOp1
    lda testNum+1
    sta intOp1+1

    ; Reset error info
    lda #0
    sta errorCount
    sta errorLine
    sta errorLine+1
    sta errorNum

    ; Print the "running" title
    lda #<strTitle
    ldx #>strTitle
    jsr printLine

    lda #<intBuf
    ldx #>intBuf
    jsr writeInt16
    lda #<intBuf
    ldx #>intBuf
    jsr printLine

    ; Format the filename for the tokenizer
    jsr makeSourceFn

    ; Tokenize the source file
    lda #<strTokenizing
    ldx #>strTokenizing
    jsr printLine
    jsr initTokenizer
    lda #<sourceFn
    ldx #>sourceFn
    jsr tokenize
    stq tokens

    ; Parse the tokens
    lda #<strParsing
    ldx #>strParsing
    jsr printLine
    jsr initParser
    jsr parserInit
    lda #0
    tax
    tay
    taz
    stq unitList
    jsr setParserUnitsList
    ldq tokens
    jsr parse
    stq astRoot
    jsr getParserUnitsList
    stq unitList

    ; Free the tokens
    ldq tokens
    jsr freeMemBuf

    ; Free the AST
    ldq astRoot
    jsr astFree

    ; Free the units the parser added (the System unit)
    jsr freeUnits

    ; Check the error information
    lda pErrors
    sta ptr2
    lda pErrors+1
    sta ptr2+1
    lda errorCount
    beq FL
    ldy #0
    lda (ptr2),y
    cmp errorLine
    bne FL
    iny
    lda (ptr2),y
    cmp errorLine+1
    bne FL
    iny
    lda (ptr2),y
    cmp errorNum
    bne FL

    lda #<strPass
    ldx #>strPass
    jsr printLine
    lda #13
    jmp CHROUT

FL: jmp failed
.endproc

; This routine reports the error the test got and the one it expected,
; and adds the test to the failure list.
.proc failed
    lda #13
    jsr CHROUT

    lda errorCount
    bne :+
    lda #<strNoError
    ldx #>strNoError
    jsr printLine
    bra L1

:   lda #<strGot
    ldx #>strGot
    jsr printLine
    lda errorNum
    ldx errorLine
    ldy errorLine+1
    jsr printErrorAndLine

L1: lda #<strExpected
    ldx #>strExpected
    jsr printLine
    lda pErrors
    sta ptr2
    lda pErrors+1
    sta ptr2+1
    ldy #2
    lda (ptr2),y
    pha
    dey
    lda (ptr2),y
    tax                     ; Line high byte
    dey
    lda (ptr2),y
    sta tmp1                ; Line low byte
    txa
    tay
    ldx tmp1
    pla
    jsr printErrorAndLine
    lda #13
    jsr CHROUT

    ; Add the test to the list
    lda failCount
    cmp #MAX_FAILURES
    bcs :+
    asl a
    tax
    lda testNum
    sta failList,x
    lda testNum+1
    sta failList+1,x
:   inc failCount
    rts
.endproc

; This routine prints an error number and line number.
; Inputs:
;    A - error number
;    X - line number low byte
;    Y - line number high byte
.proc printErrorAndLine
    phy
    phx
    sta intOp1
    lda #0
    sta intOp1+1
    jsr printInt
    lda #<strLine
    ldx #>strLine
    jsr printLine
    pla
    sta intOp1
    pla
    sta intOp1+1
    jmp printInt
.endproc

; This routine prints the number in intOp1.
.proc printInt
    lda #<intBuf
    ldx #>intBuf
    jsr writeInt16
    lda #<intBuf
    ldx #>intBuf
    jmp printLine
.endproc

; This routine lists the tests that failed.
.proc listFailures
    lda #<strFailed
    ldx #>strFailed
    jsr printLine
    ldx #0
L1: cpx failCount
    beq L2
    cpx #MAX_FAILURES
    beq L2
    phx
    lda #' '
    jsr CHROUT
    pla
    pha
    asl a
    tax
    lda failList,x
    sta intOp1
    lda failList+1,x
    sta intOp1+1
    jsr printInt
    plx
    inx
    bra L1
L2: lda #13
    jmp CHROUT
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

; This routine formats the source filename using the test number.
; The format is errorXXXX.pas and the buffer is null-terminated.
.proc makeSourceFn
    ; Copy the prefix
    ldx #0
:   lda strFnPrefix,x
    beq :+
    sta sourceFn,x
    inx
    bne :-
:   phx                 ; Save the sourceFn index
    ; Format the test number in PETSCII
    lda testNum
    sta intOp1
    lda testNum+1
    sta intOp1+1
    lda #<intBuf
    ldx #>intBuf
    jsr writeInt16
    ; Copy the test number into the filename
    plx
    ldy #0
:   lda intBuf,y
    beq :+
    sta sourceFn,x
    inx
    iny
    bne :-
:   ldy #0              ; Copy the suffix
:   lda strFnSuffix,y
    beq :+
    sta sourceFn,x
    inx
    iny
    bne :-
:   ; Null-terminate the filename
    lda #0
    sta sourceFn,x
    rts
.endproc
