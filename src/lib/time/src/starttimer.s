;
; starttimer.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

; StartTimer for Time Unit

.include "c64.inc"

.export startTimer

VIC_PAL = $d06f

.proc startTimer
    lda VIC_PAL
    and #%10000000
    eor #%10000000
    ora #%01000001
    sta CIA2_CRA
    lda #$41
    sta CIA2_CRB
    rts
.endproc
