;
; inittypecheck.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Routine to load the typecheck from disk

.include "cbm_kernal.inc"
.include "c64.inc"

.data

fnTypeCheck: .byte "typecheck,p,r"
fnTypeCheck2:

.code

.export initTypeCheck

.import loadfile

.proc initTypeCheck
    ; Call SETNAM
    ldx #<fnTypeCheck
    ldy #>fnTypeCheck
    lda #fnTypeCheck2-fnTypeCheck
    jsr loadfile

    rts
.endproc
