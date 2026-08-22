;
; initeditor.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Routine to load the editor from disk

.include "cbm_kernal.inc"
.include "c64.inc"

.data

fnEditor: .byte "editor,p,r"
fnEditor2:

.code

.export initEditor

.import loadfile

.proc initEditor
    ; Call SETNAM
    ldx #<fnEditor
    ldy #>fnEditor
    lda #fnEditor2-fnEditor
    jsr loadfile

    rts
.endproc
