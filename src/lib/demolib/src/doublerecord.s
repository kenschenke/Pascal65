;
; doublerecord.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

.include "runtime.inc"

.import doubleRecordHelper

.export doubleRecord

.proc doubleRecord
    lda #0              ; Load the pointer to the first parameter on the runtime stack
    jsr rtLibLoadParam
    sta ptr1
    stx ptr1 + 1
    ldy #1              ; Dereference to get the pointer to the record's heap
    lda (ptr1),y
    tax
    dey
    lda (ptr1),y
    jmp doubleRecordHelper
.endproc
