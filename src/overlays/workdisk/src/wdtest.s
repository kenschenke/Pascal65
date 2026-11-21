;
; wdtest.s
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Hooks for the workdisk tests (src/apps/workdisktest). They are only
; assembled in the test build of the overlay (make WORKDISKTEST=1), which
; defines __WORKDISKTEST__. The normal overlay has none of this.
;
; The test sets a key script with wdTestSetup, then calls wdTestRun, which
; runs the startup dialog (wdDialog) or wdStartup. getKey takes its keys
; from the script instead of the keyboard. If the script runs out before the dialog
; returns, wdTestRun returns straight to its caller with the carry set,
; wherever the dialog was waiting for a key. Each message the dialog shows
; for a code is logged: wdTestState returns the address of the count,
; followed by the codes.

.ifdef __WORKDISKTEST__

.export wdTestSetup, wdTestRun, wdTestState, wdTestNextKey, wdTestLogCode

.import wdDialog, wdStartup

LOG_SIZE = 8

.bss

wdTestSP: .res 1            ; Stack pointer on entry to wdTestRun
logCount: .res 1            ; Must be followed by logCodes
logCodes: .res LOG_SIZE

.code

; Returns the address of the log in A/X: the count, then the codes
.proc wdTestState
    lda #<logCount
    ldx #>logCount
    rts
.endproc

; Returns the next key of the script in A. At the end of the script it
; does not return. It returns from wdTestRun with the carry set.
.proc wdTestNextKey
    lda $ffff               ; The address is set by wdTestSetup
keyAddr = * - 2
    beq DN
    inc keyAddr
    bne :+
    inc keyAddr+1
:   rts

DN: ldx wdTestSP
    txs
    sec
    rts
.endproc

; Sets the key script and empties the log. A/X points to the script: key
; codes as the keyboard sends them, ended by a zero.
.proc wdTestSetup
    sta wdTestNextKey::keyAddr
    stx wdTestNextKey::keyAddr+1
    lda #0
    sta logCount
    rts
.endproc

; Runs the dialog (A 0) or wdStartup (A not 0). The carry is clear if it
; returned and set if the key script ran out.
.proc wdTestRun
    tsx
    stx wdTestSP
    cmp #0
    bne :+
    jmp wdDialog
:   jmp wdStartup
.endproc

; Logs the code in A. A and Y are kept.
.proc wdTestLogCode
    ldx logCount
    cpx #LOG_SIZE
    bcs :+
    sta logCodes,x
    inc logCount
:   rts
.endproc

.endif ; __WORKDISKTEST__
