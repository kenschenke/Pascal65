;
; check.s
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Printing and checks for the runtime test suites.
;
; A suite keeps the number of the test it is running in rttTest and the
; step within it in rttStep. A failed check prints both, what was
; checked, and the expected and actual values, then fails the suite
; (testFail, which doesn't return).
;
; These routines use no zero page, so the runtime code under test can have
; all of it. printZ reads the string through self-modifying code.

.include "cbm_kernal.inc"
.include "rtt.inc"

.export printZ, printHex8, printHex16, printDec8, printCR
.export rttTest, rttStep, rttExpect, rttActual
.export rttFail, rttCheck8, rttCheck16, rttWhere

.import testFail

.bss

rttTest: .res 1             ; The test being run, from 1
rttStep: .res 1             ; The step within it, from 1
rttExpect: .res 2           ; The value rttCheck8 and rttCheck16 expect
rttActual: .res 2           ; and the value they got
msgPtr: .res 2
printed: .res 1             ; printDec8: non-zero once a digit is printed

.data

strTest: .asciiz "test "
strStep: .asciiz " step "
strColon: .asciiz ": "
strExpected: .asciiz " expected $"
strGot: .asciiz " got $"

.code

; Prints the zero-terminated string in A/X
.proc printZ
    sta L1+1
    stx L1+2
    ldy #0
L1: lda $ffff,y             ; The address is set above
    beq DN
    jsr CHROUT
    iny
    bne L1
DN: rts
.endproc

.proc printCR
    lda #13
    jmp CHROUT
.endproc

; Prints the 16-bit value in A/X as four hex digits
.proc printHex16
    pha
    txa
    jsr printHex8
    pla
    ; Fall through
.endproc

; Prints A as two hex digits
.proc printHex8
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
    adc #6                  ; The carry is set: 10 + 6 + 1 + '0' = 'a'
:   adc #'0'
    jmp CHROUT
.endproc

; Prints A in decimal, without leading zeros
.proc printDec8
    ldy #0
    sty printed
L1: ldx #0                  ; X = the digit for powers,y
:   cmp powers,y
    bcc :+
    sbc powers,y
    inx
    bne :-
:   pha
    txa
    ora printed
    beq SK                  ; A leading zero
    txa
    ora #'0'
    phy
    jsr CHROUT
    ply
    sta printed
SK: pla
    iny
    cpy #2
    bne L1
    ora #'0'                ; The ones digit is always printed
    jmp CHROUT
powers: .byte 100, 10
.endproc

; Prints "test N step M: " on a new line
.proc rttWhere
    jsr printCR
    LDAX strTest
    jsr printZ
    lda rttTest
    jsr printDec8
    LDAX strStep
    jsr printZ
    lda rttStep
    jsr printDec8
    LDAX strColon
    jmp printZ
.endproc

; Fails the suite with the message in A/X. Doesn't return.
.proc rttFail
    sta msgPtr
    stx msgPtr+1
    jsr rttWhere
    lda msgPtr
    ldx msgPtr+1
    jsr printZ
    jsr printCR
    jmp testFail
.endproc

; Fails the suite if the low bytes of rttExpect and rttActual differ. A/X
; is the message that names the value.
.proc rttCheck8
    sta msgPtr
    stx msgPtr+1
    lda rttExpect
    cmp rttActual
    bne :+
    rts
:   jsr rttWhere
    lda msgPtr
    ldx msgPtr+1
    jsr printZ
    LDAX strExpected
    jsr printZ
    lda rttExpect
    jsr printHex8
    LDAX strGot
    jsr printZ
    lda rttActual
    jsr printHex8
    jsr printCR
    jmp testFail
.endproc

; Fails the suite if rttExpect and rttActual differ. A/X is the message
; that names the value.
.proc rttCheck16
    sta msgPtr
    stx msgPtr+1
    lda rttExpect
    cmp rttActual
    bne :+
    lda rttExpect+1
    cmp rttActual+1
    bne :+
    rts
:   jsr rttWhere
    lda msgPtr
    ldx msgPtr+1
    jsr printZ
    LDAX strExpected
    jsr printZ
    lda rttExpect
    ldx rttExpect+1
    jsr printHex16
    LDAX strGot
    jsr printZ
    lda rttActual
    ldx rttActual+1
    jsr printHex16
    jsr printCR
    jmp testFail
.endproc
