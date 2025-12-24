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

.include "c64.inc"
.include "error.inc"
.include "asmlib.inc"
.include "parser.inc"
.include "dumpast.inc"
.include "zeropage.inc"
.include "tokenizer.inc"
.include "cbm_kernal.inc"
.include "4510macros.inc"

NUM_TESTS = 12

.export runErrorTests

.import initTokenizer, initParser, getKey
.import errorCount, errorLine, errorNum
.import heapWalk

.bss

testNum: .res 2
sourceFn: .res 16
intBuf: .res 10
tokens: .res 4
astRoot: .res 4
pErrors: .res 2         ; Pointer to current test in "errors"
.data

strFnPrefix: .asciiz "error"
strFnSuffix: .asciiz ".pas"
strTitle: .asciiz "Running error test "
strTokenizing: .asciiz " : Tokenizing, "
strParsing: .asciiz "Parsing, "
strPass: .asciiz "Pass"
strErrorCount: .asciiz "Expected one error - press a key"
strErrorLine1: .asciiz "Error reported in line "
strErrorLine2: .asciiz ", expected line "
strErrorNum1: .asciiz "Error number "
strErrorNum2: .asciiz ", expected num "

; Array of parser errors by test number (zero-based)
;   Each element is three bytes:
;      1) Line number (low byte)
;      2) Line number (high byte)
;      3) Error code
errors: .byte $06, $00, errMissingIdentifier        ; Missing identifier after Program
        .byte $09, $00, errMissingRightParen        ; Missing right paren on routine call
        .byte $09, $00, errUnexpectedToken          ; Unexpected token in array literal
        .byte $0c, $00, errMissingIMPLEMENTATION    ; Missing Implementation in unit
        .byte $08, $00, errMissingBEGIN             ; Missing Begin
        .byte $0b, $00, errMissingConstant          ; Missing contant parsing case branch
        .byte $0b, $00, errInvalidConstant          ; Invalid constant parsing case branch
        .byte $09, $00, errInvalidConstant          ; Invalid constant parsing constant declarations
        .byte $09, $00, errInvalidConstant          ; Invalid constant parsing string constant
        .byte $09, $00, errMissingComma             ; Missing comma parsing enumeration
        .byte $09, $00, errMissingIdentifier        ; Missing identifier parsing enumeration
        .byte $09, $00, errInvalidExpression        ; Invalid expression
        .byte $09, $00, errMissingRightParen        ; Missing right paren in array literal

.code

.proc runErrorTests
    ; jsr heapWalk
    
    ; Start with test 1
    lda #1
    sta testNum
    lda #0
    sta testNum+1

    ; Initialize pErrors
    lda #<errors
    sta pErrors
    lda #>errors
    sta pErrors+1

L1: jsr runErrorTest
    ; jsr heapWalk

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

L3: rts
.endproc

; This routine runs a parser test. The test number is in A/X.
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
    lda #0
    tax
    tay
    taz
    jsr setParserUnitsList
    ldq tokens
    jsr parse
    stq astRoot

    ; Free the tokens
    ldq tokens
    jsr freeMemBuf

    ; Free the AST
    ldq astRoot
    jsr astFree

    ; Check the error information
    lda pErrors
    sta ptr2
    lda pErrors+1
    sta ptr2+1
    lda errorCount
    cmp #1
    beq :+
    jsr unexpectedErrorCount
    bra DN

    ; Check error line
:   ldy #0
    lda (ptr2),y
    cmp errorLine
    beq :+
    jsr unexpectedErrorLine
    bra DN
:   iny
    lda (ptr2),y
    cmp errorLine+1
    beq :+
    jsr unexpectedErrorLine
    bra DN

    ; Check error number
:   iny
    lda (ptr2),y
    cmp errorNum
    beq :+
    jsr unexpectedErrorNum
    bra DN

:   lda #<strPass
    ldx #>strPass
    jsr printLine

DN: lda #13
    jsr CHROUT

    rts
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

.proc unexpectedErrorCount
    lda #<strErrorCount
    ldx #>strErrorCount
    jsr printLine
    lda #13
    jsr CHROUT
    jsr getKey
    rts
.endproc

.proc unexpectedErrorLine
    lda #13
    jsr CHROUT
    jsr CHROUT

    lda #<strErrorLine1
    ldx #>strErrorLine1
    jsr printLine
    lda errorLine
    sta intOp1
    lda errorLine+1
    sta intOp1+1
    lda #<intBuf
    ldx #>intBuf
    jsr writeInt16
    lda #<intBuf
    ldx #>intBuf
    jsr printLine

    lda pErrors
    sta ptr2
    lda pErrors+1
    sta ptr2+1
    lda #<strErrorLine2
    ldx #>strErrorLine2
    jsr printLine
    ldy #0
    lda (ptr2),y
    sta intOp1
    iny
    lda (ptr2),y
    sta intOp1+1
    lda #<intBuf
    ldx #>intBuf
    jsr writeInt16
    lda #<intBuf
    ldx #>intBuf
    jsr printLine
    lda #13
    jsr CHROUT
    jsr getKey
    rts
.endproc

.proc unexpectedErrorNum
    lda #13
    jsr CHROUT
    jsr CHROUT

    lda #<strErrorNum1
    ldx #>strErrorNum1
    jsr printLine
    lda errorNum
    sta intOp1
    lda #0
    sta intOp1+1
    lda #<intBuf
    ldx #>intBuf
    jsr writeInt16
    lda #<intBuf
    ldx #>intBuf
    jsr printLine

    lda pErrors
    sta ptr2
    lda pErrors+1
    sta ptr2+1
    lda #<strErrorNum2
    ldx #>strErrorNum2
    jsr printLine
    ldy #2
    lda (ptr2),y
    sta intOp1
    lda #0
    sta intOp1+1
    lda #<intBuf
    ldx #>intBuf
    jsr writeInt16
    lda #<intBuf
    ldx #>intBuf
    jsr printLine
    lda #13
    jsr CHROUT
    jsr getKey
    rts
.endproc
