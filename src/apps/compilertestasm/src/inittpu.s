;
; inittpu.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Routine to load the tpu overlay, which writes a unit's TPU, from disk

.include "cbm_kernal.inc"
.include "c64.inc"

.data

fnTpu: .byte "tpu,p,r"
fnTpu2:

.code

.export initTpu

.import loadfile

.proc initTpu
    ; Call SETNAM
    ldx #<fnTpu
    ldy #>fnTpu
    lda #fnTpu2-fnTpu
    jsr loadfile

    rts
.endproc
