.include "runtime.inc"

.export trim

.import loadParam, returnVal, copyString

startY = tmp3
newLen = tmp2

; This routine counts the length of a string after space characters
; would be removed. It is called before allocating the new string.
; The length is returned in A
; Starting index for first non-space returned in Y.
;
; The string is expected in ptr1
.proc trimmedLen
    ldy #0
    sty newLen
    sty startY          ; index of first non-space
    lda (ptr1),y
    beq RT
    sta tmp1
    ; Loop until a space is found or the string length is reached
:   iny
    inc startY
    lda (ptr1),y
    cmp #' '
    beq :-
    ; The first first non-space is found. Go to the end of the string
    ; and move backwards until a non-space is found or the start is reached.
    ldy #0
    lda (ptr1),y
    tay
:   lda (ptr1),y
    cmp #' '
    bne DN
    dey
    bne :-
    beq RT
DN: tya
    sec
    sbc startY
    sta newLen
    inc newLen
RT: rts
.endproc

.proc trim
    lda #0
    jsr loadParam
    sta ptr1
    stx ptr1 + 1
    jsr trimmedLen
    lda ptr1
    clc
    adc startY
    bcc :+
    inc ptr1 + 1
:   ldx ptr1 + 1
    ldy newLen
    jsr copyString
    pha
    txa
    pha
    lda #0
    sta sreg
    sta sreg + 1
    pla
    tax
    pla
    jmp returnVal
.endproc
