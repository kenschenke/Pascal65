;
; biggest.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

.include "runtime.inc"

.export biggest

; Compare if intOp1 is less than intOp2
; .A contains 1 if intOp1 < intOp2, 0 otherwise.
.proc ltInt16
    lda intOp1
    cmp intOp2
    lda intOp1 + 1
    sbc intOp2 + 1
    bvc L1
    eor #$80
L1:
    bpl L2
    lda #1
    rts
L2:
    lda #0
    rts
.endproc

; Find the biggest element of the array passed in the first parameter
.proc biggest
    lda #0                  ; Look up the first parameter
    jsr rtLibLoadParam
    sta ptr1                ; Store it in ptr1
    stx ptr1 + 1
    ldy #6
    lda (ptr1),y            ; Load the first element into intOp1
    sta intOp1
    iny
    lda (ptr1),y
    sta intOp1 + 1
    ldx #8                  ; Index counter for 9 elements
    iny
L1: lda (ptr1),y            ; Load the current element in intOp2
    sta intOp2
    iny
    lda (ptr1),y
    sta intOp2 + 1
    iny
    jsr ltInt16             ; Is intOp1 < intOp2?
    cmp #0
    beq :+                  ; Branch if not
    lda intOp2              ; Copy intOp2 to intOp1 (it's now the biggest element)
    sta intOp1
    lda intOp2 + 1
    sta intOp1 + 1
:   dex                     ; Decrement element counter
    bpl L1                  ; Branch if counter >= 0
    lda #0                  ; Return intOp1 to caller
    sta sreg
    sta sreg + 1
    lda intOp1
    ldx intOp1 + 1
    jmp rtLibReturnValue
.endproc
