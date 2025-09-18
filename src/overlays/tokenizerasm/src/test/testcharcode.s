.include "cbm_kernal.inc"
.include "tokenizer.inc"
.include "zeropage.inc"

.export testCharCode

.import getCharCode

.data

okMsg: .asciiz "okay"
failMsg: .asciiz "fail"
specialChars: .byte "+-*/=^.,<>()[]:;!&@", $0

.bss

charCodes: .res 256

.code

.proc setupCharCodes
    lda #ccError
    ldx #0
:   sta charCodes,x
    inx
    bne :-

    lda #ccLetter

    ldx #65
:   sta charCodes,x
    inx
    cpx #91
    bne :-

    ldx #97
:   sta charCodes,x
    inx
    cpx #123
    bne :-

    ldx #193
:   sta charCodes,x
    inx
    cpx #219
    bne :-

    ; Special
    ldy #0
:   lda specialChars,y
    beq :+
    tax
    lda #ccSpecial
    sta charCodes,x
    iny
    bne :-

:   lda #ccDigit
    ldx #'0'
:   sta charCodes,x
    inx
    cpx #'9'+1
    bne :-

    lda #ccQuote
    ldx #'''
    sta charCodes,x

    lda #ccWhiteSpace
    ldx #' '
    sta charCodes,x
    ldx #9
    sta charCodes,x
    inx
    sta charCodes,x
    ldx #13
    sta charCodes,x
    ldx #0
    sta charCodes,x

    lda #ccDollar
    ldx #'$'
    sta charCodes,x

    lda #ccHash
    ldx #'#'
    sta charCodes,x

    lda #ccPercent
    ldx #'%'
    sta charCodes,x

    lda #ccEndOfFile
    ldx #$7f
    sta charCodes,x

    rts
.endproc

.proc testCharCode
    jsr setupCharCodes

    lda #0
    sta tmp1
:   lda tmp1
    jsr getCharCode
    ldx tmp1
    cmp charCodes,x
    bne FAIL
    inc tmp1
    bne :-
    bra OK

FAIL:
    lda #<failMsg
    sta ptr1
    lda #>failMsg
    sta ptr1+1
    bra printz

OK: lda #<okMsg
    sta ptr1
    lda #>okMsg
    sta ptr1+1
    ; Fall through to printz
.endproc

.proc printz
    ldy #0
:   lda (ptr1),y
    beq :+
    jsr CHROUT
    iny
    bne :-
:   lda #13
    jmp CHROUT
.endproc
