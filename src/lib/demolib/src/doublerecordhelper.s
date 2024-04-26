;
; doublerecordhelper.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

.include "runtime.inc"

.export doubleRecordHelper

; Pointer to record in A/X
.proc doubleRecordHelper
    sta ptr1            ; Store record pointer in ptr1
    stx ptr1 + 1
    ldy #0
:   lda (ptr1),y        ; Load the low byte of the record field
    asl a               ; Multiply by 2
    sta (ptr1),y        ; Store it
    iny
    lda (ptr1),y        ; Load the high byte of the record field
    rol a               ; Multiply by 2
    sta (ptr1),y        ; Store it
    iny
    cpy #4              ; Have both record fields be done?
    bne :-              ; Branch if not
    rts
.endproc
