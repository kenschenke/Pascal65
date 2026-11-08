;
; compiletests.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; compileTests routine

.include "zeropage.inc"
.include "cbm_kernal.inc"
.include "error.inc"

.export compileTests, nextTestPrg, expectedError

.import runCompiler

.data

pascalSuffix: .asciiz ".pas"
strAdd: .asciiz "add"
strAssign: .asciiz "assign"
strVarInit: .asciiz "varinit"
strConstants: .asciiz "constants"
strBitwiseA: .asciiz "bitwisea"
strBitwiseB: .asciiz "bitwiseb"
strIfThen: .asciiz "ifthen"
strLoops: .asciiz "loops"
strStdRoutines: .asciiz "stdroutines"
strIncDec: .asciiz "incdec"
strStrRoutines: .asciiz "strroutines"
strWriteWidth: .asciiz "writewidth"
strStrTests: .asciiz "strtests"
strRecArray: .asciiz "recarray"
strScopeTest: .asciiz "scopetest"
strCaseTest: .asciiz "casetest"
strProcFunc: .asciiz "procfunc"
strMultiply: .asciiz "multiply"
strSubtract: .asciiz "subtract"
strDivInt: .asciiz "divint"
strTrig: .asciiz "trig"
strVarTest: .asciiz "vartest"
strFileTestA: .asciiz "filetesta"
strFileTestB: .asciiz "filetestb"
strPointers: .asciiz "pointers"
strUnit: .asciiz "unit"
strLibTest: .asciiz "libtest"
strRtnArray: .asciiz "rtnarray"
strRtnRecord: .asciiz "rtnrecord"
strRtnPtrs: .asciiz "rtnptrs"
strRecord: .asciiz "strrecord"
strArray: .asciiz "strarray"
strTypeCast: .asciiz "typecast"
strCharArray: .asciiz "chararray"
strExprClone: .asciiz "exprclone"
strNamedIdx: .asciiz "namedidx"
strForOrd: .asciiz "forord"
strDeclOrdr: .asciiz "declordr"
strDynArrayA: .asciiz "dynarraya"
strDynArrayB: .asciiz "dynarrayb"
strDynArrayC: .asciiz "dynarrayc"
strRtPkgNone: .asciiz "rtpkgnone"
strRtPkgA: .asciiz "rtpkga"
strRtPkgB: .asciiz "rtpkgb"
strRtPkgC: .asciiz "rtpkgc"
strFiveDice: .asciiz "fivedice"
strDone: .asciiz "done"
strTooLarge: .asciiz "toolarge"
strRun1: .asciiz "Run "
strRun2: .asciiz " to begin tests"

; The complete list of tests is too large to compile onto one D81 disk image.
; When the TESTSET symbol is defined (see the Makefile test target) the list
; is split in three. Each set ends by chaining to "done", which reports the
; overall PASS to the test harness. Without TESTSET the whole list is built.
.ifndef TESTSET
TESTSET = 0
.endif

tests:
.if TESTSET = 0 || TESTSET = 1
    .byte .lobyte(strAdd), .hibyte(strAdd)
    .byte .lobyte(strAssign), .hibyte(strAssign)
    .byte .lobyte(strVarInit), .hibyte(strVarInit)
    .byte .lobyte(strConstants), .hibyte(strConstants)
    .byte .lobyte(strBitwiseA), .hibyte(strBitwiseA)
    .byte .lobyte(strBitwiseB), .hibyte(strBitwiseB)
    .byte .lobyte(strIfThen), .hibyte(strIfThen)
    .byte .lobyte(strLoops), .hibyte(strLoops)
    .byte .lobyte(strStdRoutines), .hibyte(strStdRoutines)
    .byte .lobyte(strIncDec), .hibyte(strIncDec)
    .byte .lobyte(strStrRoutines), .hibyte(strStrRoutines)
    .byte .lobyte(strWriteWidth), .hibyte(strWriteWidth)
    .byte .lobyte(strStrTests), .hibyte(strStrTests)
    .byte .lobyte(strRecArray), .hibyte(strRecArray)
    .byte .lobyte(strScopeTest), .hibyte(strScopeTest)
    .byte .lobyte(strCaseTest), .hibyte(strCaseTest)
    .byte .lobyte(strProcFunc), .hibyte(strProcFunc)
    .byte .lobyte(strMultiply), .hibyte(strMultiply)
    .byte .lobyte(strForOrd), .hibyte(strForOrd)
    .byte .lobyte(strDeclOrdr), .hibyte(strDeclOrdr)
.endif
.if TESTSET = 0 || TESTSET = 2
    .byte .lobyte(strSubtract), .hibyte(strSubtract)
    .byte .lobyte(strDivInt), .hibyte(strDivInt)
    .byte .lobyte(strUnit), .hibyte(strUnit)
    .byte .lobyte(strLibTest), .hibyte(strLibTest)
    .byte .lobyte(strTrig), .hibyte(strTrig)
    .byte .lobyte(strVarTest), .hibyte(strVarTest)
    .byte .lobyte(strPointers), .hibyte(strPointers)
    .byte .lobyte(strRtnArray), .hibyte(strRtnArray)
    .byte .lobyte(strRtnRecord), .hibyte(strRtnRecord)
    .byte .lobyte(strRtnPtrs), .hibyte(strRtnPtrs)
    .byte .lobyte(strRecord), .hibyte(strRecord)
    .byte .lobyte(strArray), .hibyte(strArray)
    .byte .lobyte(strTypeCast), .hibyte(strTypeCast)
    .byte .lobyte(strCharArray), .hibyte(strCharArray)
    .byte .lobyte(strExprClone), .hibyte(strExprClone)
    .byte .lobyte(strNamedIdx), .hibyte(strNamedIdx)
    .byte .lobyte(strFileTestA), .hibyte(strFileTestA)
    .byte .lobyte(strFileTestB), .hibyte(strFileTestB)
.endif
.if TESTSET = 0 || TESTSET = 3
    .byte .lobyte(strDynArrayA), .hibyte(strDynArrayA)
    .byte .lobyte(strDynArrayB), .hibyte(strDynArrayB)
    .byte .lobyte(strDynArrayC), .hibyte(strDynArrayC)
    ; Runtime packages (see rtpkg.inc). Together with the tests above they
    ; use every package variant file.
    .byte .lobyte(strRtPkgNone), .hibyte(strRtPkgNone)
    .byte .lobyte(strRtPkgA), .hibyte(strRtPkgA)
    .byte .lobyte(strRtPkgB), .hibyte(strRtPkgB)
    .byte .lobyte(strRtPkgC), .hibyte(strRtPkgC)
.endif
.if TESTSET <> 0
    .byte .lobyte(strDone), .hibyte(strDone)
.endif
    .byte $00, $00

; Programs the compiler must refuse, each followed by the one error it must
; report. They are compiled before the tests above, aren't linked and aren't
; part of the chain.
errorTests:
.if TESTSET = 0 || TESTSET = 1
    .byte .lobyte(strTooLarge), .hibyte(strTooLarge)
    .byte errCodeSegmentOverflow
.endif
    .byte $00, $00

; Programs that must compile and link without an error or warning. They
; are compiled after errorTests and aren't run or part of the chain.
compileOnlyTests:
.if TESTSET = 0 || TESTSET = 3
    ; The split runtime must leave fivedice room (see plans/runtime.md)
    .byte .lobyte(strFiveDice), .hibyte(strFiveDice)
.endif
    .byte $00, $00

.bss

testNum: .res 1
expectedError: .res 1       ; error the current test must report, or 0
sourceFn: .res 16           ; null-terminated source filename for the current test
nextTestPrg: .res 16        ; null-terminated PRG filename of the next test

.code

.proc compileTests
    jsr compileErrorTests
    jsr compileOnly

    lda #0
    sta testNum
    sta expectedError

    ; Loop through the tests
L1: lda testNum
    asl a
    tax
    tay

    ; Check for terminator
    lda tests,y
    iny
    ora tests,y
    beq DN

    ; Put current filename in ptr1
    lda tests,x
    sta ptr1
    inx
    lda tests,x
    sta ptr1+1

    ; Next filename in ptr2
    inx
    lda tests,x
    sta ptr2
    inx
    lda tests,x
    sta ptr2+1

    ; Format current source filename
    jsr makeSourceFilename

    ; Format next test filename
    jsr makeNextTestFilename

    lda #<sourceFn
    ldx #>sourceFn
    jsr runCompiler

    inc testNum
    bra L1

DN: lda #13
    jsr CHROUT

    ldx #0
:   lda strRun1,x
    beq :+
    jsr CHROUT
    inx
    bne :-

:   lda tests
    sta ptr1
    lda tests+1
    sta ptr1+1
    ldy #0
:   lda (ptr1),y
    beq :+
    jsr CHROUT
    iny
    bne :-

:   ldx #0
:   lda strRun2,x
    beq :+
    jsr CHROUT
    inx
    bne :-

:   lda #13
    jsr CHROUT

    rts
.endproc

; This routine compiles the programs in errorTests. runCompiler fails the
; tests unless each reports exactly its expected error.
.proc compileErrorTests
    lda #0
    sta testNum

L1: lda testNum                 ; Y = testNum * 3
    asl a
    adc testNum
    tay

    ; Check for terminator
    lda errorTests,y
    ora errorTests+1,y
    beq DN

    lda errorTests,y
    sta ptr1
    lda errorTests+1,y
    sta ptr1+1
    lda errorTests+2,y
    sta expectedError

    jsr makeSourceFilename

    ; Not part of the chain
    lda #0
    sta nextTestPrg

    lda #<sourceFn
    ldx #>sourceFn
    jsr runCompiler

    inc testNum
    bra L1

DN: rts
.endproc

; This routine compiles and links the programs in compileOnlyTests.
; runCompiler fails the tests if any reports an error or a warning.
.proc compileOnly
    lda #0
    sta testNum
    sta expectedError

L1: lda testNum                 ; Y = testNum * 2
    asl a
    tay

    ; Check for terminator
    lda compileOnlyTests,y
    ora compileOnlyTests+1,y
    beq DN

    lda compileOnlyTests,y
    sta ptr1
    lda compileOnlyTests+1,y
    sta ptr1+1

    jsr makeSourceFilename

    ; Not part of the chain
    lda #0
    sta nextTestPrg

    lda #<sourceFn
    ldx #>sourceFn
    jsr runCompiler

    inc testNum
    bra L1

DN: rts
.endproc

; This routine expects ptr1 to point to the null-terminated test name.
; The routine copies characters until it reaches a null then appends ".pas".
.proc makeSourceFilename
    ldy #0
L1: lda (ptr1),y
    beq L2
    sta sourceFn,y
    iny
    bne L1
L2: ldx #0
L3: lda pascalSuffix,x
    sta sourceFn,y
    beq L4
    iny
    inx
    bne L3
L4: rts
.endproc

; This routine expects ptr2 to point to the null-terminated
; filename of the next test.
; The routine copies it into nextTestPrg.
; If ptr2 is null then it sets nextTestPrg to empty.
.proc makeNextTestFilename
    lda ptr2
    ora ptr2+1
    bne L1
    lda #0
    sta nextTestPrg
    rts

L1: ldy #0
L2: lda (ptr2),y
    sta nextTestPrg,y
    beq L3
    iny
    bne L2
L3: rts
.endproc
