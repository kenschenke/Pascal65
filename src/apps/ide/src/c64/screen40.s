; void __fastcall__ clearScreen40(void);
; void __fastcall__ drawRow40(char row, char len, char *buf);

    .export     _drawRow40, _clearScreen40, _setScreenBg40, _initScreen40, _cursorOnOff
    .export     _renderCursor64, _clearCursor64, _setRowColor
    .import     popa, popax, incRow, petscii2Screen
    .importzp   ptr1, ptr2, ptr3, tmp1, tmp2, tmp3, tmp4

    .include    "c64.inc"

    ;; Registers
    NUM_COLS = 40

.proc _cursorOnOff
    lda #0
    sta 204
    rts
.endproc

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
    ldy #NUM_COLS - 1
@Clear:
    sta (ptr2),y
    dey
    bpl @Clear
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
    jsr fillMem
    jmp _clearScreen40

; void drawRow40(char row, char col, char len, char *buf, char isReversed)
;       ptr1 - char buffer
;       ptr2 = screen RAM
;       tmp1 - length of buffer
;       tmp2 - row number, then # of chars to pad later
;       tmp3 - col number to start rendering
;       tmp4 - non-zero if drawing reversed characters
_drawRow40:
    sta tmp4        ; isReversed
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
    sec
    sbc tmp3
    sta tmp2
    ldy #$0
@LoopChar:
    lda tmp1
    beq @BeginFill
    lda (ptr1),y    ; Load the next byte
    jsr petscii2Screen
    ; Check if isReversed is non-zero
    ldx tmp4
    beq @WriteChar
    ora #$80    ; "Or" the reverse bit (bit 7)
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

; void clearCursor64(char x, char y)
; Clears the rendered cursor
; x and y are zero-based column and row of current cursor position
; Uses ptr1 as screen memory
.proc _clearCursor64
    pha
    tay
    ldx #0
    stx ptr1
    ldx #4
    stx ptr1 + 1    ; Set ptr1 to $400 (base of screen RAM)
    jsr calcScreenPos
    jsr popa
    pha
    tay
    lda (ptr1),y
    and #$7f
    sta (ptr1),y
    ldx #0
    stx ptr1
    ldx #$d8
    stx ptr1 + 1
    pla
    tax
    pla
    tay
    jsr calcScreenPos
    txa
    tay
    lda #1
    sta (ptr1),y
    rts
.endproc

; void renderCursor64(char x, char y)
; Renders the cursor
; x and y are zero-based column and row of current cursor position
; Uses ptr1 as screen memory
.proc _renderCursor64
    pha
    tay
    ldx #0
    stx ptr1
    ldx #4
    stx ptr1 + 1    ; Set ptr1 to $400 (base of screen RAM)
    jsr calcScreenPos
    jsr popa
    pha
    tay
    lda (ptr1),y
    ora #$80
    sta (ptr1),y
    ldx #0
    stx ptr1
    ldx #$d8
    stx ptr1 + 1
    pla
    tax
    pla
    tay
    jsr calcScreenPos
    txa
    tay
    lda #3
    sta (ptr1),y
    rts
.endproc

; This routine sets the color of the row (zero-based)
; void setRowColor(char row, char color)
.proc _setRowColor
    pha
    jsr popa
    tay
    ldx #0
    stx ptr1
    ldx #$d8
    stx ptr1 + 1
    jsr calcScreenPos
    pla
    ldy #39
L1:
    sta (ptr1),y
    dey
    bpl L1
    rts
.endproc

; This routine calculates the row address in screen memory
; and stores it in ptr1.
; X register is untouched
; Y contains zero-based row number
.proc calcScreenPos
L1:
    cpy #0
    beq L2
    clc
    lda ptr1
    adc #40
    sta ptr1
    lda ptr1 + 1
    adc #0
    sta ptr1 + 1
    dey
    jmp L1
L2:
    rts
.endproc
