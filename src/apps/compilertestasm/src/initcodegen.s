;
; initcodegen.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Routine to load the codegen overlay from disk

.include "cbm_kernal.inc"
.include "c64.inc"

.data

fnCodeGen: .byte "codegen,p,r"
fnCodeGen2:

.code

.export initCodeGen

.import loadfile

.proc initCodeGen
    ; Call SETNAM
    ldx #<fnCodeGen
    ldy #>fnCodeGen
    lda #fnCodeGen2-fnCodeGen
    jsr loadfile

    rts
.endproc
