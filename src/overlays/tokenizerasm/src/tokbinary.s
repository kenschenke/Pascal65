;
; tokbinary.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; getBinaryToken routine

.include "tokenizer.inc"
.include "zeropage.inc"
.include "4510macros.inc"

.export getBinaryToken

.import tokenCode, getChar, tokenValue, numberSize, tokenString

.bss

ch: .res 1
digitCount: .res 1

.code

; This routine tokenizes a binary literal. The caller has already consumed
; the % so the routine starts with the first digit of the binary number.
;
; On exit, tokenCode contains tcNumber and tokenizerCode contains either
; tzByte, tzWord, or tzCardinal.
.proc getBinaryToken
    ; Clear intOp1/2
    lda #0
    ldx #3
:   sta intOp1,x
    dex
    bpl :-

    ; Write a '%' to tokenString
    lda #'%'
    sta tokenString
    lda #1
    sta digitCount

L1: jsr getChar
    sta ch
    cmp #'0'
    beq L2
    cmp #'1'
    bne L5

L2: sec
    sbc #'0'
    sta tmp1

    ; Add the digit
L3: lda intOp1
    ora intOp1+1
    ora intOp1+2
    ora intOp1+3
    beq L4
    ; Shift intOp1 left by 1 position
    asl intOp1
    rol intOp1+1
    rol intOp1+2
    rol intOp1+3

L4: lda intOp1
    ora tmp1
    sta intOp1

    lda ch
    ldx digitCount
    sta tokenString,x
    inc digitCount

    bra L1

    ; Copy the number to tokenValue
L5: ldx #3
:   lda intOp1,x
    sta tokenValue,x
    dex
    bpl :-

    ; Null-terminate tokenString
    lda #0
    ldx digitCount
    sta tokenString,x

    jsr numberSize

    lda #tcNumber
    sta tokenCode
    rts
.endproc
