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

.export stringSubscriptRead, stringSubscriptCalc
.import runtimeError

; This routine returns the string character at the given subscript.
;
; Pointer to string heap in A/X.
; String index on runtime stack.
;
; Character returned in A.  If index is 0, string length is returned.
.proc stringSubscriptRead
    sta ptr1
    stx ptr1 + 1
    jsr rtPopEax
    sta tmp1
    txa
    beq :+
    lda #rteValueOutOfRange
    jsr runtimeError
:   ldy #0
    lda (ptr1),y
    cmp tmp1
    bcs :+
    lda #rteValueOutOfRange
    jsr runtimeError
:   ldy tmp1
    ldx #0
    lda (ptr1),y
    rts
.endproc

; This routine calculates the address of a string's character
; at a given index.
;
; Pointer to string heap in A/X
; String index in Y
; Address of character returned in ptr1
.proc stringSubscriptCalc
    sta ptr1                    ; Save heap address in ptr1
    stx ptr1 + 1
    tya                         ; Transfer index to A (for Z flag)
    beq RO                      ; Index cannot be 0
    sta tmp1                    ; Save index to tmp1
    ldy #0
    lda (ptr1),y                ; Load string length into A
    cmp tmp1                    ; Is index <= string length?
    bcc RO                      ; Branch if not
    ; Add the index to the string heap address
    lda ptr1
    clc
    adc tmp1
    sta ptr1
    lda ptr1 + 1
    adc #0
    sta ptr1 + 1
    rts
RO: lda #rteValueOutOfRange     ; Index out of range
    jsr runtimeError
.endproc

