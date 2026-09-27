;
; codesample.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Draw code sample

.include "zeropage.inc"
.include "4510macros.inc"

SAMPLE_ROW = 0          ; Screen row to draw
SAMPLE_COL = 4          ; Screen column to start at
SAMPLE_COLS = SAMPLE_COL+36

.export drawCodeSample

.import getScreenRowPtr, getColorRowPtr, getColorFromTheme, toVIC

.bss

currentRow: .res 1
currentCol: .res 1
currentChar: .res 1

.data

charRow1:       ; +----------------------------------+
    .byte $70, $40, $40, $40, $40, $40, $40, $40, $40
    .byte $40, $40, $40, $40, $40, $40, $40, $40, $40
    .byte $40, $40, $40, $40, $40, $40, $40, $40, $40
    .byte $40, $40, $40, $40, $40, $40, $40, $40, $6e
charRow2:       ; |  Sample Code                     |
    .byte $5d, $20, $20, $53, $01, $0d, $10, $0c, $05
    .byte $20, $43, $0f, $04, $05, $20, $20, $20, $20
    .byte $20, $20, $20, $20, $20, $20, $20, $20, $20
    .byte $20, $20, $20, $20, $20, $20, $20, $20, $5d
charRow3:       ; +----------------------------------+
    .byte $6b, $40, $40, $40, $40, $40, $40, $40, $40
    .byte $40, $40, $40, $40, $40, $40, $40, $40, $40
    .byte $40, $40, $40, $40, $40, $40, $40, $40, $40
    .byte $40, $40, $40, $40, $40, $40, $40, $40, $73
charRow4:       ; |                                  |
    .byte $5d, $20, $20, $20, $20, $20, $20, $20, $20
    .byte $20, $20, $20, $20, $20, $20, $20, $20, $20
    .byte $20, $20, $20, $20, $20, $20, $20, $20, $20
    .byte $20, $20, $20, $20, $20, $20, $20, $20, $5d
charRow5:       ; |  Program Test;                   |
    .byte $5d, $20, $20, $50, $12, $0f, $07, $12, $01
    .byte $0d, $20, $54, $05, $13, $14, $3b, $20, $20
    .byte $20, $20, $20, $20, $20, $20, $20, $20, $20
    .byte $20, $20, $20, $20, $20, $20, $20, $20, $5d
charRow6:       ; |  X <== Cursor                    |
    .byte $5d, $20, $20, $a0, $20, $3c, $3d, $3d, $20
    .byte $43, $15, $12, $13, $0f, $12, $20, $20, $20
    .byte $20, $20, $20, $20, $20, $20, $20, $20, $20
    .byte $20, $20, $20, $20, $20, $20, $20, $20, $5d
charRow7:       ; |  Var                             |
    .byte $5d, $20, $20, $56, $01, $12, $20, $20, $20
    .byte $20, $20, $20, $20, $20, $20, $20, $20, $20
    .byte $20, $20, $20, $20, $20, $20, $20, $20, $20
    .byte $20, $20, $20, $20, $20, $20, $20, $20, $5d
charRow8:       ; |     i : Integer;                 |
    .byte $5d, $20, $20, $20, $20, $20, $09, $20, $3a
    .byte $20, $49, $0e, $14, $05, $07, $05, $12, $3b
    .byte $20, $20, $20, $20, $20, $20, $20, $20, $20
    .byte $20, $20, $20, $20, $20, $20, $20, $20, $5d
charRow9:       ; |                                  |
    .byte $5d, $20, $20, $20, $20, $20, $20, $20, $20
    .byte $20, $20, $20, $20, $20, $20, $20, $20, $20
    .byte $20, $20, $20, $20, $20, $20, $20, $20, $20
    .byte $20, $20, $20, $20, $20, $20, $20, $20, $5d
charRow10:      ; |  // Comment                      |
    .byte $5d, $20, $20, $2f, $2f, $20, $43, $0f, $0d
    .byte $0d, $05, $0e, $14, $20, $20, $20, $20, $20
    .byte $20, $20, $20, $20, $20, $20, $20, $20, $20
    .byte $20, $20, $20, $20, $20, $20, $20, $20, $5d
charRow11:      ; |  Begin                           |
    .byte $5d, $20, $20, $42, $05, $07, $09, $0e, $20
    .byte $20, $20, $20, $20, $20, $20, $20, $20, $20
    .byte $20, $20, $20, $20, $20, $20, $20, $20, $20
    .byte $20, $20, $20, $20, $20, $20, $20, $20, $5d
charRow12:      ; |     For i := 1 To 10 Do          |
    .byte $5d, $20, $20, $20, $20, $20, $46, $0f, $12
    .byte $20, $09, $20, $3a, $3d, $20, $31, $20, $54
    .byte $0f, $20, $31, $30, $20, $44, $0f, $20, $20
    .byte $20, $20, $20, $20, $20, $20, $20, $20, $5d
charRow13:      ; |        Writeln('Hello, World');  |
    .byte $5d, $20, $20, $20, $20, $20, $20, $20, $20
    .byte $57, $12, $09, $14, $05, $0c, $0e, $28, $27
    .byte $48, $05, $0c, $0c, $0f, $2c, $20, $57, $0f
    .byte $12, $0c, $04, $27, $29, $3b, $20, $20, $5d
charRow14:      ; |  End.                            |
    .byte $5d, $20, $20, $45, $0e, $04, $2e, $20, $20
    .byte $20, $20, $20, $20, $20, $20, $20, $20, $20
    .byte $20, $20, $20, $20, $20, $20, $20, $20, $20
    .byte $20, $20, $20, $20, $20, $20, $20, $20, $5d
charRow15:      ; |                                  |
    .byte $5d, $20, $20, $20, $20, $20, $20, $20, $20
    .byte $20, $20, $20, $20, $20, $20, $20, $20, $20
    .byte $20, $20, $20, $20, $20, $20, $20, $20, $20
    .byte $20, $20, $20, $20, $20, $20, $20, $20, $5d
charRow16:      ; +----------------------------------+
    .byte $6d, $40, $40, $40, $40, $40, $40, $40, $40
    .byte $40, $40, $40, $40, $40, $40, $40, $40, $40
    .byte $40, $40, $40, $40, $40, $40, $40, $40, $40
    .byte $40, $40, $40, $40, $40, $40, $40, $40, $7d
charRows:
    .byte .lobyte(charRow1), .hibyte(charRow1)
    .byte .lobyte(charRow2), .hibyte(charRow2)
    .byte .lobyte(charRow3), .hibyte(charRow3)
    .byte .lobyte(charRow4), .hibyte(charRow4)
    .byte .lobyte(charRow5), .hibyte(charRow5)
    .byte .lobyte(charRow6), .hibyte(charRow6)
    .byte .lobyte(charRow7), .hibyte(charRow7)
    .byte .lobyte(charRow8), .hibyte(charRow8)
    .byte .lobyte(charRow9), .hibyte(charRow9)
    .byte .lobyte(charRow10), .hibyte(charRow10)
    .byte .lobyte(charRow11), .hibyte(charRow11)
    .byte .lobyte(charRow12), .hibyte(charRow12)
    .byte .lobyte(charRow13), .hibyte(charRow13)
    .byte .lobyte(charRow14), .hibyte(charRow14)
    .byte .lobyte(charRow15), .hibyte(charRow15)
    .byte .lobyte(charRow16), .hibyte(charRow16)
    .byte $0, $0

; None = $00
; Number = $01
; Keyword = $02
; String = $03
; Comment = $04
; Cursor = $05
; Foreground = $08
colorRow1:      ; +----------------------------------+
    .byte $08, $08, $08, $08, $08, $08, $08, $08, $08
    .byte $08, $08, $08, $08, $08, $08, $08, $08, $08
    .byte $08, $08, $08, $08, $08, $08, $08, $08, $08
    .byte $08, $08, $08, $08, $08, $08, $08, $08, $08
colorRow2:      ; |  Sample Code                     |
    .byte $08, $00, $00, $08, $08, $08, $08, $08, $08
    .byte $00, $08, $08, $08, $08, $00, $00, $00, $00
    .byte $00, $00, $00, $00, $00, $00, $00, $00, $00
    .byte $00, $00, $00, $00, $00, $00, $00, $00, $08
colorRow3:      ; +----------------------------------+
    .byte $08, $08, $08, $08, $08, $08, $08, $08, $08
    .byte $08, $08, $08, $08, $08, $08, $08, $08, $08
    .byte $08, $08, $08, $08, $08, $08, $08, $08, $08
    .byte $08, $08, $08, $08, $08, $08, $08, $08, $08
colorRow4:      ; |                                  |
    .byte $08, $00, $00, $00, $00, $00, $00, $00, $00
    .byte $00, $00, $00, $00, $00, $00, $00, $00, $00
    .byte $00, $00, $00, $00, $00, $00, $00, $00, $00
    .byte $00, $00, $00, $00, $00, $00, $00, $00, $08
colorRow5:      ; |  Program Test;                   |
    .byte $08, $00, $00, $02, $02, $02, $02, $02, $02
    .byte $02, $00, $06, $06, $06, $06, $05, $00, $00
    .byte $00, $00, $00, $00, $00, $00, $00, $00, $00
    .byte $00, $00, $00, $00, $00, $00, $00, $00, $08
colorRow6:      ; |                                  |
    .byte $08, $00, $00, $07, $00, $08, $08, $08, $08
    .byte $08, $08, $08, $08, $08, $08, $00, $00, $00
    .byte $00, $00, $00, $00, $00, $00, $00, $00, $00
    .byte $00, $00, $00, $00, $00, $00, $00, $00, $08
colorRow7:      ; |  Var                             |
    .byte $08, $00, $00, $02, $02, $02, $00, $00, $00
    .byte $00, $00, $00, $00, $00, $00, $00, $00, $00
    .byte $00, $00, $00, $00, $00, $00, $00, $00, $00
    .byte $00, $00, $00, $00, $00, $00, $00, $00, $08
colorRow8:      ; |     i : Integer;                 |
    .byte $08, $00, $00, $00, $00, $00, $06, $00, $05
    .byte $00, $02, $02, $02, $02, $02, $02, $02, $05
    .byte $00, $00, $00, $00, $00, $00, $00, $00, $00
    .byte $00, $00, $00, $00, $00, $00, $00, $00, $08
colorRow9:      ; |                                  |
    .byte $08, $00, $00, $00, $00, $00, $00, $00, $00
    .byte $00, $00, $00, $00, $00, $00, $00, $00, $00
    .byte $00, $00, $00, $00, $00, $00, $00, $00, $00
    .byte $00, $00, $00, $00, $00, $00, $00, $00, $08
colorRow10:     ; |  // Comment                      |
    .byte $08, $00, $00, $04, $04, $04, $04, $04, $04
    .byte $04, $04, $04, $04, $00, $00, $00, $00, $00
    .byte $00, $00, $00, $00, $00, $00, $00, $00, $00
    .byte $00, $00, $00, $00, $00, $00, $00, $00, $08
colorRow11:     ; |  Begin                           |
    .byte $08, $00, $00, $02, $02, $02, $02, $02, $00
    .byte $00, $00, $00, $00, $00, $00, $00, $00, $00
    .byte $00, $00, $00, $00, $00, $00, $00, $00, $00
    .byte $00, $00, $00, $00, $00, $00, $00, $00, $08
colorRow12:     ; |     For i := 1 To 10 Do          |
    .byte $08, $00, $00, $00, $00, $00, $02, $02, $02
    .byte $00, $06, $00, $05, $05, $00, $01, $00, $02
    .byte $02, $00, $01, $01, $00, $02, $02, $00, $00
    .byte $00, $00, $00, $00, $00, $00, $00, $00, $08
colorRow13:     ; |        Writeln('Hello, World');  |
    .byte $08, $00, $00, $00, $00, $00, $00, $00, $00
    .byte $06, $06, $06, $06, $06, $06, $06, $05, $03
    .byte $03, $03, $03, $03, $03, $03, $03, $03, $03
    .byte $03, $03, $03, $03, $05, $05, $00, $00, $08
colorRow14:     ; |  End.                            |
    .byte $08, $00, $00, $02, $02, $02, $05, $00, $00
    .byte $00, $00, $00, $00, $00, $00, $00, $00, $00
    .byte $00, $00, $00, $00, $00, $00, $00, $00, $00
    .byte $00, $00, $00, $00, $00, $00, $00, $00, $08
colorRow15:     ; |                                  |
    .byte $08, $00, $00, $00, $00, $00, $00, $00, $00
    .byte $00, $00, $00, $00, $00, $00, $00, $00, $00
    .byte $00, $00, $00, $00, $00, $00, $00, $00, $00
    .byte $00, $00, $00, $00, $00, $00, $00, $00, $08
colorRow16:     ; +----------------------------------+
    .byte $08, $08, $08, $08, $08, $08, $08, $08, $08
    .byte $08, $08, $08, $08, $08, $08, $08, $08, $08
    .byte $08, $08, $08, $08, $08, $08, $08, $08, $08
    .byte $08, $08, $08, $08, $08, $08, $08, $08, $08
colorRows:
    .byte .lobyte(colorRow1), .hibyte(colorRow1)
    .byte .lobyte(colorRow2), .hibyte(colorRow2)
    .byte .lobyte(colorRow3), .hibyte(colorRow3)
    .byte .lobyte(colorRow4), .hibyte(colorRow4)
    .byte .lobyte(colorRow5), .hibyte(colorRow5)
    .byte .lobyte(colorRow6), .hibyte(colorRow6)
    .byte .lobyte(colorRow7), .hibyte(colorRow7)
    .byte .lobyte(colorRow8), .hibyte(colorRow8)
    .byte .lobyte(colorRow9), .hibyte(colorRow9)
    .byte .lobyte(colorRow10), .hibyte(colorRow10)
    .byte .lobyte(colorRow11), .hibyte(colorRow11)
    .byte .lobyte(colorRow12), .hibyte(colorRow12)
    .byte .lobyte(colorRow13), .hibyte(colorRow13)
    .byte .lobyte(colorRow14), .hibyte(colorRow14)
    .byte .lobyte(colorRow15), .hibyte(colorRow15)
    .byte .lobyte(colorRow16), .hibyte(colorRow16)
    .byte $0, $0
    
.code

.proc drawCodeSample
    jsr drawSampleChars
    jsr drawSampleColors

    rts
.endproc

.proc drawSampleChars
    ; Ptr1 = screen RAM
    ; Ptr2 = row pointer in charRows
    ; Ptr3 = current row

    lda #<charRows
    sta ptr2
    lda #>charRows
    sta ptr2+1

    lda #SAMPLE_ROW
    sta currentRow

    ; Loop through the rows
L1: ldy #0
    lda (ptr2),y
    sta ptr3
    iny
    lda (ptr2),y
    sta ptr3+1

    lda ptr3
    ora ptr3+1
    beq DN

    lda currentRow
    jsr getScreenRowPtr
    sta ptr1
    stx ptr1+1

    ; Look through the characters in the current row
    lda #SAMPLE_COL
    sta currentCol
    lda #0
    sta currentChar
L2: ldy currentChar
    lda (ptr3),y
    ldy currentCol
    sta (ptr1),y
    inc currentChar
    inc currentCol
    lda currentCol
    cmp #SAMPLE_COLS
    bne L2

    ; Move to the next row
    lda ptr2
    clc
    adc #2
    sta ptr2
    lda ptr2+1
    adc #0
    sta ptr2+1
    inc currentRow
    bra L1

DN: rts
.endproc

.proc drawSampleColors
    ; Ptr1 = color RAM
    ; Ptr2 = row pointer in colorRows
    ; Ptr3 = current row

    lda #<colorRows
    sta ptr2
    lda #>colorRows
    sta ptr2+1

    lda #SAMPLE_ROW
    sta currentRow

    ; Loop through the rows
L1: ldy #0
    lda (ptr2),y
    sta ptr3
    iny
    lda (ptr2),y
    sta ptr3+1

    lda ptr3
    ora ptr3+1
    beq DN

    lda currentRow
    jsr getColorRowPtr
    stq ptr1

    ; Look through the colors in the current row
    lda #SAMPLE_COL
    sta currentCol
    lda #0
    sta currentChar
L2: ldy currentChar
    lda (ptr3),y
    jsr getColorFromTheme
    jsr toVIC
    ldz currentCol
    nop
    sta (ptr1),z
    inc currentChar
    inc currentCol
    lda currentCol
    cmp #SAMPLE_COLS
    bne L2

    ; Move to the next row
    lda ptr2
    clc
    adc #2
    sta ptr2
    lda ptr2+1
    adc #0
    sta ptr2+1
    inc currentRow
    bra L1

DN: rts
.endproc
