;
; initmeminfo.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Routine to load the meminfo overlay from disk

.include "cbm_kernal.inc"
.include "c64.inc"

.data

fnMemInfo: .byte "meminfo,p,r"
fnMemInfo2:

.code

.export initMemInfo

.import loadfile

.proc initMemInfo
    ; Call SETNAM
    ldx #<fnMemInfo
    ldy #>fnMemInfo
    lda #fnMemInfo2-fnMemInfo
    jsr loadfile

    rts
.endproc
