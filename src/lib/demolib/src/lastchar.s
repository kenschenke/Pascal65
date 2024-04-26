;
; lastchar.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

.include "runtime.inc"

.export lastChar

.proc lastChar
    lda #0              ; Load parameter
    jsr rtLibLoadParam
    sta ptr1            ; Store parameter (pointer to string heap) in ptr1
    stx ptr1 + 1
    ldy #0              ; Load string length
    lda (ptr1),y
    tay                 ; Put in Y
    lda #0              ; Zero out sreg and X
    sta sreg
    sta sreg + 1
    ldx #0
    lda (ptr1),y        ; Load last character and return it
    jmp rtLibReturnValue
.endproc
