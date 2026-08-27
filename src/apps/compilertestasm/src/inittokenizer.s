;
; inittokenizer.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Routine to load the tokenizer from disk

.include "cbm_kernal.inc"
.include "c64.inc"

.data

fnTokenizer: .byte "tokenizer,p,r"
fnTokenizer2:

.code

.export initTokenizer

.import loadfile

.proc initTokenizer
    ; Call SETNAM
    ldx #<fnTokenizer
    ldy #>fnTokenizer
    lda #fnTokenizer2-fnTokenizer
    jsr loadfile

    rts
.endproc
