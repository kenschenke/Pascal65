; Play with screen buffer stuff

.include "cbm_kernal.inc"

.import popa, petscii2Screen
.importzp ptr1, ptr2, tmp1
; ptr1: screen
; ptr2: buffer

.export _kenTestTyping, _kenTestScrolling, _screenInsertChar, _screenDeleteChar
.export _screenScrollDown, _screenScrollUp

.data

msg: .asciiz "hello world"

.bss

curX: .res 1
curY: .res 1
buf: .res 40

.code

; Gets key and returns in A
.proc getkey
L1:
    jsr GETIN
    cmp #32
    bcc L1
    rts
.endproc

.proc dumprow
    ldy #0
L1:
    lda (ptr2),y
    sta (ptr1),y
    iny
    cpy #40
    bcc L1
    rts
.endproc

.proc fillrow
    lda #<buf
    sta ptr2
    lda #>buf
    sta ptr2 + 1
    ldy #0
    lda #'a'
L1:
    sta (ptr2),y
    tax
    inx
    txa
    iny
    cpy #40
    bcc L1
    rts
.endproc

; Row number (0-based) in X
; Address returned in ptr1
.proc calcRowAddr
    inx                     ; Add one to row
    ; Start with ptr1 at $400 (base of screen memory)
    lda #0
    sta ptr1
    lda #4
    sta ptr1 + 1
    ; Add 40 for every row
L1:
    dex                     ; Decrement row
    beq L2                  ; Branch if zero
    lda ptr1                ; Add 40 to ptr1
    clc
    adc #40
    sta ptr1
    lda ptr1 + 1
    adc #0
    sta ptr1 + 1
    jmp L1
L2:
    rts
.endproc

; void screenDeleteChar(char ch, char col, char row)
.proc _screenDeleteChar
    tax                     ; Copy row to X
    jsr calcRowAddr
    jsr popa                ; Pop col number off call stack
    sta tmp1                ; Store it in tmp1
    lda #40                 ; Start at column 40
    sec                     ; Clear for subtraction
    sbc tmp1                ; 40 - column = # of chars to copy
    beq L2                  ; Branch if no chars to copy
    tax                     ; # of chars to copy in X
    ldy tmp1                ; Start at next to last column
L1:
    iny
    lda (ptr1),y
    dey
    sta (ptr1),y
    iny
    dex
    bne L1
L2:
    jsr popa
    ldy #39
    jsr petscii2Screen
    sta (ptr1),y
    rts
.endproc

; void screenInsertChar(char ch, char col, char row)
.proc _screenInsertChar
    tax                     ; Copy row to X
    jsr calcRowAddr
    jsr popa                ; Pop col number off call stack
    sta tmp1                ; Store it in tmp1
    ldy #$ff
    lda #40                 ; Start at column 40
    sec                     ; Clear for subtraction
    sbc tmp1                ; 40 - column = # of chars to copy
    beq L2                  ; Branch if no chars to copy
    tax                     ; # of chars to copy in X
    ldy #39                 ; Start at next to last column
L1:
    dey
    lda (ptr1),y
    iny
    sta (ptr1),y
    dey
    dex
    bne L1
L2:
    iny
    sty tmp1
    jsr popa
    jsr petscii2Screen
    ldy tmp1
    sta (ptr1),y
    rts
.endproc

; This routine scrolls rows up by one, starting at the specified row.
; void screenScrollUp(char startingRow)
.proc _screenScrollUp
    sta curY
    tax
    jsr calcRowAddr
    lda ptr1
    clc
    adc #40
    sta ptr2
    lda ptr1 + 1
    adc #0
    sta ptr2 + 1
    lda #24
    sec
    sbc curY
    tax                     ; X now contains the number of rows to copy
L1:
    ldy #39
L2:
    lda (ptr2),y
    sta (ptr1),y
    dey
    bpl L2
    lda ptr1
    clc
    adc #40
    sta ptr1
    lda ptr1 + 1
    adc #0
    sta ptr1 + 1
    lda ptr2
    clc
    adc #0
    sta ptr2
    lda ptr2 + 1
    adc #0
    sta ptr2 + 1
    dex
    bne L1
    rts
.endproc

; This routine scrolls rows down by one, starting at the specified row
; void screenScrollDown(char startingRow)
.proc _screenScrollDown
    sta curY
    lda #24
    sec
    sbc curY
    tax                     ; X now contains the number of rows to scroll
    lda #$98
    sta ptr1
    lda #7                  ; ptr1 = $798 (start of row 23)
    sta ptr1 + 1
    sta ptr2 + 1
    lda #$c0
    sta ptr2                ; ptr2 = $7c0 (start of row 24)
L1:
    ldy #39
L2:
    lda (ptr2),y
    sta (ptr1),y
    dey
    bpl L2
    lda ptr1
    sec
    sbc #40
    sta ptr1
    lda ptr1 + 1
    sbc #0
    sta ptr1 + 1
    lda ptr2
    sec
    sbc #0
    sta ptr2
    lda ptr2 + 1
    sbc #0
    sta ptr2 + 1
    dex
    bne L1
    rts
.endproc

.proc savechr
    pha
    ldy #38
L1:
    lda (ptr2),y
    iny
    sta (ptr2),y
    sta (ptr1),y
    dey
    dey
    cpy curX
    bpl L1
    ldy curX
    pla
    sta (ptr2),y
    sta (ptr1),y
    inc curX
    rts
.endproc

.proc _kenTestTyping
    lda #147
    jsr CHROUT
    jsr fillrow
    lda #0
    sta curX
    lda #0
    sta ptr1
    lda #4
    sta ptr1 + 1
    jsr dumprow
L1:
    jsr getkey
    jsr savechr
    jmp L1
L99:
    rts
.endproc

.proc initMsg
    lda #147
    jsr CHROUT
    ldx #14
    ldy #0
L1:
    lda msg,y
    sta $400,x
    iny
    cpy #11
    beq L2
    inx
    jmp L1
L2:
    rts
.endproc

.proc scrollUp
    lda #$28
    sta ptr1
    lda #4
    sta ptr1 + 1
    lda #0
    sta ptr2
    lda #4
    sta ptr2 + 1
    ldx #0
L1:
    ldy #0
L2:
    lda (ptr1),y
    sta (ptr2),y
    iny
    cpy #$28
    bne L2
    lda ptr1
    clc
    adc #$28
    sta ptr1
    lda ptr1 + 1
    adc #0
    sta ptr1 + 1
    lda ptr2
    clc
    adc #$28
    sta ptr2
    lda ptr2 + 1
    adc #0
    sta ptr2 + 1
    inx
    cpx #25
    bne L1
    ldx #0
    lda #' '
L3:
    sta $7c0,x
    inx
    cpx #$28
    bne L3
    rts
.endproc

.proc scrollDown
    lda #$98
    sta ptr1
    lda #7
    sta ptr1 + 1
    lda #$c0
    sta ptr2
    lda #7
    sta ptr2 + 1
    ldx #0
L1:
    ldy #0
L2:
    lda (ptr1),y
    sta (ptr2),y
    iny
    cpy #$28
    bne L2
    lda ptr1
    sec
    sbc #$28
    sta ptr1
    lda ptr1 + 1
    sbc #0
    sta ptr1 + 1
    lda ptr2
    sec
    sbc #$28
    sta ptr2
    lda ptr2 + 1
    sbc #0
    sta ptr2 + 1
    inx
    cpx #25
    bne L1
    ldx #0
    lda #' '
L3:
    sta $400,x
    inx
    cpx #$28
    bne L3
    rts
.endproc

.proc _kenTestScrolling
    jsr initMsg
    lda #0
    sta curY
L1:
    lda curY
    cmp #24
    beq L2
    jsr scrollDown
    inc curY
    jmp L1
L2:
    lda #0
    sta curY
L3:
    lda curY
    cmp #24
    beq L99
    jsr scrollUp
    inc curY
    jmp L3
L99:
    jmp _kenTestScrolling
.endproc
