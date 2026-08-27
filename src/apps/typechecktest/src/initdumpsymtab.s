;
; initdumpsymtab.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Routine to load dumpsymtab from disk

.include "cbm_kernal.inc"
.include "c64.inc"

.data

fnDumpSymtab: .byte "dumpsymtab,p,r"
fnDumpSymtab2:

.code

.export initDumpSymtab

.import loadfile

.proc initDumpSymtab
    ; Call SETNAM
    ldx #<fnDumpSymtab
    ldy #>fnDumpSymtab
    lda #fnDumpSymtab2-fnDumpSymtab
    jsr loadfile

    rts
.endproc
