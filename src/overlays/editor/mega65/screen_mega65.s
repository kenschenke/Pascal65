; void __fastcall__ clearScreen(void);
; void __fastcall__ drawRow(char row, char len, char *buf);

    .export     _drawRow, _clearScreen, _initScreen
    .export     _renderCursor, _clearCursor, _setRowColor
    .import     popa, popax, pusha, _cellcolor, incRow, petscii2Screen, _E, _clrscr, _drawRow65, _conioinit
    .import     _getcell, _setcell, pushax
    .importzp   ptr1, ptr2, ptr3, tmp1, tmp2, tmp3, tmp4

    .include    "c64.inc"
    .include    "cbm_kernal.inc"

    ;; Registers
    NUM_COLS = 80

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

_initScreen:
    jsr _conioinit
    jmp _clearScreen

; void drawRow(char row, char col, char len, char *buf, char isReversed)
;       ptr1 - char buffer
;       ptr2 = screen RAM
;       tmp1 - length of buffer
;       tmp2 - row number, then # of chars to pad later
;       tmp3 - col number to start rendering
;       tmp4 - non-zero if drawing reversed characters
_drawRow:
    jmp _drawRow65

_clearScreen:
    jmp _clrscr

; void clearCursor(void)
; Clears the rendered cursor
; Uses ptr1 as screen memory
.proc _clearCursor
    ; tmp1 is row
    ; tmp2 is column
    ldx #0
    stx ptr1
    ldx #8
    stx ptr1 + 1    ; Set ptr1 to $800 (base of screen RAM)
    lda _E + 14     ; E.cf.cy
    sec
    sbc _E + 16     ; E.cf.rowoff
    sta tmp1
    tay
    jsr calcScreenPos
    lda _E + 12     ; E.cf.cx
    sec
    sbc _E + 18     ; E.cf.coloff
    sta tmp2
    tay
    lda (ptr1),y
    and #$7f
    sta (ptr1),y
    lda tmp2
    jsr pusha
    lda tmp1
    jsr pusha
    lda #1
    jmp _cellcolor
.endproc

; void renderCursor(char x, char y)
; Renders the cursor
; x and y are zero-based column and row of current cursor position
; Uses ptr1 as screen memory
.proc _renderCursor
    ; row is in A
    ; X is on the call stack
    ; tmp1 is row
    ; tmp2 is column
    sta tmp1
    ldx #0
    stx ptr1
    ldx #8
    stx ptr1 + 1
    tay
    jsr calcScreenPos
    jsr popa    ; pull column from call stack
    sta tmp2
    tay
    lda (ptr1),y
    ora #$80
    sta (ptr1),y
    lda tmp2
    jsr pusha
    lda tmp1
    jsr pusha
    lda #8
    jmp _cellcolor
.endproc

; This routine sets the color of the row (zero-based)
; void setRowColor(char row, char color)
.proc _setRowColor
    ; tmp1 row
    ; tmp2 color
    ; tmp3 current column
    sta tmp2
    jsr popa
    sta tmp1
    lda #0
    sta tmp3
L1:
    lda tmp3
    cmp #80
    beq L2
    pha
    jsr pusha
    lda tmp1
    pha
    jsr pusha
    lda tmp2
    pha
    jsr _cellcolor
    pla
    sta tmp2
    pla
    sta tmp1
    pla
    sta tmp3
    inc tmp3
    jmp L1
L2:
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
    adc #80
    sta ptr1
    lda ptr1 + 1
    adc #0
    sta ptr1 + 1
    dey
    jmp L1
L2:
    rts
.endproc
