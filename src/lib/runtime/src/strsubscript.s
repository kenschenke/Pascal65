;
; strsubscript.s
; Ken Schenke (kenschenke@gmail.com)
;
; String subscript handling
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;

.include "runtime.inc"
.include "error.inc"

.export stringSubscriptRead, stringSubscriptWrite

; This routine returns the string character at the given subscript.
;
; Pointer to string heap in A/X.
; String index on runtime stack.
;
; Character returned in A.  If index is 0, string length is returned.
.proc stringSubscriptRead
    sta ptr1
    stx ptr1 + 1
    jsr rtPopAx
    sta tmp1
    txa
    beq :+
    lda #rteValueOutOfRange
    jsr rtRuntimeError
:   ldy #0
    lda (ptr1),y
    cmp tmp1
    bcs :+
    lda #rteValueOutOfRange
    jsr rtRuntimeError
:   ldy tmp1
    ldx #0
    lda (ptr1),y
    rts
.endproc

; This routine writes a character to the string at a subscript
;
; Pointer to string heap in A/X
; Character to write in Y
; String index on runtime stack
.proc stringSubscriptWrite
    sta ptr1                    ; Save heap address in ptr1
    stx ptr1 + 1
    sty tmp1                    ; Store character in tmp1
    jsr rtPopAx                 ; Pop string index off stack
    sta tmp2                    ; Save lower byte to tmp2
    txa                         ; Copy high byte to A
    beq :+                      ; Branch if high byte is zero
RO: lda #rteValueOutOfRange     ; Index out of range
    jsr rtRuntimeError
:   lda tmp2                    ; Load lower byte of index
    beq RO                      ; Branch if zero
    ldy #0
    lda (ptr1),y                ; Load string length
    cmp tmp2                    ; Compare string length to index
    bcc RO                      ; Branch if index > string length
    lda tmp2                    ; Load index
    tay                         ; Transfer it to Y
    lda tmp1                    ; Load character
    sta (ptr1),y                ; Store it in the string
    rts
.endproc

