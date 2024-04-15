;
; upcase.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

; UpCase

.include "runtime.inc"

.export upCase

.proc upCase
    lda #0
    jsr rtLibLoadParam
    ldy #1
    jsr rtStrCase
    pha
    txa
    pha
    lda #0
    sta sreg
    sta sreg + 1
    pla
    tax
    pla
    jmp rtLibReturnValue
.endproc
