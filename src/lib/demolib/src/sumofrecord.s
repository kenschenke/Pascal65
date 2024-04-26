;
; sumofrecord.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

.include "runtime.inc"
.include "types.inc"

.export sumOfRecord

; Value offset of record in Y
.proc loadField
    lda #0          ; Zero out sreg
    sta sreg
    sta sreg + 1
    iny             ; Load high byte of record field
    lda (ptr1),y
    tax             ; Put it in X
    dey
    lda (ptr1),y    ; Load low byte of record field
    jmp rtPushEax   ; Push the field onto the runtime stack
.endproc

.proc sumOfRecord
    lda #0          ; Load parameter (pointer to record) into A/X
    jsr rtLibLoadParam
    sta ptr1        ; Put the record pointer into ptr1
    stx ptr1 + 1
    ldy #0
    jsr loadField   ; Put the first field onto the runtime stack
    ldy #2
    jsr loadField   ; Put the second field (offset 2) on runtime stack
    lda #TYPE_INTEGER
    tax
    tay
    jsr rtAdd       ; Add the record fields
    jsr rtPopEax
    jmp rtLibReturnValue ; Return the sum to the caller
.endproc
