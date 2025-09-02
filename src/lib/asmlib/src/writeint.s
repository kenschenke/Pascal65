;
; writeint.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; writeInt16 routine

.include "zeropage.inc"

.export writeInt16

.import subInt16, geInt16, invertInt16

NUM_TENSTABLE = 8      ; 4 entries * 2 bytes
INTBUFLEN = 7

.bss

intBuf: .res 7          ; null-terminated petscii number

.data

tensTable:
    .word 10000
    .word 1000
    .word 100
    .word 10
    .word 1

spcl32768:
    .asciiz "-32768"

.code

; This routine converts the signed integer in intOp1 into
; a string stored in the caller's buffer as a series of PETSCII
; characters. If bit 7 of the high byte is set, the number is
; treated as negative and a minus sign in written to the buffer.
;
; A pointer to the buffer is passed in A/X. It must be in bank 0.
;
; This routine works by seeing how many times the number goes into
; 10,000 then 1,000 then 100 and finally 10.
;
; ptr1 - used for accessing tensTable
; ptr2 - pointer to intBuf
; tmp1 - current digit
; tmp2 - current offset into tensTable
; tmp3 - set to 0 until the first non-zero digit is seen in the number.
;        once this is 1, print all digits even if zero.

.proc writeInt16
    jsr setup
    ; See if the number is -32,768 : a special case
    lda intOp1
    bne L1
    lda intOp1+1
    cmp #$80
    bne L1
    ; Number is -32,768
    ; This is important because any other number can be negated
    lda #<spcl32768
    sta ptr1
    lda #>spcl32768
    sta ptr1+1
    ldy #0
    ; Copy spcl32768 to intBuf then return
    ldy #0
:   lda (ptr1),y
    beq :+
    sta (ptr2),y
    iny
    bne :-
:   rts
L1: lda intOp1+1
    and #$80
    beq :+
    jsr invertInt16
    lda #'-'        ; negative - add minus sign
    ldy #0
    sta (ptr2),y
    inw ptr2
:   ; Loop through tensTable, comparing values until intOp1 is less.
    ; If the count is > 0 then write the digit.
    lda #0
    sta tmp2
    sta tmp3
    lda #<tensTable
    sta ptr1
    lda #>tensTable
    sta ptr1+1
L2: lda #0
    sta tmp1
    lda tmp2            ; current index into table
    cmp #NUM_TENSTABLE
    beq PrintLastDigit
    tay
L3: ldx #0
    lda (ptr1),y
    sta intOp2
    iny
    lda (ptr1),y
    iny
    sta intOp2+1
L4: jsr geInt16
    beq IsDigitZero     ; intOp1 < tensTable -- digit is zero
    ; intOp1 > tensTable. Subtract current tensTable value
    ; and go around for another loop
    jsr subInt16
    ; Still > 0 - save the number for the next loop
    inc tmp1
    bne L4
IsDigitZero:
    inc tmp2
    inc tmp2
    lda tmp1            ; see if the current digit
    ora tmp3            ; is zero and we have not see a non-zero digit yet
    beq L2              ; not yet - skip writing it
    lda #1
    sta tmp3            ; we have not seen a non-zero digit yet
    ; Digit is non-zero - print it
    clc
    lda tmp1
    adc #'0'
    ldy #0
    sta (ptr2),y
    inw ptr2
    jmp L2
PrintLastDigit:
    clc
    lda intOp1
    adc #'0'
    ldy #0
    sta (ptr2),y

Done:
    rts
.endproc

.proc clearbuf
    lda #0
    ldy #INTBUFLEN-1
:   sta (ptr2),y
    dey
    bpl :-
    rts
.endproc

.proc setup
    sta ptr2
    stx ptr2+1
    jmp clearbuf
.endproc