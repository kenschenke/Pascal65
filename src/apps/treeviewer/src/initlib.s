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

fnAsmLib: .byte "asm.lib,p,r"
fnAsmLib2:
fnAstLib: .byte "ast.lib,p,r"
fnAstLib2:

.code

.export initLib

.import loadfile

.proc initLib
    ldx #<fnAsmLib
    ldy #>fnAsmLib
    lda #fnAsmLib2-fnAsmLib
    jsr loadfile

    ldx #<fnAstLib
    ldy #>fnAstLib
    lda #fnAstLib2-fnAstLib
    jsr loadfile

    rts
.endproc
