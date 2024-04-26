;
; doublepublicrecord.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

.include "runtime.inc"

.export doublePublicRecord

.import publicRecord, doubleRecordHelper

.proc doublePublicRecord
    lda publicRecord
    sta ptr1
    lda publicRecord + 1
    sta ptr1 + 1
    ldy #1
    lda (ptr1),y
    tax
    dey
    lda (ptr1),y
    jmp doubleRecordHelper
.endproc
