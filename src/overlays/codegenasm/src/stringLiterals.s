;
; stringLiteral.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; string literal routines

.include "asmlib.inc"
.include "zeropage.inc"
.include "cbm_kernal.inc"
.include "4510macros.inc"

.export addStringLiteral, initStringLiterals, writeStringLiterals, freeStringLiterals

.import strbuf, incCodeOffset

.bss

stringLiterals: .res 4
buf: .res 1
index: .res 1

.code

.proc addStringLiteral
    pha
    phx

    ldq stringLiterals
    jsr isQZero
    bne L1
    jsr allocMemBuf
    stq stringLiterals

    ; Write the label
L1: pla
    sta ptr2+1
    pla
    sta ptr2
    lda #0
    sta ptr2+2
    sta ptr2+3
    ldq stringLiterals
    stq ptr1

    ; Count the label length and write the label
    ldz #0
:   nop
    lda (ptr2),z
    beq :+
    inz
    bne :-
:   inz
    tza
    ldx #0
    jsr writeToMemBuf

    ; Count the string literal length and write the string literal
    lda #<strbuf
    sta ptr2
    lda #>strbuf
    sta ptr2+1
    lda #0
    sta ptr2+2
    sta ptr2+3
    ldq stringLiterals
    stq ptr1
    ldx #0
:   lda strbuf,x
    beq :+
    inx
    bne :-
:   inx
    txa
    ldx #0
    jsr writeToMemBuf

    rts
.endproc

.proc freeStringLiterals
    ldq stringLiterals
    jsr isQZero
    bne :+
    rts

:   jsr freeMemBuf
    rts
.endproc

.proc initStringLiterals
    lda #0
    tax
    tay
    taz
    stq stringLiterals
    rts
.endproc

.proc writeStringLiterals
    ldq stringLiterals
    jsr isQZero
    bne :+
    rts

:   stq ptr1
    lda #0
    tax
    jsr setMemBufPos

    ldx #1
    jsr CHKOUT

    ; Loop through the string literals
L1: ldq stringLiterals
    jsr isMemBufAtEnd
    beq L5

    ; Read the label from the membuf
    lda #0
    sta index

L2: lda #<buf
    sta ptr2
    lda #>buf
    sta ptr2+1
    lda #0
    sta ptr2+2
    sta ptr2+3
    ldq stringLiterals
    stq ptr1
    lda #1
    ldx #0
    jsr readFromMemBuf
    ldx index
    lda buf
    sta strbuf,x
    beq L3
    inc index
    bne L2

L3: lda #<strbuf
    ldx #>strbuf
    jsr linkAddressSet

    ; Read the string literal and write it to the object file
L4: lda #<buf
    sta ptr2
    lda #>buf
    sta ptr2+1
    lda #0
    sta ptr2+2
    sta ptr2+3
    ldq stringLiterals
    stq ptr1
    lda #1
    ldx #0
    jsr readFromMemBuf
    lda buf
    jsr CHROUT
    lda #1
    jsr incCodeOffset
    lda buf
    bne L4

    ; Keep reading string literals
    bra L1

L5: rts
.endproc
