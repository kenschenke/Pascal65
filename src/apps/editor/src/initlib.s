;
; initlib.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Routine to load the ASM.LIB from disk

.include "cbm_kernal.inc"
.include "c64.inc"

.data

fnLib: .byte "asm.lib,p,r"
fnLib2:

.code

.export initLib

.import loadfile

.proc initLib
    ; Call SETNAM
    ldx #<fnLib
    ldy #>fnLib
    lda #fnLib2-fnLib
    jsr loadfile

    rts
.endproc
