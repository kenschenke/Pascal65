
; void __fastcall__ clearScreen40(void);
; void __fastcall__ drawRow40(char row, char len, char *buf);

    .export     _drawRow40, _clearScreen40, _setScreenBg40, _initScreen40
    .import     popa, popax, incRow, petscii2Screen
    .importzp   ptr1, ptr2, ptr3, tmp1, tmp2, tmp3

    .include    "c64.inc"

    ;; Registers
    NUM_COLS = 40

; Fill screen memory
;   .A byte to fill
;   .X low byte of memory
;   .Y high byte of memory
fillMem:
    ; ptr2      Screen memory
    ; tmp1      Row count
    ; tmp2      byte to fill
    ; Set the starting address for attribute memory
    sta tmp2
    lda #25         ; 25 rows
    sta tmp1
    stx ptr2
    sty ptr2+1
@NewRow:
    lda tmp2
    ldy #NUM_COLS
@Clear:
    dey
    sta (ptr2),y
    bne @Clear
@DoneRow:
    lda ptr2
    clc
    adc #NUM_COLS
    sta ptr2
    lda ptr2+1
    adc #0
    sta ptr2+1
    dec tmp1
    bne @NewRow
    rts

; void setScreenBg40(char bg)
_setScreenBg40:
    sta 53280
    sta 53281
    rts

_initScreen40:
    lda #1      ; white text
    ldx #0
    ldy #$d8    ; color ram
    jmp fillMem

; void drawRow40(char row, char col, char len, char *buf, unsigned char *rev)
;       ptr1 - char buffer
;       ptr2 = screen RAM
;       ptr3 - reverse buffer (or'd with chars)
;       tmp1 - length of buffer
;       tmp2 - row number, then # of chars to pad later
;       tmp3 - col number to start rendering
_drawRow40:
    sta ptr3        ; Low byte of rev buffer passed in .A
    stx ptr3+1      ; High byte of rev buffer passed in .X
    jsr popax       ; Pull the character buffer pointer off the stack
    sta ptr1        ; Low byte of char buffer
    stx ptr1+1      ; High byte of char buffer
    jsr popa        ; Pull the length off the stack
    sta tmp1        ; Store it for later use
    jsr popa        ; Pull the column number off the stack
    sta tmp3        ; Store it for later
    jsr popa        ; Pull the row number off the stack
    sta tmp2        ; Store it for later
    lda #$00        ; Store the buffer for char memory
    sta ptr2        ; in ptr2 for incRow
    lda #$04
    sta ptr2+1
    ldx tmp2
    ldy #NUM_COLS
    jsr incRow      ; Move ptr2 down to the row
    ; Add the starting column
    clc
    lda ptr2
    adc tmp3
    sta ptr2
    lda ptr2 + 1
    adc #0
    sta ptr2 + 1
    ; How many spaces to pad out the line?
    lda #NUM_COLS
    sec
    sbc tmp1
    sta tmp2
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
    sta (ptr2),y
    iny
    dec tmp1
    bne @LoopChar
    ; Fill the rest of the line with spaces
@BeginFill:
    lda #' '
@LoopFill:
    ldx tmp2
    beq @Done
    sta (ptr2),y
    iny
    dec tmp2
    bne @LoopFill
@Done:
    rts

_clearScreen40:
    lda #' '
    ldx #$00
    ldy #$04
    jmp fillMem

