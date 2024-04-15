;
; peek.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

; Peek runtime function

.include "runtime.inc"

.export peek

; This routine returns the value in the address in the first parameter

.proc peek
    jsr rtLibLoadParam
    sta ptr1
    stx ptr1 + 1
    lda #0
    sta sreg
    sta sreg + 1
    tax
    ldy #0
    lda (ptr1),y
    jmp rtLibReturnValue
.endproc
