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

.export compileTests, nextTestPrg

.import runCompiler

.data

pascalSuffix: .asciiz ".pas"
strAdd: .asciiz "add"
strAssign: .asciiz "assign"
strSubtract: .asciiz "subtract"
strRun1: .asciiz "Run "
strRun2: .asciiz " to begin tests"

tests:
    .byte .lobyte(strAdd), .hibyte(strAdd)
    .byte .lobyte(strAssign), .hibyte(strAssign)
    .byte .lobyte(strSubtract), .hibyte(strSubtract)
    .byte $00, $00

.bss

testNum: .res 1
sourceFn: .res 16           ; null-terminated source filename for the current test
nextTestPrg: .res 16        ; null-terminated PRG filename of the next test

.code

.proc compileTests
    lda #0
    sta testNum

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
