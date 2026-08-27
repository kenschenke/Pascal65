;
; viewdump.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; viewdump routine

.include "asmlib.inc"
.include "zeropage.inc"
.include "cbm_kernal.inc"
.include "4510macros.inc"

KEYBUF = $d610

CH_CLR = $93
CH_UP = $91
CH_DOWN = $11
CH_RETURN = $0d
CH_SPACE = $20
CH_HOME = $13
CH_ESC = $1b
CH_DELETE = $14

ROWS = 23

.export viewDump, getKey

.data

strPrompt: .asciiz "PageDn=Return  PageUp=Delete  Scroll=Arrows  Top=Home  Bottom=Clr  Exit=Esc"

.bss

ch: .res 1
memBuf: .res 4
topRow: .res 2
numRows: .res 2
rowCount: .res 2
rowData: .res 80
ndxData: .res 1
screenRow: .res 1
eofReached: .res 1
intBuf: .res 10

.code

; This routine shows an AST dump on the screen. It clears the screen
; and shows the dump. If the dump longer than a screen, it paginates.
; The up and down arrows scroll the dump contents.
;
; Keys for navigation:
;    Page Down:    Return or Space
;    Page Up:      Delete
;    Scroll Down:  Down arrow
;    Scroll Up:    Up arrow
;    Go to top:    Home
;    Go to bottom: Clear (Shift+Home)
;    Escape:       Exit the viewer
;
; The dump membuf is passed in Q.
.proc viewDump
    stq memBuf

    jsr countRows

    jsr clearKeyBuf

    lda #0
    sta topRow
    sta topRow+1

L1: jsr showDump

    jsr getKey
    cmp #CH_ESC
    beq L9
    cmp #CH_DOWN
    bne :+
    jsr handleDownArrow
    bra L1
:   cmp #CH_UP
    bne :+
    jsr handleUpArrow
    bra L1
:   cmp #CH_RETURN
    bne :+
    jsr handlePageDown
    bra L1
:   cmp #CH_SPACE
    bne :+
    jsr handlePageDown
    bra L1
:   cmp #CH_DELETE
    bne :+
    jsr handlePageUp
    bra L1
:   cmp #CH_HOME
    bne :+
    jsr handleHome
    bra L1
:   cmp #CH_CLR
    bne :+
    jsr handleEnd
:   bra L1

L9: rts
.endproc

.proc countRows
    lda #0
    sta numRows
    sta numRows+1

    ldq memBuf
    stq ptr1
    lda #0
    tax
    jsr setMemBufPos

L1: ldq memBuf
    sta ptr1
    jsr isMemBufAtEnd
    beq L9

    jsr readByte
    lda ch
    cmp #CH_RETURN
    bne L1

    lda numRows
    clc
    adc #1
    sta numRows
    lda numRows+1
    adc #0
    sta numRows+1
    bra L1

L9: rts
.endproc

.proc handleHome
    lda #0
    sta topRow
    sta topRow+1
    rts
.endproc

.proc handleEnd
    lda numRows
    sta topRow
    lda numRows+1
    sta topRow+1

    lda topRow
    sec
    sbc #ROWS
    sta topRow
    lda topRow+1
    sbc #0
    sta topRow+1

    lda topRow
    bpl :+
    lda #0
    sta topRow
    sta topRow+1
:   rts
.endproc

.proc handleDownArrow
    lda topRow
    clc
    adc #1
    sta topRow
    lda topRow+1
    adc #0
    sta topRow+1
    rts
.endproc

.proc handleUpArrow
    lda topRow
    ora topRow+1
    beq :+
    lda topRow
    sec
    sbc #1
    sta topRow
    lda topRow+1
    sbc #0
    sta topRow+1
:   rts
.endproc

.proc handlePageDown
    lda eofReached
    bne :+
    lda topRow
    clc
    adc #ROWS
    sta topRow
    lda topRow+1
    adc #0
    sta topRow+1
:   rts
.endproc

.proc handlePageUp
    lda topRow
    sec
    sbc #ROWS
    sta topRow
    lda topRow+1
    sbc #0
    sta topRow+1
    lda topRow
    bpl :+
    lda #0
    sta topRow
    sta topRow+1
:   rts
.endproc

.proc showDump
    ; Clear the screen
    lda #CH_CLR
    jsr CHROUT

    ; Reset the row counter
    lda #0
    sta rowCount
    sta rowCount+1
    sta screenRow
    sta eofReached

    ; Reset the position in the membuf
    ldq memBuf
    stq ptr1
    lda #0
    tax
    jsr setMemBufPos

    ; Read rows in the membuf
L1: jsr readRow
    jsr isRowVisible
    beq L2

    ; Row is visible so print it out
    jsr showRowNum
    ldx #0
    inc screenRow
:   lda rowData,x
    beq L2
    jsr CHROUT
    inx
    bne :-

L2: lda rowCount
    clc
    adc #1
    sta rowCount
    lda rowCount+1
    adc #0
    sta rowCount+1

    ; Is the membuf EOF?
    ldq memBuf
    stq ptr1
    jsr isMemBufAtEnd
    bne :+
    lda #1
    sta eofReached
    bra L3

:   lda screenRow
    cmp #ROWS
    bne L1

L3: rts
.endproc

.proc showRowNum
    lda rowCount
    clc
    adc #1
    sta intOp1
    lda rowCount+1
    adc #0
    sta intOp1+1
    lda #<intBuf
    ldx #>intBuf
    jsr writeInt16
    ldx #0
:   lda intBuf,x
    beq :+
    jsr CHROUT
    inx
    bne :-
:   cpx #3
    beq :+
    lda #' '
    jsr CHROUT
    inx
    bne :-
:   lda #' '
    jsr CHROUT
    rts
.endproc

; This routine reads a row from the membuf
; and stores it in rowData and null-terminates it.
.proc readRow
    lda #0
    sta ndxData

L1: jsr readByte
    ldx ndxData
    lda ch
    sta rowData,x
    inc ndxData
    cmp #CH_RETURN
    bne L1

    lda #0
    inx
    sta rowData,x
    rts
.endproc

; This routine reads a byte from the membuf and
; stores in ch.
.proc readByte
    ldq memBuf
    stq ptr1
    lda #<ch
    sta ptr2
    lda #>ch
    sta ptr2+1
    lda #0
    sta ptr2+2
    sta ptr2+3
    lda #1
    ldx #0
    jmp readFromMemBuf
.endproc

.proc clearKeyBuf
    lda #0
L1: ldx KEYBUF
    beq L2
    sta KEYBUF
    bne L1
L2: rts
.endproc

.proc fixAlphaCase
    cmp #96
    bcc L1
    cmp #123
    bcs L2
    sec
    sbc #32
    jmp L2
L1: cmp #64
    bcc L2
    cmp #91
    bcs L2
    clc
    adc #128
L2: rts
.endproc

.proc getKey
L1: ldx KEYBUF
    beq L1
    lda #0
    sta KEYBUF
    txa
    jmp fixAlphaCase
.endproc

; Compare if rowCount is greater than or equal to topRow
; Z flag is cleared if rowCount >= topRow
.proc isRowVisible
    lda rowCount
    cmp topRow
    lda rowCount + 1
    sbc topRow + 1
    bvc L1
    eor #$80
L1: bpl L2
    lda #0
    rts
L2: lda #1
    rts
.endproc
