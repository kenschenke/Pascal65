;
; rterror.s
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Stands in for the runtime's runtimeError (rterror.s in the runtime), which
; prints the error and ends the program. The runtime code under test calls
; it, and it never returns there.
;
; A test that expects a runtime error arms a catch (CATCH_RTE in
; rterror.inc). This routine then puts the stack pointer back where it was
; when the catch was armed and jumps to the catch's handler, with the
; error's code in rteCode. The catch is disarmed first. A runtime error
; with no catch armed fails the suite.

.include "rtt.inc"

.export runtimeError, rteCatch, rteCatchSP, rteCode

.import rttWhere, printHex8, printCR, printZ, testFail

.bss

rteCatch: .res 2            ; The handler, or 0 (the high byte) for none
rteCatchSP: .res 1          ; The stack pointer for the handler
rteCode: .res 1             ; The error's code
handler: .res 2

.data

strUnexpected: .asciiz "unexpected runtime error $"

.code

.proc runtimeError
    sta rteCode
    lda rteCatch+1
    beq NC
    sta handler+1
    lda rteCatch
    sta handler
    lda #0
    sta rteCatch+1
    ldx rteCatchSP
    txs
    jmp (handler)

NC: jsr rttWhere
    LDAX strUnexpected
    jsr printZ
    lda rteCode
    jsr printHex8
    jsr printCR
    jmp testFail
.endproc
