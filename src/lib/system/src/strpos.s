;
; strpos.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

; Contains runtime function

.include "runtime.inc"

.export strPos

.proc strPos
    lda #2
    jsr rtLibLoadParam
    pha
    lda #1
    jsr rtLibLoadParam
    sta ptr2
    stx ptr2 + 1
    lda #0
    jsr rtLibLoadParam
    sta ptr1
    stx ptr1 + 1
    pla
    jsr rtStrPos
    ldx #0
    stx sreg
    stx sreg + 1
    jmp rtLibReturnValue
.endproc
