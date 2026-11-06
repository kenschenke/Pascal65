;
; runerrortests.s
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Routines to test the resolver error handling. Each test, errorN.pas,
; is parsed and resolved. It must report exactly one error, the one in
; the errors table below, on the line in the table.
;
; The $ExpectError directive can't be used here. The parser only sees
; it where a statement can go, and these errors are in declarations.

.include "ast.inc"
.include "error.inc"
.include "asmlib.inc"
.include "parser.inc"
.include "zeropage.inc"
.include "resolver.inc"
.include "tokenizer.inc"
.include "cbm_kernal.inc"
.include "4510macros.inc"

NUM_TESTS = 7

.export runErrorTests
.import testFail

.import initTokenizer, initParser, initResolver, printLine, logError
.import unitList, tokenizeAndParseUnits, freeUnits

.bss

testNum: .res 2
sourceFn: .res 16
intBuf: .res 14
tokens: .res 4
astRoot: .res 4
errorCount: .res 1
errorNum: .res 1
errorLine: .res 2
pErrors: .res 2         ; Pointer to current test in "errors"

.data

; Expected error for each test, starting with test 1.
;   Each element is three bytes:
;      1) Line number (low byte)
;      2) Line number (high byte)
;      3) Error code
errors: .byte $0c, $00, errMultiDimDynArray     ; Array of a dynamic type
        .byte $0b, $00, errDynArrayInRecord     ; Dynamic type record field
        .byte $0b, $00, errMultiDimDynArray     ; Dynamic array of array type
        .byte $0b, $00, errMultiDimDynArray     ; Nested array of dynamic type
        .byte $0c, $00, errDynArrayInRecord     ; Anonymous record field
        .byte $0c, $00, errDynArrayInRecord     ; Record in array element
        .byte $0b, $00, errDynArrayInRecord     ; Record in dynamic array

strFnPrefix: .asciiz "error"
strFnSuffix: .asciiz ".pas"
strRunning: .asciiz "Running resolver error tests"
strTitle: .asciiz "Running error test "
strTokenizing: .asciiz " : Tokenizing, "
strParsing: .asciiz "Parsing, "
strResolving: .asciiz "Resolving, "
strErrorCount: .asciiz "Expected one error, got "
strErrorLine: .asciiz "Error reported in line "
strErrorNum: .asciiz "Error number "
strExpected: .asciiz ", expected "
strPass: .asciiz "Pass"

.code

.proc runErrorTests
    lda #<logTestError
    ldx #>logTestError
    jsr initCompilerErrors

    lda #13
    jsr CHROUT
    lda #<strRunning
    ldx #>strRunning
    jsr printLine
    lda #13
    jsr CHROUT

    ; Start with test 1
    lda #1
    sta testNum
    lda #0
    sta testNum+1
    lda #<errors
    sta pErrors
    lda #>errors
    sta pErrors+1

L1: jsr runErrorTest

    lda testNum
    cmp #.LOBYTE(NUM_TESTS)
    bne L2
    lda testNum+1
    cmp #.HIBYTE(NUM_TESTS)
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

    ; Put back the error handler the other tests use
L3: lda #<logError
    ldx #>logError
    jmp initCompilerErrors
.endproc

; This routine runs the resolver error test in testNum.
.proc runErrorTest
    lda #0
    sta errorCount
    sta errorNum
    sta errorLine
    sta errorLine+1

    ; Clear the unit list
    lda #0
    tax
    tay
    taz
    stq unitList

    ; Print the "running" title
    lda #<strTitle
    ldx #>strTitle
    jsr printLine
    lda testNum
    sta intOp1
    lda testNum+1
    sta intOp1+1
    jsr printInt

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
    ldq unitList
    jsr setParserUnitsList
    ldq tokens
    jsr parse
    stq astRoot
    jsr getParserUnitsList
    stq unitList

    ; Free the tokens
    ldq tokens
    jsr freeMemBuf

    jsr tokenizeAndParseUnits

    ; Resolve
    lda #<strResolving
    ldx #>strResolving
    jsr printLine
    jsr initResolver
    ldq unitList
    jsr setResolverUnitsList
    jsr initScopeStack
    jsr injectSystemUnit

    ldq astRoot
    jsr pushQ
    jsr pushQZero
    jsr declResolve

    ; Free the PROGRAM scope symbol table
    jsr scopeExit
    jsr heapFree

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

    ldq astRoot
    jsr astFree
    jsr freeUnits

    jmp checkError
.endproc

; This routine checks the error the test reported against the table.
.proc checkError
    lda pErrors
    sta ptr2
    lda pErrors+1
    sta ptr2+1

    lda errorCount
    cmp #1
    beq L1
    lda #<strErrorCount
    ldx #>strErrorCount
    jsr printLine
    lda errorCount
    sta intOp1
    lda #0
    sta intOp1+1
    jsr printInt
    jmp Fail

L1: ldy #0
    lda (ptr2),y
    cmp errorLine
    bne L2
    iny
    lda (ptr2),y
    cmp errorLine+1
    beq L3
L2: lda #<strErrorLine
    ldx #>strErrorLine
    jsr printLine
    lda errorLine
    sta intOp1
    lda errorLine+1
    sta intOp1+1
    jsr printInt
    lda #<strExpected
    ldx #>strExpected
    jsr printLine
    ldy #0
    lda (ptr2),y
    sta intOp1
    iny
    lda (ptr2),y
    sta intOp1+1
    jsr printInt
    jmp Fail

L3: ldy #2
    lda (ptr2),y
    cmp errorNum
    beq L4
    lda #<strErrorNum
    ldx #>strErrorNum
    jsr printLine
    lda errorNum
    sta intOp1
    lda #0
    sta intOp1+1
    jsr printInt
    lda #<strExpected
    ldx #>strExpected
    jsr printLine
    ldy #2
    lda (ptr2),y
    sta intOp1
    lda #0
    sta intOp1+1
    jsr printInt
    jmp Fail

L4: lda #<strPass
    ldx #>strPass
    jsr printLine
    lda #13
    jmp CHROUT

Fail:
    lda #13
    jsr CHROUT
    jmp testFail
.endproc

; This routine prints the 16-bit value in intOp1.
.proc printInt
    lda #<intBuf
    ldx #>intBuf
    jsr writeInt16
    lda #<intBuf
    ldx #>intBuf
    jmp printLine
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

; This routine is called when the compiler reports an error. It counts
; the errors and keeps the first one.
; Inputs:
;    A - low byte of line number
;    X - high byte of line number
;    Y - error number
.proc logTestError
    ; Ignore this error. It happens because the tests are not resolving the
    ; system unit for each test.
    cpy #errMissingUnitDeclaration
    beq L1

    ldz errorCount
    bne :+
    sta errorLine
    stx errorLine+1
    sty errorNum
:   inc errorCount

    ; Discard the message from the runtime stack
L1: jmp popQ
.endproc
