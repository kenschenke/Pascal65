;
; length.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

; Implement the Length function (string length)

.include "runtime.inc"

.export length

.proc length
    lda #0
    jsr rtLibLoadParam
    sta ptr1
    stx ptr1 + 1
    lda #0
    tax
    tay
    sta sreg
    sta sreg + 1
    lda (ptr1),y
    jmp rtLibReturnValue
.endproc
