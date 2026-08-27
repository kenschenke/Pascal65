;
; tokhex.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; getHexToken routine

.include "tokenizer.inc"
.include "zeropage.inc"
.include "4510macros.inc"
.include "asmlib.inc"

.export getHexToken

.import tokenCode, tokenizerCode, getChar, getCharCode, tokenValue, numberSize
.import tokenString

.bss

ch: .res 1
digitCount: .res 1

.code

; This routine tokenizes a hexidecimal number literal. The caller has already consumed
; the $ so the routine starts with the first digit of the hex number.
;
; On exit, tokenCode contains tcNumber and tokenizerCode contains either
; tzByte, tzWord, or tzCardinal.
.proc getHexToken
    ; Clear intOp1/2
    lda #0
    ldx #3
:   sta intOp1,x
    dex
    bpl :-

    ; Clear intOp32
    lda #0
    ldx #3
:   sta intOp32,x
    dex
    bpl :-

    ; Write a '$' to tokenString
    lda #'$'
    sta tokenString
    lda #1
    sta digitCount

L1: jsr getChar
    sta ch
    jsr getCharCode
    cmp #ccLetter
    beq L2
    cmp #ccDigit
    bne L5

    ; Digit
    lda ch
    sec
    sbc #'0'
    sta intOp32
    bra L3

    ; Letter
L2: lda ch
    and #$7f            ; Convert to lower-case
    ; Make sure it's between 'a' and 'f'
    cmp #'a'
    bcc L5
    cmp #'g'
    bcs L5
    sec
    sbc #'a'
    clc
    adc #10
    sta intOp32

    ; Add the digit
L3: lda intOp1
    ora intOp1+1
    ora intOp1+2
    ora intOp1+3
    beq L4
    ; Shift intOp1 left by 4 positions
    ldx #4
:   asl intOp1
    rol intOp1+1
    rol intOp1+2
    rol intOp1+3
    dex
    bne :-

L4: ldq intOp1
    orq intOp32
    stq intOp1

    ; Write the digit to tokenString
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
