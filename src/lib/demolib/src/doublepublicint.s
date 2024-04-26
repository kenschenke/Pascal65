;
; doublepublicint.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

.include "runtime.inc"

.export doublePublicInt

.import publicInt

.proc doublePublicInt
    lda publicInt       ; load the pointer to the variable
    sta ptr1            ; and store it in ptr1
    lda publicInt + 1
    sta ptr1 + 1
    ldy #0
    lda (ptr1),y        ; load the low byte of the value
    asl a               ; double it
    sta (ptr1),y        ; store the low byte
    iny
    lda (ptr1),y        ; lowe the high byte of the value
    rol a               ; double it
    sta (ptr1),y        ; store the high byte
    rts
.endproc
