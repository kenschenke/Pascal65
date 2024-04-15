;
; poke.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

; Poke runtime function

.include "runtime.inc"

.export poke

; This routine stores the value from the second parameter
; into the address in the first parameter.

.proc poke
    lda #0
    jsr rtLibLoadParam
    sta ptr2
    stx ptr2 + 1
    lda #1
    jsr rtLibLoadParam
    ldy #0
    sta (ptr2),y
    rts
.endproc
