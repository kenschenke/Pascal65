;
; testresult.s
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Shared by the test programs to report an overall PASS/FAIL result to
; the host. The result is printed on the screen as the last line before
; the BASIC READY prompt. The Makefile runs the emulator with -dumpscreen
; and looks for "RESULT: PASS" or "RESULT: FAIL" in the screen dump.
;
; testInit must be called first thing in main. testFail abandons the
; test run immediately by restoring the stack to where it was when main
; started and returning to BASIC, so no test needs to unwind itself.

.include "cbm_kernal.inc"
.include "zeropage.inc"

.export testInit, testPass, testFail

CH_HOME = $13
CH_DOWN = $11

.bss

savedSP: .res 1

.data

strPass: .byte "RESULT: PASS", 13, 0
strFail: .byte "RESULT: FAIL", 13, 0

.code

; Remembers the stack pointer as it was on entry to main
.proc testInit
    tsx
    inx                 ; Discard the return address pushed by the JSR
    inx
    stx savedSP
    rts
.endproc

.proc testPass
    lda #<strPass
    ldx #>strPass
    jmp printString
.endproc

; Does not return to the caller. Control goes back to whatever called main.
.proc testFail
    jsr CLALL           ; Close open files and send output back to the screen
    lda #<strFail
    ldx #>strFail
    jsr printString
    ldx savedSP
    txs
    rts
.endproc

; Prints the result string at the top of the screen. xemu's -prgexit does not
; see a READY prompt in the bottom two screen rows, so a test that scrolled the
; screen would never exit. Printing at the top puts READY well clear of them.
;
; xemu also only recognizes the prompt when the cursor sits over a blank cell.
; After this returns BASIC prints READY on row 2, which leaves the cursor at
; column 0 of row 3, so a space is written there. Only that one cell is changed
; so the rest of the screen, which has the details of a failure, stays visible.
; (Writing whole blank rows made the screen editor shift the screen contents.)
.proc printString
    sta ptr1
    stx ptr1+1
    lda #CH_HOME
    jsr CHROUT
    ldy #0
:   lda (ptr1),y
    beq :+
    jsr CHROUT
    iny
    bne :-
:   lda #13             ; Move to row 3
    jsr CHROUT
    jsr CHROUT
    lda #' '
    jsr CHROUT
    lda #CH_HOME        ; Back to row 1 for BASIC
    jsr CHROUT
    lda #CH_DOWN
    jmp CHROUT
.endproc
