.include "cbm_kernal.inc"

.importzp ptr1, ptr2, tmp1, tmp2, tmp3, tmp4
.import tensTable, intBuf, intOp1, intOp2, spcl32768
.import isNegInt16, invertInt16, leftpad, popax

.export writeInt16

; This routine converts the signed 16-bit integer in intOp1 into
; a string stored in the intBuf buffer as a series of PETSCII
; characters.  If bit 7 of the high byte is set, the number is
; treated as negative and a minus sign is written to the buffer.
;
; The routine works by seeing how many times the number goes into
; 10000, then 1000, then 100, and finally 10.
;
; ptr1, ptr2, tmp1, tmp2, tmp3, and tmp4 are trashed as well as intOp2.
;
; ptr1 - used for accessing the tensTable
; ptr2 - pointer to intBuf
; tmp1 - current digit
; tmp2 - current offset into tensTable
; tmp3 - set to 0 until the first non-zero digit is seen in the number.
;        once this is 1, print all digits even if zero.
; tmp4 - width to right-align number in

NUM_WORDTBL = 8     ; four entries * 2 bytes

.code

; number to write is in intOp1
; field width in .A
.proc writeInt16
    ; See if the number is -32768 : a special case.
    sta tmp4
    lda #<intBuf
    sta ptr2
    lda #>intBuf
    sta ptr2 + 1
    jsr clearbuf
    lda intOp1
    cmp #0
    bne @NotSpecl
    lda intOp1 + 1
    cmp #$80
    bne @NotSpecl
    ; Number is -32768
    ; This is important because any other number can be negated.
    lda #<spcl32768
    sta ptr1
    lda #>spcl32768
    sta ptr1 + 1
    ldy #0
    ; Print -32768 to the screen then return
@LSpecl:
    lda (ptr1),y
    beq @JmpDone
    sta (ptr2),y
    iny
    jmp @LSpecl

@NotSpecl:
    ; Number is not -32768
    jsr isNegInt16       ; Is it negative?
    beq @NotNeg
    lda #'-'        ; It is.  Print a negative sign
    ldy #0
    sta (ptr2),y
    clc
    lda ptr2
    adc #1
    sta ptr2
    lda ptr2 + 1
    adc #0
    sta ptr2 + 1
    jsr invertInt16      ; Make it a positive number
    jmp @NotNeg

@JmpDone:
    jmp @Done

@NotNeg:
    ; Loop through tensTable, subtracting values until intOp1 is negative.
    ; If the count is > 0 then write the digit.
    lda #0
    sta tmp3
    lda #<tensTable
    sta ptr1
    lda #>tensTable
    sta ptr1 + 1
    lda #0
    sta tmp2
@LoopTbl:
    lda #0
    sta tmp1
    lda tmp2            ; current index into table
    cmp #NUM_WORDTBL    ; end of the table?
    beq @PrintLastDigit
    tay
@LoopSub:
    sec
    lda intOp1
    sbc (ptr1),y
    sta intOp2
    lda intOp1 + 1
    iny
    sbc (ptr1),y
    sta intOp2 + 1
    bmi @IsDigitZero
    ; Still > 0 - save the number for the next loop
    dey
    lda intOp2
    sta intOp1
    lda intOp2 + 1
    sta intOp1 + 1
    inc tmp1
    jmp @LoopSub

@IsDigitZero:
    inc tmp2        ; move to the next entry
    inc tmp2        ; in tensTable
    lda tmp1        ; see if the current digit
    ora tmp3        ; is zero and we have not see a non-zero digit yet
    beq @LoopTbl    ; not yet - skip writing it
    lda #1
    sta tmp3        ; we have not seen a non-zero digit
    ; Digit is non-zero - print it
    clc
    lda tmp1
    adc #'0'
    ldy #0
    sta (ptr2),y
    clc
    lda ptr2
    adc #1
    sta ptr2
    lda ptr2 + 1
    adc #0
    sta ptr2 + 1
    jmp @LoopTbl

@PrintLastDigit:
    ; Print last digit
    clc
    lda intOp1
    adc #'0'
    ldy #0
    sta (ptr2),y

@Done:
    ; count the length of the null-terminated string in intBuf
    lda #<intBuf
    sta ptr2
    lda #>intBuf
    sta ptr2 + 1
    ldy #0
@L1:
    lda (ptr2),y
    beq @PadStr
    iny
    jmp @L1
@PadStr:
    tya
    tax
    lda tmp4
    jsr leftpad
    rts
.endproc

.proc clearbuf
    lda #0
    ldy #0
@Loop:
    sta (ptr2),y
    iny
    cpy #7
    bne @Loop
    rts
.endproc
