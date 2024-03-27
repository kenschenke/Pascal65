.include "runtime.inc"

.export readInt32

.import invertInt32

; This routine converts the string representation of a signed 32-bit integer
; into an integer stored in intOp1/intOp2.  The routine parses digits from intBuf
; until it encounters a non-digit or reaches the end of the buffer (11 chars).
;
; It works by adding 1 for the number in the 1s place, 10 for the number in
; the 10s place, and so on.
;
; tmp1 - contains a 1 if negative
; tmp2 - number of digits
; tmp3 - buffer index
; tmp4 - tensTable32 index
.proc readInt32
    ; initialize a few things
    lda #0
    sta tmp1        ; not negative - so far
    sta tmp2        ; number of digits
    sta tmp3        ; buffer index
    sta tmp4        ; tensTable32 index
    sta intOp1      ; LB
    sta intOp1 + 1  ; HB
    sta intOp2
    sta intOp2 + 1

    ; look for a negative sign
    tay             ; initialize .Y to 0 as well
    lda (intPtr),y
    cmp #'-'
    bne L1
    lda #1
    sta tmp1
    inc tmp3

    ; count the number of digits in the number
L1:
    ldy tmp3
    cpy #11
    beq L2          ; maximum number of characters in number
    lda (intPtr),y
    cmp #'0'-1
    bcc L2          ; non-digit
    cmp #'9'+1
    bcs L2          ; non-digit
    inc tmp2
    inc tmp3
    bne L1

L2:
    ; tmp2 contains the number of digits
    ; initialize tmp4 to the correct offset in tensTable32
    sec
    lda #10
    sbc tmp2
    asl             ; multiply by 4
    asl
    sta tmp4
    ; reset tmp3 to point to the first digit in the number
    lda tmp1
    sta tmp3        ; tmp1 contains a 1 if minus sign

    ; Loop through the digits, adding values from tensTable32
L3:
    lda tmp2        ; check if all digits have been read
    beq L6          ; yes
    ldy tmp3        ; index into intBuf
    lda (intPtr),y
    sec
    sbc #'0'        ; convert the character to a number
    tax             ; use the .X register to count for the loop
L4:
    ; Add to intOp1/intOp2 for the digit in this place
    cpx #0
    beq L5          ; done adding for this digit
    ldy tmp4
    clc
    lda intOp1
    adc (tensTable32Ptr),y
    sta intOp1
    lda intOp1 + 1
    iny
    adc (tensTable32Ptr),y
    sta intOp1 + 1
    lda intOp2
    iny
    adc (tensTable32Ptr),y
    sta intOp2
    lda intOp2 + 1
    iny
    adc (tensTable32Ptr),y
    sta intOp2 + 1
    dex
    clc
    bcc L4
L5:
    ; Move on to the next digit
    dec tmp2
    inc tmp3
    clc
    lda tmp4
    adc #4
    sta tmp4
    bne L3

L6:
    ; If the number was negative, negate it
    lda tmp1
    beq L7
    jsr invertInt32

L7:
    rts
.endproc
