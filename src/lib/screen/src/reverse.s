;
; reverse.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

.include "runtime.inc"

.export setReverse, reverse

reverse: .byte 0

.proc setReverse
    lda #0
    jsr rtLibLoadParam
    beq :+
    lda #$80
:   sta reverse
    rts
.endproc
