;
; runerrortest.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;

.include "ast.inc"
.include "error.inc"
.include "asmlib.inc"
.include "parser.inc"
.include "zeropage.inc"
.include "resolver.inc"
.include "tokenizer.inc"
.include "typecheck.inc"
.include "cbm_kernal.inc"
.include "4510macros.inc"

.import testFail
.export runErrorTest, logExpectedWarning, logExpectedError
.export registerExpectHandlers

MAX_EXPECTED_ERRORS = 64
MAX_FILES = 4                   ; source files in one test
FILE_SLOT = 17                  ; a CBM filename and a null
SEEN = $80                      ; flag bit in an expected block

.import initTokenizer, initParser, getKey
.import initResolver, initTypeCheck, printLine
.import unitList, tokenizeAndParseUnits, freeUnits

.bss

testNum: .res 2
sourceFn: .res 16
intBuf: .res 14
tokens: .res 4
astRoot: .res 4
numExpectedErrors: .res 1
expectedErrors: .res MAX_EXPECTED_ERRORS * 4
numExpectedWarnings: .res 1
expectedWarnings: .res MAX_EXPECTED_ERRORS * 4
expectedIndex: .res 1
expectedNumber: .res 1
lineNumber: .res 2
pauseForErrors: .res 1
numExpected: .res 1
numFiles: .res 1                ; filenames in fileTable
fileTable: .res MAX_FILES * FILE_SLOT
fileNum: .res 1
fileOffset: .res 1
alreadySeen: .res 1             ; recordExpected matched a seen expectation

; expectedErrors and expectedWarnings are an array of blocks, four bytes each.
;   expected error code (1 byte)
;   expected error line (2 bytes)
;   flags (1 byte): bit 7 (SEEN) is set once the error is seen. Bits 0-6
;     are the index in fileTable of the file the expectation is in. An
;     error only matches if it is reported in that file.

.data

; Non-zero while an error test parses (see registerExpectHandlers). It's
; data rather than BSS so it starts out zero for the other tests.
inErrorTest: .byte 0
strFnPrefix: .asciiz "error"
strFnSuffix: .asciiz ".pas"
strTitle: .asciiz "Running test "
strTokenizing: .asciiz " : Tokenizing, "
strParsing: .asciiz "Parsing, "
strResolving: .asciiz "Resolving, "
strTypeChecking: .asciiz "Type Checking, "
strMaxExpected: .asciiz "Maximum expected errors/warnings exceeded"
strMaxFiles: .asciiz "Too many source files"
strErrorCount: .asciiz "Errors encountered - press a key"
strUnexpected: .asciiz "Unexpected error or warning encountered "
strAlreadyEnountered: .asciiz "Already encountered error or warning "
strExpected: .asciiz "Did not encounter expected error or warning "
strLineNumber: .asciiz ", Line "
strFile: .asciiz ", File "
strPause: .asciiz "Press a key..."
strPass: .asciiz "Pass"

.code

; This routine runs a typecheck error test. The test number is in A/X.
.proc runErrorTest
    sta testNum
    sta intOp1
    stx testNum+1
    stx intOp1+1

    lda #0
    sta pauseForErrors

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

    ; Set up the expected warnings list
    lda #0
    sta numExpectedErrors
    sta numExpectedWarnings
    sta numFiles
    lda #1
    sta inErrorTest
    jsr registerExpectHandlers

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
    lda #0
    sta inErrorTest

    lda #<strResolving
    ldx #>strResolving
    jsr printLine
    jsr initResolver
    ldq unitList
    jsr setResolverUnitsList
    jsr initScopeStack
    jsr initStandardRoutines
    jsr injectSystemUnit
    ; Resolve the System unit so tests can call its routines (Length)
    jsr resolveUnits

    ; resolveUnits reports errors in each unit's file, as the compiler
    ; does. The rest are in the program's.
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
    jsr setUnitOffsets
    ldq astRoot
    jsr fixGlobalOffsets
    ldq astRoot
    jsr verifyFwdDeclarations
    jsr getResolverUnitsList
    stq unitList

    lda #<strTypeChecking
    ldx #>strTypeChecking
    jsr printLine
    jsr initTypeCheck
    ldq astRoot
    jsr declTypeCheck
    ldq unitList
    jsr typeCheckUnits

    ; Free the PROGRAM scope symbol table
    jsr scopeExit
    jsr freeSymtab

    ldq astRoot
    jsr astFree

    jsr freeUnits

    jsr verifyExpectedWarnings
    jsr verifyExpectedErrors

    lda pauseForErrors
    beq :+

    jmp testFail

:   lda #<strPass
    ldx #>strPass
    jsr printLine
    lda #13
    jsr CHROUT

    rts
.endproc

; This routine gives the parser the $ExpectWarn and $ExpectError handlers
; while an error test is parsing. tokenizeAndParseUnits calls it after
; parserInit, which clears them, so a unit's directives are recorded too.
.proc registerExpectHandlers
    lda inErrorTest
    beq :+
    lda #<expectedWarnHandler
    ldx #>expectedWarnHandler
    jsr registerExpectWarnHandler
    lda #<expectedErrorHandler
    ldx #>expectedErrorHandler
    jsr registerExpectErrorHandler
:   rts
.endproc

; This routine formats the source filename using the test number.
; The format is testXXXX.pas and the buffer is null-terminated.
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

; This routine is called when the parser encounters a $ExpectWarn
; directive in the source code.
;
; Inputs:
;    A - the warning code
;    X - low byte of line number
;    Y - high byte of line number
.proc expectedWarnHandler
    ; Store the inputs while we set up the pointer to the next slot in expectedWarnings array
    sta expectedNumber
    stx lineNumber
    sty lineNumber+1
    jsr currentFileIndex

    lda numExpectedWarnings
    cmp #MAX_EXPECTED_ERRORS
    bne :+
    lda #<strMaxExpected
    ldx #>strMaxExpected
    jsr printLine
    lda #13
    jsr CHROUT
    jmp testFail

:   asl a
    asl a
    tax

    ; Store the warning code and line number in the next slot
    lda expectedNumber
    sta expectedWarnings,x
    inx
    lda lineNumber
    sta expectedWarnings,x
    inx
    lda lineNumber+1
    sta expectedWarnings,x
    inx
    lda fileNum                 ; not seen yet, in this file
    sta expectedWarnings,x
    inc numExpectedWarnings

    rts
.endproc

; This routine is called when the parser encounters a $ExpectError
; directive in the source code.
;
; Inputs:
;    A - the error code
;    X - low byte of line number
;    Y - high byte of line number
.proc expectedErrorHandler
    ; Store the inputs while we set up the pointer to the next slot in expectedErrors array
    sta expectedNumber
    stx lineNumber
    sty lineNumber+1
    jsr currentFileIndex

    lda numExpectedErrors
    cmp #MAX_EXPECTED_ERRORS
    bne :+
    lda #<strMaxExpected
    ldx #>strMaxExpected
    jsr printLine
    lda #13
    jsr CHROUT
    jmp testFail

:   asl a
    asl a
    tax

    ; Store the error code and line number in the next slot
    lda expectedNumber
    sta expectedErrors,x
    inx
    lda lineNumber
    sta expectedErrors,x
    inx
    lda lineNumber+1
    sta expectedErrors,x
    inx
    lda fileNum                 ; not seen yet, in this file
    sta expectedErrors,x
    inc numExpectedErrors

    rts
.endproc

; This routine is called when the compiler generates a warning.
; Inputs:
;    A - low byte of line number
;    X - high byte of line number
;    Y - warning number
.proc logExpectedWarning
    ; Store the warning information
    sty expectedNumber
    sta lineNumber
    stx lineNumber+1
    jsr currentFileIndex

    lda #<expectedWarnings
    sta ptr1
    lda #>expectedWarnings
    sta ptr1+1
    lda numExpectedWarnings
    sta numExpected

    jsr recordExpected

    jsr popQ
    rts
.endproc

; This routine is called when the compiler generates an error.
; Inputs:
;    A - low byte of line number
;    X - high byte of line number
;    Y - error number
.proc logExpectedError
    ; Ignore this error. It happens because the tests are not resolving the
    ; system unit for each test.
    cpy #errMissingUnitDeclaration
    beq L1

    ; Store the warning information
    sty expectedNumber
    sta lineNumber
    stx lineNumber+1
    jsr currentFileIndex

    lda #<expectedErrors
    sta ptr1
    lda #>expectedErrors
    sta ptr1+1
    lda numExpectedErrors
    sta numExpected

    jsr recordExpected

    ; Discard the message from the runtime stack
L1: jsr popQ
    rts
.endproc

; This routine records an error or warning.
; On input, ptr1 points to the list of expected errors or warnings and
; fileNum is the file it was reported in. An error expected twice on a line
; (two $ExpectError directives) can be reported twice: each report takes
; the first expectation not yet seen.
.proc recordExpected
    ; Look through the array of expected warnings or errors
    lda #0
    sta expectedIndex
    sta alreadySeen
    lda numExpected
    beq NF                      ; nothing is expected
L1: lda expectedIndex
    asl a
    asl a
    tay
    lda (ptr1),y
    cmp expectedNumber
    bne L2
    iny
    lda (ptr1),y
    cmp lineNumber
    bne L2
    iny
    lda (ptr1),y
    cmp lineNumber+1
    bne L2
    ; Is it in the same file?
    iny
    lda (ptr1),y
    and #<~SEEN
    cmp fileNum
    bne L2
    ; Have we already encountered this one? Look for another.
    lda (ptr1),y
    bpl :+
    sta alreadySeen
    bra L2
    ; Mark the warning as seen
:   ora #SEEN
    sta (ptr1),y
    rts

    ; Is this the last slot?
L2: inc expectedIndex
    lda expectedIndex
    cmp numExpected
    bne L1

    ; Every match was already seen
NF: lda alreadySeen
    bne L3

    ; Reached the end of the list and did not expect this warning
    lda #<strUnexpected
    ldx #>strUnexpected
    jsr showWarningMessage
    lda #1
    sta pauseForErrors
    rts

    ; Already saw this warning
L3: lda #<strAlreadyEnountered
    ldx #>strAlreadyEnountered
    jsr showWarningMessage
    lda #1
    sta pauseForErrors
    rts
.endproc

; This routine prints a message to the console then prints the warning number
; and line number. Each message is on a line of its own, so as many as can
; be fit on the screen.
.proc showWarningMessage
    pha
    phx
    sec
    jsr PLOT                    ; the cursor's column in Y
    cpy #0
    beq :+
    lda #13
    jsr CHROUT
:   plx
    pla
    jsr printLine
    lda expectedNumber
    sta intOp1
    lda #0
    sta intOp1+1
    lda #<intBuf
    ldx #>intBuf
    jsr writeInt16
    ldx #0
:   lda intBuf,x
    beq :+
    jsr CHROUT
    inx
    bne :-
:   ldx #0
:   lda strLineNumber,x
    beq :+
    jsr CHROUT
    inx
    bne :-
:   lda lineNumber
    sta intOp1
    lda lineNumber+1
    sta intOp1+1
    lda #<intBuf
    ldx #>intBuf
    jsr writeInt16
    lda #<intBuf
    ldx #>intBuf
    jsr printLine

    ; Print the file it's in: fileTable + fileNum * FILE_SLOT
    lda #<strFile
    ldx #>strFile
    jsr printLine
    lda #0
    ldx fileNum
    beq :++
:   clc
    adc #FILE_SLOT
    dex
    bne :-
:   clc
    adc #<fileTable
    pha
    lda #>fileTable
    adc #0
    tax
    pla
    jsr printLine
    lda #13
    jsr CHROUT
    rts
.endproc

; This routine looks up the file errors are reported in (from
; getCompilerFilename) in fileTable, adding it if it's not there.
; Its index is returned in A and fileNum. ptr1 is preserved.
.proc currentFileIndex
    lda ptr1
    pha
    lda ptr1+1
    pha
    jsr getCompilerFilename
    sta ptr1
    stx ptr1+1

    lda #0
    sta fileNum
    sta fileOffset
L1: lda fileNum
    cmp numFiles
    beq L4                      ; not in the table
    ldx fileOffset
    ldy #0
L2: lda (ptr1),y
    cmp fileTable,x
    bne L3
    cmp #0
    beq L6                      ; found it
    inx
    iny
    bne L2
L3: inc fileNum
    lda fileOffset
    clc
    adc #FILE_SLOT
    sta fileOffset
    bra L1

    ; Add it to the table
L4: cmp #MAX_FILES
    bne :+
    lda #<strMaxFiles
    ldx #>strMaxFiles
    jsr printLine
    lda #13
    jsr CHROUT
    jmp testFail
:   ldx fileOffset
    ldy #0
L5: lda (ptr1),y
    sta fileTable,x
    beq :+
    inx
    iny
    bne L5
:   inc numFiles

L6: pla
    sta ptr1+1
    pla
    sta ptr1
    lda fileNum
    rts
.endproc

; This routine looks through the list of expected errors and verifies
; each one was encountered.
.proc verifyExpectedErrors
    lda numExpectedErrors
    bne :+
    rts
:   lda #0
    sta expectedIndex

    ; Iterate through the expectedErrors array
L1: lda expectedIndex
    asl a
    asl a
    tax
    lda expectedErrors+3,x
    bmi L2

    ; We did not see this error
    sta fileNum                 ; SEEN is clear
    lda expectedErrors,x
    sta expectedNumber
    lda expectedErrors+1,x
    sta lineNumber
    lda expectedErrors+2,x
    sta lineNumber+1
    lda #<strExpected
    ldx #>strExpected
    jsr showWarningMessage

    lda #1
    sta pauseForErrors

L2: inc expectedIndex
    lda expectedIndex
    cmp numExpectedErrors
    bne L1

    rts
.endproc

; This routine looks through the list of expected warnings and verifies
; each one was encountered.
.proc verifyExpectedWarnings
    lda numExpectedWarnings
    bne :+
    rts
:   lda #0
    sta expectedIndex

    ; Iterate through the expectedWarnings array
L1: lda expectedIndex
    asl a
    asl a
    tax
    lda expectedWarnings+3,x
    bmi L2

    ; We did not see this warning
    sta fileNum                 ; SEEN is clear
    lda expectedWarnings,x
    sta expectedNumber
    lda expectedWarnings+1,x
    sta lineNumber
    lda expectedWarnings+2,x
    sta lineNumber+1
    lda #<strExpected
    ldx #>strExpected
    jsr showWarningMessage

    lda #1
    sta pauseForErrors

L2: inc expectedIndex
    lda expectedIndex
    cmp numExpectedWarnings
    bne L1

    rts
.endproc
