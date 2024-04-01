;
; screen80.s
; Ken Schenke (kenschenke@gmail.com)
;
; 80 column screen code for editor
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;

    .export     _drawRow80, _initScreen80, _setScreenBg80, _clearScreen80
    .import     popa, popax, incRow, petscii2Screen
    .importzp   ptr1, ptr2, ptr3, tmp1, tmp2

    .include    "c128.inc"

    ;; Registers
    VDC_SCREEN_ADDR = 12
    VDC_ATTR_HI = 20
    VDC_ATTR_LO = 21
    VDC_COLOR = 26
    NUM_COLS = 80

; void drawRow80(char row, char len, char *buf, unsigned char *rev)
;       ptr1 - char buffer
;       ptr2 = screen RAM
;       ptr3 - reverse buffer (or'd with chars)
;       tmp1 - length of buffer
;       tmp2 - row number, then # of chars to pad later
_drawRow80:
    sta ptr3        ; Low byte of rev buffer passed in .A
    stx ptr3+1      ; High byte of rev buffer passed in .X
    jsr popax       ; Pull the character buffer pointer off the stack
    sta ptr1        ; Low byte of char buffer
    stx ptr1+1      ; High byte of char buffer
    jsr popa        ; Pull the length off the stack
    sta tmp1        ; Store it for later use
    jsr popa        ; Pull the row number off the stack
    sta tmp2        ; Store it for later
    lda CHARMEM     ; Store the buffer for char memory
    sta ptr2        ; in ptr2 for incRow
    lda CHARMEM+1
    sta ptr2+1
    ldx tmp2
    ldy #NUM_COLS
    jsr incRow      ; Move ptr2 down to the row
    ; How many spaces to pad out the line?
    lda #NUM_COLS
    sec
    sbc tmp1
    sta tmp2
    ; Tell the VDC to write to screen memory
    ldx #VDC_DATA_HI
    lda ptr2+1
    jsr write80r    ; Set the high byte of the data buffer
    ldx #VDC_DATA_LO
    lda ptr2
    jsr write80r    ; Set the low byte of the data buffer
    ldy #$0
@LoopChar:
    lda tmp1
    beq @BeginFill
    lda (ptr1),y    ; Load the next byte
    jsr petscii2Screen
    ; Check if ptr3 is null.
    ldx ptr3        ; Look at the low byte of ptr3
    bne @DoRev
    ldx ptr3+1      ; Look at the high byte of ptr3
    beq @WriteChar  ; Both bytes were zero
@DoRev:
    ora (ptr3),y    ; "Or" the reverse bit (bit 7)
@WriteChar:
    ldx #VDC_RAM_RW
    jsr write80r    ; Write the character to screen memory
    iny
    dec tmp1
    bne @LoopChar
    ; Fill the rest of the line with spaces
@BeginFill:
    lda #' '
@LoopFill:
    ldy tmp2
    beq @Done
    ldx #VDC_RAM_RW
    jsr write80r
    dec tmp2
    bne @LoopFill
@Done:
    rts

_clearScreen80:
    ; Set the starting address for attribute memory
    ldx #VDC_DATA_HI
    lda CHARMEM+1
    jsr write80r
    ldx #VDC_DATA_LO
    lda CHARMEM
    jsr write80r
    ; Fill 2,000 bytes of character memory
    ; tmp1 = low byte, tmp2 = high byte
    ; 208 + 7*256 = 2000 (80 x 25)
    lda #208    ; low byte
    sta tmp1
    lda #8      ; high byte (+1 for one extra loop)
    sta tmp2
    lda #' '
    ldx #VDC_RAM_RW
@Loop:
    jsr write80r
    dec tmp1
    bne @Loop
    dec tmp2
    bne @Loop
    rts

_initScreen80:
    ldx #VDC_SCREEN_ADDR
    jsr read80r
    sta CHARMEM+1
    inx
    jsr read80r
    sta CHARMEM
    ; Initialize attribute memory
    ; Get the address of attr mem
    ldx #VDC_ATTR_HI
    jsr read80r
    sta tmp2
    ldx #VDC_ATTR_LO
    jsr read80r
    sta tmp1
    ; Set the starting address for attribute memory
    ldx #VDC_DATA_HI
    lda tmp2
    jsr write80r
    ldx #VDC_DATA_LO
    lda tmp1
    jsr write80r
    ; Fill 2,000 bytes of attribute memory
    ; tmp1 = low byte, tmp2 = high byte
    ; 208 + 7*256 = 2000 (80 x 25)
    lda #208    ; low byte
    sta tmp1
    lda #8      ; high byte (+1 for one extra loop)
    sta tmp2
    lda #$8f    ; white text, secondary char set
    ldx #VDC_RAM_RW
@Loop:
    jsr write80r
    dec tmp1
    bne @Loop
    dec tmp2
    bne @Loop
    rts

_setScreenBg80:
    ldx #VDC_COLOR
    jsr write80r
    rts

    ;; register # in X, value in A
read80r:
    stx VDC_INDEX
@Loop:
    bit VDC_INDEX
    bpl @Loop
    lda VDC_DATA
    rts

write80r:
    stx VDC_INDEX
@Loop:
    bit VDC_INDEX
    bpl @Loop
    sta VDC_DATA
    rts

CHARMEM: .byte 0, 0
