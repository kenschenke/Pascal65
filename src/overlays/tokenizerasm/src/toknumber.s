;
; toknumber.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; getNumberToken routine

.include "tokenizer.inc"
.include "error.inc"
.include "asmlib.inc"
.include "zeropage.inc"

MAX_NUMBER_LEN = 15

.export getNumberToken

.import tokenCode, tokenizerCode, getCurrentChar, putBackChar, getChar, tokenString
.import getCharCode, tokenValue, numberSize

.bss

ch: .res 1
digitCount: .res 1
countErrorFlag: .res 1
sawDecimalPoint: .res 1
sawExponent: .res 1
sawExponentSign: .res 1

.data

maxDigitCount: .byte 20

.code

; This routine converts digits from the input buffer into a number.
; If the number is an integer, it is converted into an 8, 16, or 32-bit
; number. Otherwise, it is left as a string (real).
;
; Input: If the carry flag is set then the tokenizer has already encountered
; a decimal point.
;
; On exit, tokenCode contains tcNumber and tokenizerCode contains either
; tzByte, tzWord, or tzCardinal.
.proc getNumberToken
    lda #0
    bcc :+
    lda #1
:   sta sawDecimalPoint

    ; Clear a few local variables
    lda #0
    sta digitCount
    sta countErrorFlag
    sta sawExponent
    sta sawExponentSign

    ; Start off with tokenizerCode set to tzDummy
    lda #tzDummy
    sta tokenizerCode

    jsr getCurrentChar
    sta ch
    jsr getCharCode
    cmp #ccDigit
    beq :+
    rts

    ; If sawDecimalPoint is non-zero, this call came from
    ; getSpecialToken when it saw a decimal point followed
    ; by a digit. The digit was put back but the decimal
    ; point needs to be preserved.
:   lda sawDecimalPoint
    beq L1                  ; Branch if not decimal point encountered yet
    ldx digitCount
    lda #'.'
    sta tokenString,x
    inc digitCount
    lda #tzReal
    sta tokenizerCode

    ; Accumulate the value as long as the total allowable
    ; number of digits has not been exceeded.
L1: lda ch
    cmp #'.'
    bne L2
    ; If we already saw a decimal point then this is another one
    ; and not part of the number.
    lda sawDecimalPoint
    beq :+
    jsr putBackChar
    jmp L8

    ; If type is tzReal then we have already seen a decimal point
    ; and this one is not part of the number.
:   lda tokenizerCode
    cmp #tzReal
    bne :+
    jsr putBackChar
    jmp L8

    ; Look at the next character and see if's a decimal point too.
    ; If so, this is actually then '..' operator.
:   jsr getChar
    sta ch
    cmp #'.'
    bne :+
    ; We have a '..' operator. Put the character back so that the
    ; token can be extracted next.
    jsr putBackChar
    bra L8
:   lda #tzReal
    sta tokenizerCode
    lda #'.'
    ldx digitCount
    sta tokenString,x
    inc digitCount

    ; Look for 'e' or 'E' (scientific notation)
L2: cmp #'e'
    beq :+
    cmp #'E'
    bne L3
:   lda tokenizerCode
    cmp #tzReal
    beq :+
    ; This is not part of the number.
    bra L1
:   lda #1
    sta sawExponent
    bra L7

    ; Look for a '-' or '+' (part of scientific notation)
L3: cmp #'-'
    beq :+
    cmp #'+'
    bne L4
:   ldx tokenizerCode
    cpx #tzReal
    bne L8
    ldx sawExponent
    beq L8
    ldx sawExponentSign
    bne L8
    lda #1
    sta sawExponentSign
    bra L7

    ; Is the character a digit?
L4: lda ch
    jsr getCharCode
    cmp #ccDigit
    bne L8

    ; Record the character
L7: lda ch
    ldx digitCount
    sta tokenString,x
    inc digitCount
    lda digitCount
    cmp maxDigitCount
    bcc :+
    lda #1
    sta countErrorFlag
:   jsr getChar
    sta ch
    jmp L1

L8: ldx digitCount
    lda #0
    sta tokenString,x
    lda tokenizerCode
    cmp #tzDummy
    bne L9

    ; Convert the number string to an integer
    lda #<tokenString
    ldx #>tokenString
    jsr readInt32

    ; Copy the number to tokenValue
    ldx #3
:   lda intOp1,x
    sta tokenValue,x
    dex
    bpl :-

    jsr numberSize

L9: ldx #tcNumber
    lda countErrorFlag
    beq :+
    ldx #tcError
:   stx tokenCode
    rts
.endproc
