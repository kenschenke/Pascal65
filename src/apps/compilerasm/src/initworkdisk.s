;
; initworkdisk.s
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Routine to load the workdisk overlay from disk

.include "cbm_kernal.inc"
.include "c64.inc"

.data

fnWorkdisk: .byte "workdisk,p,r"
fnWorkdisk2:

.code

.export initWorkdisk

.import loadfile

.proc initWorkdisk
    ldx #<fnWorkdisk
    ldy #>fnWorkdisk
    lda #fnWorkdisk2-fnWorkdisk
    jmp loadfile
.endproc
