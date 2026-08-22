;
; deletezzprg.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; deletezzPrg routine

.include "asmlib.inc"
.include "zeropage.inc"

.export deleteZzprg

.data

filename: .asciiz "zzprg.prg"

.code

.proc deleteZzprg
    ; See if the file exists
    lda #<filename
    ldx #>filename
    ldy #0
    ldz #0
    jsr doesFileExist
    bne L1
    rts

    ; Delete the file
L1: lda #<filename
    sta ptr1
    lda #>filename
    sta ptr1+1
    lda #0
    sta ptr1+2
    sta ptr1+3
    jsr scratchFile

    rts
.endproc
