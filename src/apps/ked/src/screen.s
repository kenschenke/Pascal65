
; void __fastcall__ clearScreen128(void);
; void __fastcall__ initScreen128(void);
; void __fastcall__ setScreenBg128(char bg);
; void __fastcall__ drawRow128(char row, char len, char *buf);

    .export     _drawRow128, _initScreen128, _setScreenBg128, _clearScreen128
    .import     popa, popax
    .importzp   ptr1, ptr2, ptr3, tmp1, tmp2

    .include    "c128.inc"

    ;; Registers
    VDC_SCREEN_ADDR = 12
    VDC_ATTR_HI = 20
    VDC_ATTR_LO = 21
    VDC_COLOR = 26
    NUM_COLS = 80

; Increment the address in ptr2 by 80 bytes per row
; row passed in .X
incRow:
    beq @Done       ; If .X is zero we're done
    lda ptr2        ; Load low byte for address from ptr2
    clc
    adc #$50        ; 80 chars per row
    sta ptr2        ; Store the low byte
    lda ptr2+1      ; Load the high byte
    adc #$0         ; Add the carry bit
    sta ptr2+1      ; Store the high byte
    dex
    jmp incRow
@Done:
    rts

; void drawRow128(char row, char len, char *buf, unsigned char *rev)
;       ptr1 - char buffer
;       ptr2 = screen RAM
;       ptr3 - reverse buffer (or'd with chars)
;       tmp1 - length of buffer
;       tmp2 - row number, then # of chars to pad later
_drawRow128:
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
    jsr convert     ; Convert from PETSCII to screen char
    ora (ptr3),y    ; "Or" the reverse bit (bit 7)
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

_clearScreen128:
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

_initScreen128:
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

_setScreenBg128:
    ldx #VDC_COLOR
    jsr write80r
    rts

convert:
    cmp #$20    ; if a < 32
    bcc convRev

    cmp #$60    ; if a < 96
    bcc conv1

    cmp #$80    ; if a < 128
    bcc conv2

    cmp #$a0    ; if a < 160
    bcc conv3

    cmp #$c0    ; if a < 192
    bcc conv4

    cmp #$ff    ; if a < 255
    bcc convRev

    lda #$7e
    bne convEnd

conv2:
    and #$5f
    bne convEnd

conv3:
    ora #$40
    bne convEnd

conv4:
    eor #$c0
    bne convEnd

conv1:
    and #$3f
    bpl convEnd

convRev:
    eor #$80
convEnd:
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
