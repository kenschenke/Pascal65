;
; backupZeroPages.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; backupZeroPage and restoreZeroPage routines

.include "zeropage.inc"

.export backupZeroPage, restoreZeroPage

.bss

buf: .res zeroPageSize

.code

; This routine backs up page zero
.proc backupZeroPage
    ldx #0
L1: lda zp_base,x
    sta buf,x
    inx
    cpx #zeroPageSize
    bne L1

    rts
.endproc

; This routine restore page zero
.proc restoreZeroPage
    ldx #0
L1: lda buf,x
    sta zp_base,x
    inx
    cpx #zeroPageSize
    bne L1

    rts
.endproc
