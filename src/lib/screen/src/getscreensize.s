;
; getscreensize.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

.include "runtime.inc"

.export getScreenSize

.import is80Cols, is50Rows

.proc getScreenSize
    lda #0
    sta sreg
    sta sreg + 1
    tax
    jsr is80Cols
    cmp #0
    bne C8
    lda #40
    bne SC
C8: lda #80
SC: ldy #0
    jsr rtLibStoreVarParam
    ldx #0
    jsr is50Rows
    cmp #0
    bne R5
    lda #25
    bne SR
R5: lda #50
SR: ldy #1
    jmp rtLibStoreVarParam
.endproc
