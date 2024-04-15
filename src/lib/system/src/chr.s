;
; chr.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

; Chr runtime function

.include "runtime.inc"

.export chr

; This routine returns the low byte of the parameter.

.proc chr
    lda #0
    jsr rtLibLoadParam
    ; Isolate the 1 bit
    pha
    lda #0
    tax
    sta sreg
    stx sreg + 1
    pla
    jmp rtLibReturnValue
.endproc
