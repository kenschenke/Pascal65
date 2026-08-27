;
; initparser.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Routine to load the parser from disk

.include "cbm_kernal.inc"
.include "c64.inc"

.data

fnParser: .byte "parser,p,r"
fnParser2:

.code

.export initParser

.import loadfile

.proc initParser
    ; Call SETNAM
    ldx #<fnParser
    ldy #>fnParser
    lda #fnParser2-fnParser
    jsr loadfile

    rts
.endproc
