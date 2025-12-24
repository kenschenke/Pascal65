;
; initshowtree.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Routine to load the showtree overlay from disk

.include "cbm_kernal.inc"
.include "c64.inc"

.data

fnShowTree: .byte "showtree,p,r"
fnShowTree2:

.code

.export initShowTree

.import loadfile

.proc initShowTree
    ; Call SETNAM
    ldx #<fnShowTree
    ldy #>fnShowTree
    lda #fnShowTree2-fnShowTree
    jsr loadfile

    rts
.endproc
