;
; odd.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

; Odd runtime function

.include "runtime.inc"

.export odd

; This routine returns a non-zero value if the paramater is odd

.proc odd
    lda #0
    jsr rtLibLoadParam
    ; Isolate the 1 bit
    and #1
    pha
    lda #0
    tax
    sta sreg
    stx sreg + 1
    pla
    jmp rtLibReturnValue
.endproc
