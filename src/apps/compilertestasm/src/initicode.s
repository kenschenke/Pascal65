;
; initicode.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Routine to load the icode generator from disk

.include "cbm_kernal.inc"
.include "c64.inc"

.data

fnIcode: .byte "icode,p,r"
fnIcode2:

.code

.export initIcode

.import loadfile

.proc initIcode
    ; Call SETNAM
    ldx #<fnIcode
    ldy #>fnIcode
    lda #fnIcode2-fnIcode
    jsr loadfile

    rts
.endproc
