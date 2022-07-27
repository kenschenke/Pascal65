; Common Assembly Routines

    .export     incRow, petscii2Screen, strLen
    .importzp   ptr1, ptr2, ptr3, tmp1, tmp2

; Increment the address in ptr2 by .Y bytes per row
; row passed in .X, number of columns in .Y
incRow:
    lda tmp1        ; Store tmp1 on the stack and restore it later
    pha             ; since this routine clobbers it.
    sty tmp1
    cpx #0
@Loop:
    beq @Done       ; If .X is zero we're done
    lda ptr2        ; Load low byte for address from ptr2
    clc
    adc tmp1        ; 80 chars per row
    sta ptr2        ; Store the low byte
    lda ptr2+1      ; Load the high byte
    adc #$0         ; Add the carry bit
    sta ptr2+1      ; Store the high byte
    dex
    jmp @Loop
@Done:
    pla
    sta tmp1
    rts

; Calculate string length in ptr1
; Length returned in .Y
strLen:
    ldy #0
_Loop:
    lda (ptr1),y
    beq _Done
    iny
    jmp _Loop
_Done:
    rts

; Convert the PETSCII character in .A
; to a screen code.

petscii2Screen:
    cmp #$20    ; if a < 32
    bcc @convRev

    cmp #$60    ; if a < 96
    bcc @conv1

    cmp #$80    ; if a < 128
    bcc @conv2

    cmp #$a0    ; if a < 160
    bcc @conv3

    cmp #$c0    ; if a < 192
    bcc @conv4

    cmp #$ff    ; if a < 255
    bcc @convRev

    lda #$7e
    bne @convEnd

@conv2:
    and #$5f
    bne @convEnd

@conv3:
    ora #$40
    bne @convEnd

@conv4:
    eor #$c0
    bne @convEnd

@conv1:
    and #$3f
    bpl @convEnd

@convRev:
    eor #$80
@convEnd:
    rts
