.include "runtime.inc"

.export loadParam, returnVal, copyString, isAlpha

; This routine calculates the address of a parameter and
; leaves it in ptr1.
; parameter number (0-based) in A.
.proc calcParam
    tax                 ; Parameter number in X
    lda stackP
    sec
    sbc #20             ; first parameter is 20 bytes below stack frame ptr
    sta ptr1
    lda stackP + 1
    sbc #0
    sta ptr1 + 1
    cpx #0
    beq DN
:   lda ptr1
    sec
    sbc #4
    sta ptr1
    lda ptr1 + 1
    sbc #0
    sta ptr1 + 1
    dex
    bne :-
DN: rts
.endproc

; This routine loads a parameter off the runtime stack
; into A/X/sreg.
;
; Parameter number in A (0-based)
.proc loadParam
    jsr calcParam
    ldy #3
    lda (ptr1),y
    sta sreg + 1
    dey
    lda (ptr1),y
    sta sreg
    dey
    lda (ptr1),y
    tax
    dey
    lda (ptr1),y
    rts
.endproc

; This routine stores the value in A/X/sreg into the
; return value spot in the current stack frame.
.proc returnVal
    pha
    lda stackP
    sec
    sbc #4
    sta ptr1
    lda stackP + 1
    sbc #0
    sta ptr1 + 1
    ldy #0
    pla
    sta (ptr1),y
    txa
    iny
    sta (ptr1),y
    lda sreg
    iny
    sta (ptr1),y
    lda sreg + 1
    iny
    sta (ptr1),y
    rts
.endproc

; This routine allocates a string object and copies the source.
; The source is passed in A/X.
; The length to copy is passed in Y.
; The new string is returned in A/X.
.proc copyString
    pha
    txa
    pha
    tya
    pha
    ldx #0
    clc
    adc #1
    jsr rtHeapAlloc
    sta ptr2
    stx ptr2 + 1
    pla
    tax
    pla
    sta ptr1 + 1
    pla
    sta ptr1
    ldy #0
    txa
    sta (ptr2),y
    beq DN
:   lda (ptr1),y
    iny
    sta (ptr2),y
    dex
    bne :-
DN: lda ptr2
    ldx ptr2 + 1
    rts
.endproc

; This routine returns a 0 or 1 in X if the
; PETSCII character in A is a letter
.proc isAlpha
    cmp #'a'
    bcc NO          ; branch if < 'a'
    cmp #'z'+1
    bcc YS          ; branch if <= 'z'
    cmp #'A'
    bcc NO          ; branch if < 'A'
    cmp #'Z'+1
    bcc YS          ; branch if <= 'Z'
NO: ldx #0
    rts
YS: ldx #1
    rts
.endproc
