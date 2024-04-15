;
; comparestr.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

; Compare two strings

.include "runtime.inc"

.export compareStr

.proc compareStr
    lda #0
    jsr rtLibLoadParam
    sta ptr3
    stx ptr3 + 1
    lda #1
    jsr rtLibLoadParam
    sta ptr4
    stx ptr4 + 1
    jsr rtStrCompare
    ldx #0
    stx sreg
    stx sreg + 1
    jmp rtLibReturnValue
.endproc
