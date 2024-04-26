;
; doublearrayhelper.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

.include "runtime.inc"

.export doubleArrayHelper

; Address of array heap in A/X
.proc doubleArrayHelper
    sta ptr1            ; Save array pointer in ptr1
    stx ptr1 + 1
    lda #10             ; Ten elements in the array
    sta tmp2
    ldy #6              ; Start at 6 (past the array header)
:   lda (ptr1),y        ; Load the low byte of the current array element
    asl a               ; Multiply by 2
    sta (ptr1),y        ; Store it
    iny
    lda (ptr1),y        ; Load the high byte of the current array element
    rol a               ; Multiply by 2
    sta (ptr1),y        ; Store 2
    iny
    dec tmp2            ; Move to the next array element
    bne :-              ; Branch if more elements to go
    rts
.endproc
