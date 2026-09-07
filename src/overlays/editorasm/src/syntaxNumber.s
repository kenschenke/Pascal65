;
; syntaxNumber.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; syntaxNumber routine

.include "editor.inc"
.include "zeropage.inc"
.include "tokenizer.inc"

.export syntaxNumber

.import syntaxIndex, syntaxCharCode

.bss

isReal: .res 1          ; Non-zero if a real number has been seen
sawPeriod: .res 1       ; Non-zero if a period (decimal point) is seen
sawExponent: .res 1     ; Non-zero if an 'e' or 'E' is seen
sawExponentSign: .res 1 ; Non-zero if a '+' or '-' or seen after the exponent
numberLength: .res 1    ; Number of characters part of this number

.code

; This routine is called when a digit is encountered. It processes characters,
; looking for additional digits, decimal points, and scientific notation.
; Once it reaches the end of a valid number, it sets the highlight code
; for the characters in the number.
;
; Input: A contains a 1 if a decimal point was already seen
.proc syntaxNumber
    sta sawPeriod
    lda #0
    sta sawExponent
    sta sawExponentSign
    sta numberLength
    sta isReal

    lda sawPeriod
    beq :+
    sta isReal

    ; Process the characters
:   ldz syntaxIndex
L1: nop
    lda (ptr1),z
    cmp #'.'
    bne L2
    ; Is the next character also a period? If so, it's the .. operator
    ; instead of being part of this number.
    jsr isPeriodNext
    beq L8
    lda #1
    sta isReal
    inz
    bra L1

    ; Look for an 'e' or 'E' (scientific notation)
L2: cmp #'e'
    beq :+
    cmp #'E'
    bne L3
:   lda isReal
    beq L8
    ; The 'e' is part of the number
    lda #1
    sta sawExponent
    inz
    bra L1

    ; Look for a '-' or '+' (part of scientific notation)
L3: cmp #'+'
    beq :+
    cmp #'-'
    bne L4
:   lda isReal
    beq L8
    lda sawExponent
    beq L8
    lda sawExponentSign
    bne L8
    lda #1
    sta sawExponentSign
    bra L7
    
    ; Is the character a digit
L4: nop
    lda (ptr1),z
    jsr syntaxCharCode
    cmp #ccDigit
    bne L8

    ; Move to the next character
L7: inz
    jmp L1

L8: stz tmp1
    ldz syntaxIndex
    lda #SYNTAXHL_NUMBER
:   nop
    sta (ptr2),z
    inz
    inc syntaxIndex
    cpz tmp1
    bne :-

    rts
.endproc

; This routine looks to see if the next character is a period.
; If so, the Z flag is set.
.proc isPeriodNext
    cpz syntaxIndex
    bcs :+
    lda #1
    rts

:   inz
    nop
    lda (ptr1),z
    pha
    dez
    pla
    cmp #'.'
    rts
.endproc
