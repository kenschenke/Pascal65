;
; resetticks.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

; ResetTicks for Time Unit

.include "c64.inc"

.p4510

VIC_PAL = $d06f

.export resetTicks

.import startTimer

.proc resetTicks
    lda VIC_PAL
    and #%10000000
    eor #%10000000
    ora #%01000000
    sta CIA2_CRA
    lda #$40
    sta CIA2_CRB
    ldx #3
    lda #$ff
L1: sta CIA2_TA,x
    dex
    bpl L1
    lda #$10
    tsb CIA2_CRA
    tsb CIA2_CRB

    jmp startTimer
.endproc
