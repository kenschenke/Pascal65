;
; initdumpicode.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Routine to load the dumpicode overlay from disk

.include "cbm_kernal.inc"
.include "c64.inc"

.data

fnDumpIcode: .byte "dumpicode,p,r"
fnDumpIcode2:

.code

.export initDumpIcode

.import loadfile

.proc initDumpIcode
    ; Call SETNAM
    ldx #<fnDumpIcode
    ldy #>fnDumpIcode
    lda #fnDumpIcode2-fnDumpIcode
    jsr loadfile

    rts
.endproc
