;
; initthemes.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Routine to load the themes overlay from disk

.include "cbm_kernal.inc"
.include "c64.inc"

.data

fnThemes: .byte "themes,p,r"
fnThemes2:

.code

.export initThemes

.import loadfile

.proc initThemes
    ; Call SETNAM
    ldx #<fnThemes
    ldy #>fnThemes
    lda #fnThemes2-fnThemes
    jsr loadfile

    rts
.endproc
