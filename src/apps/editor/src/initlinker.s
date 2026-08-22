;
; initlinker.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Routine to load the linker overlay from disk

.include "cbm_kernal.inc"
.include "c64.inc"

.data

fnLinker: .byte "linker,p,r"
fnLinker2:

.code

.export initLinker

.import loadfile

.proc initLinker
    ; Call SETNAM
    ldx #<fnLinker
    ldy #>fnLinker
    lda #fnLinker2-fnLinker
    jsr loadfile

    rts
.endproc
