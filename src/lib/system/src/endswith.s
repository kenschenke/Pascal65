;
; endswith.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

; EndsWith runtime function

.include "runtime.inc"

.export endswith

.proc endswith
    lda #1
    jsr rtLibLoadParam
    sta ptr2
    stx ptr2 + 1
    lda #0
    jsr rtLibLoadParam
    sta ptr1
    stx ptr1 + 1
    ldy #0
    lda (ptr1),y
    sta tmp1
    lda (ptr2),y
    sta tmp2
    inc ptr1
    bne :+
    inc ptr1 + 1
:   inc ptr2
    bne :+
    inc ptr2 + 1
:   jsr rtEndsWith
    ldx #0
    stx sreg
    stx sreg + 1
    jmp rtLibReturnValue
.endproc
