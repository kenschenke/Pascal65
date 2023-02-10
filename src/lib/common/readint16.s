.import intBuf, intOp1, tensTable, invertInt16
.importzp ptr1, ptr2, tmp1, tmp2, tmp3, tmp4

.export readInt16

; This routine converts the string representation of a signed 16-bit integer
; into an integer stored in intOp1.  The routine parses digits from intBuf
; until it encounters a non-digit or reaches the end of the buffer (7 chars).
;
; It works by adding 1 for the number in the 1s place, 10 for the number in
; the 10s place, and so on.
;
; ptr1 - zero page pointer to intBuf
; ptr2 - zero page pointer to tensTable
; tmp1 - contains a 1 if negative
; tmp2 - number of digits
; tmp3 - buffer index
; tmp4 - tensTable index
.proc readInt16
    ; initialize ptr1
    lda #<intBuf
    sta ptr1
    lda #>intBuf
    sta ptr1 + 1
    ; initialize ptr2
    lda #<tensTable
    sta ptr2
    lda #>tensTable
    sta ptr2 + 1

    ; initialize a few things
    lda #0
    sta tmp1        ; not negative - so far
    sta tmp2        ; number of digits
    sta tmp3        ; buffer index
    sta tmp4        ; tensTable index
    sta intOp1      ; LB
    sta intOp1 + 1  ; HB

    ; look for a negative sign
    tay             ; initialize .Y to 0 as well
    lda (ptr1),y
    cmp #'-'
    bne L1
    lda #1
    sta tmp1
    inc tmp3

    ; count the number of digits in the number
L1:
    ldy tmp3
    cpy #7
    beq L2          ; maximum number of characters in number
    lda (ptr1),y
    cmp #'0'-1
    bcc L2          ; non-digit
    cmp #'9'+1
    bcs L2          ; non-digit
    inc tmp2
    inc tmp3
    jmp L1

L2:
    ; tmp2 contains the number of digits
    ; initialize tmp4 to the correct offset in tensTable
    sec
    lda #5
    sbc tmp2
    asl             ; multiply by 2
    sta tmp4
    ; reset tmp3 to point to the first digit in the number
    lda tmp1
    sta tmp3        ; tmp1 contains a 1 if minus sign

    ; Loop through the digits, adding values from tensTable
L3:
    lda tmp2        ; check if all digits have been read
    beq L6          ; yes
    ldy tmp3        ; index into intBuf
    lda (ptr1),y
    sec
    sbc #'0'        ; convert the character to a number
    tax             ; use the .X register to count for the loop
L4:
    ; Add to intOp1 for the digit in this place
    cpx #0
    beq L5          ; done adding for this digit
    ldy tmp4
    clc
    lda intOp1
    adc (ptr2),y
    sta intOp1
    lda intOp1 + 1
    iny
    adc (ptr2),y
    sta intOp1 + 1
    dex
    jmp L4
L5:
    ; Move on to the next digit
    dec tmp2
    inc tmp3
    inc tmp4
    inc tmp4
    jmp L3

L6:
    ; If the number was negative, negate it
    lda tmp1
    beq L7
    jsr invertInt16

L7:
    rts
.endproc
