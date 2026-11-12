;
; rundirtest.s
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; runDirTest routine
;
; This test checks the compiler directives the parser keeps for the
; compiler. It parses dirs.pas with handlers registered for $ExpectWarn
; and $ExpectError, then checks the stack size from $StackSize, the
; runtime mode from $StaticRuntime and what each handler was called with.

.include "asmlib.inc"
.include "asm.inc"
.include "parser.inc"
.include "zeropage.inc"
.include "tokenizer.inc"
.include "cbm_kernal.inc"
.include "4510macros.inc"

.export runDirTest

.import testFail, initTokenizer, initParser, printLine
.import freeUnits, unitList, errorCount

STACK_SIZE = 1000           ; $StackSize in dirs.pas
WARN_NUM = 66               ; $ExpectWarn in dirs.pas, and its line
WARN_LINE = 10
ERROR_NUM = 35              ; $ExpectError in dirs.pas, and its line
ERROR_LINE = 11

.data

strFn: .asciiz "dirs.pas"
strTitle: .asciiz "Running directive test : "
strParseError: .asciiz "Parse error"
strStackSize: .asciiz "Wrong stack size"
strRuntimeMode: .asciiz "Wrong runtime mode"
strWarn: .asciiz "Wrong $ExpectWarn call"
strError: .asciiz "Wrong $ExpectError call"
strPass: .asciiz "Pass"

.bss

tokens: .res 4
astRoot: .res 4
; What each handler was called with, and how many times
warnCount: .res 1
warnNum: .res 1
warnLine: .res 2
errCount: .res 1
errNum: .res 1
errLine: .res 2

.code

.proc runDirTest
    lda #<strTitle
    ldx #>strTitle
    jsr printLine

    lda #0
    sta errorCount
    sta warnCount
    sta errCount

    ; Tokenize and parse dirs.pas
    jsr initTokenizer
    lda #<strFn
    ldx #>strFn
    jsr tokenize
    stq tokens
    jsr initParser
    jsr parserInit
    lda #<onWarn
    ldx #>onWarn
    jsr registerExpectWarnHandler
    lda #<onError
    ldx #>onError
    jsr registerExpectErrorHandler
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
    ldq tokens
    jsr freeMemBuf

    lda errorCount
    beq :+
    lda #<strParseError
    ldx #>strParseError
    jmp fail

:   jsr getParserStackSize
    cmp #<STACK_SIZE
    bne :+
    cpx #>STACK_SIZE
    beq :++
:   lda #<strStackSize
    ldx #>strStackSize
    jmp fail

:   jsr getParserRuntimeMode
    cmp #RT_MODE_STATIC
    beq :+
    lda #<strRuntimeMode
    ldx #>strRuntimeMode
    jmp fail

:   lda warnCount
    cmp #1
    bne :+
    lda warnNum
    cmp #WARN_NUM
    bne :+
    lda warnLine
    cmp #<WARN_LINE
    bne :+
    lda warnLine+1
    cmp #>WARN_LINE
    beq :++
:   lda #<strWarn
    ldx #>strWarn
    jmp fail

:   lda errCount
    cmp #1
    bne :+
    lda errNum
    cmp #ERROR_NUM
    bne :+
    lda errLine
    cmp #<ERROR_LINE
    bne :+
    lda errLine+1
    cmp #>ERROR_LINE
    beq :++
:   lda #<strError
    ldx #>strError
    jmp fail

:   ldq astRoot
    jsr astFree
    jsr freeUnits

    lda #<strPass
    ldx #>strPass
    jsr printLine
    lda #13
    jmp CHROUT
.endproc

; The $ExpectWarn handler: the number in A and the line in X/Y
.proc onWarn
    sta warnNum
    stx warnLine
    sty warnLine+1
    inc warnCount
    rts
.endproc

; The $ExpectError handler: the number in A and the line in X/Y
.proc onError
    sta errNum
    stx errLine
    sty errLine+1
    inc errCount
    rts
.endproc

; This routine prints the message in A/X and fails the test.
.proc fail
    jsr printLine
    lda #13
    jsr CHROUT
    jmp testFail
.endproc
