;
; writeint.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Converts an integer into a PETSCII string
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

.include "int.inc"

.ifdef RUNTIME
.include "runtime.inc"
.else
.importzp ptr1, ptr2, tmp1, tmp2, tmp3, tmp4, intPtr
.import intOp1, intOp2, intOp32
.importzp sreg
.endif

.import tensTable32, spcl2147483648
.import isNegInt32, invertInt32, leftpad, geUint32, subInt32
.import signExtend8To32, signExtend16To32

.export writeInt8, writeUint8, writeInt16, writeUint16, writeInt32, writeUint32

; This routine converts the signed integer in intOp1/intOp2 into
; a string stored in the intBuf buffer as a series of PETSCII
; characters.  If bit 7 of the high byte is set, the number is
; treated as negative and a minus sign is written to the buffer.
;
; The routine works by seeing how many times the number goes into
; 1,000,000,000, then 100,000,000, then 10,000,000 and so on
; and finally 10.
;
; ptr1, ptr2, tmp1, tmp2, tmp3, and tmp4 are trashed as well as intOp32.
;
; ptr1 - used for accessing the tensTable32
; ptr2 - pointer to intBuf
; tmp1 - current digit
; tmp2 - current offset into tensTable32
; tmp3 - set to 0 until the first non-zero digit is seen in the number.
;        once this is 1, print all digits even if zero.
; tmp4 - width to right-align number in

NUM_WORDTBL = 36     ; nine entries * 4 bytes

.code

.proc writeInt8
    pha
    jsr signExtend8To32
    pla
    clc
    bcc writeInt32
.endproc

; This routine converts the unsigned 8-bit value in intOp1
.proc writeUint8
    pha
    lda #0
    ldx #2
L1:
    sta intOp1+1,x
    dex
    bpl L1
    pla
    clc
    bcc writeUint32
.endproc

.proc writeInt16
    pha
    jsr signExtend16To32
    pla
    clc
    bcc writeInt32
.endproc

.proc writeUint16
    pha
    lda #0
    sta intOp2
    sta intOp2 + 1
    pla
    ; fall through to writeUint32
.endproc

writeUint32:
    jsr setup
    clc
    bcc NotNeg

setup:
    sta tmp4
    lda intPtr
    sta ptr2
    lda intPtr + 1
    sta ptr2 + 1
    jsr clearbuf
    rts

; number to write is in intOp1/intOp2
; field width in .A
writeInt32:
    jsr setup
    ; See if the number is -2,147,483,648 : a special case.
    lda intOp1
    bne NotSpecl
    lda intOp1 + 1
    bne NotSpecl
    lda intOp2
    bne NotSpecl
    lda intOp2 + 1
    cmp #$80
    bne NotSpecl
    ; Number is -2,147,483,648
    ; This is important because any other number can be negated.
    lda #<spcl2147483648
    sta ptr1
    lda #>spcl2147483648
    sta ptr1 + 1
    ldy #0
    ; Print -2147483648 to the screen then return
LSpecl:
    lda (ptr1),y
    beq JmpDone
    sta (ptr2),y
    iny
    bne LSpecl

NotSpecl:
    ; Number is not -2,147,483,648
    jsr isNegInt32       ; Is it negative?
    beq NotNeg
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
    jsr invertInt32      ; Make it a positive number
    clc
    bcc NotNeg

JmpDone:
    clc
    bcc Done

NotNeg:
    ; Loop through tensTable32, comparing values until intOp1/intOp2 is less.
    ; If the count is > 0 then write the digit.
    lda #0
    sta tmp3
    lda #<tensTable32
    sta ptr1
    lda #>tensTable32
    sta ptr1 + 1
    lda #0
    sta tmp2
LoopTbl:
    lda #0
    sta tmp1
    lda tmp2            ; current index into table
    cmp #NUM_WORDTBL    ; end of the table?
    beq PrintLastDigit
    tay
LoopSub:
    ldx #0
LoopComp:
    lda (ptr1),y
    sta intOp32,x
    iny
    inx
    cpx #4
    bne LoopComp
    jsr geUint32
    beq IsDigitZero     ; intOp1/intOp2 < tensTable -- digit is zero
    ; intOp1/intOp2 > tensTable.  Subtract the current tensTable value
    ; and go around for another loop
    jsr subInt32
    ; Still > 0 - save the number for the next loop
    dey
    dey
    dey
    dey
    inc tmp1
    bne LoopSub

IsDigitZero:
    clc
    lda tmp2
    adc #4          ; move to the next entry
    sta tmp2        ; in tensTable32
    lda tmp1        ; see if the current digit
    ora tmp3        ; is zero and we have not seen a non-zero digit yet
    beq LoopTbl    ; not yet - skip writing it
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
    clc
    bcc LoopTbl

PrintLastDigit:
    ; Print last digit
    clc
    lda intOp1
    adc #'0'
    ldy #0
    sta (ptr2),y

Done:
    ; count the length of the null-terminated string in intBuf
    ldy #0
L1:
    lda (intPtr),y
    beq PadStr
    iny
    bne L1
PadStr:
    tya
    tax
    lda tmp4
    jsr leftpad
    rts

.proc clearbuf
    lda #0
    ldy #0
Loop:
    sta (ptr2),y
    iny
    cpy #INTBUFLEN - 1
    bne Loop
    rts
.endproc
