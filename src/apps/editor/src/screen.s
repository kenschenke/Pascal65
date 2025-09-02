;
; screen.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Screen routines

.include "editor.inc"
.include "zeropage.inc"
.include "cbm_kernal.inc"
.include "4510macros.inc"
.include "asmlib.inc"

.export editorRefreshScreen, editorScroll, renderCursor, editorRowAt
.export petsciiToScreenCode, currentEditorRow, clearScreen
.export editorDrawMessageBar, calcScreenPtr, initScreen, setupScreen
.export resetScreenSettings

.import anyDirtyRows, titleScreen, rowPtrs
.import screenrows, screencols, statusmsg, statusmsg_dirty, statusbar
.import editorSetAllRowsDirty, colorPtrs, editorHighlightSelection

.bss

screenX: .res 1
screenY: .res 1
intBuf: .res 7

.code

.proc isQZero
    cmp #0
    bne :+
    cpx #0
    bne :+
    cpy #0
    bne :+
    cpz #0
:   rts
.endproc

.proc initScreen
    ldx #DEFAULT_COLS
    ldy #DEFAULT_ROWS
    jsr setupScreen
    rts
.endproc

; Number of columns in X, number of rows in Y
.proc setupScreen
    stx screencols
    sty screenrows
    dec screenrows
    dec screenrows

    jsr setupScreenCols

    ; Initialize rowPtrs
    jsr calcRowPtrs

    ; Initialize color RAM pointers
    jsr calcColorPtrs

    rts
.endproc

.proc calcColorPtrs
    ldy screenrows
    iny
    iny
    sty tmp1        ; tmp1 contains screen rows
    lda #4
    sta tmp2        ; tmp2 contains colorPtrs index
    lda screencols
    sta intOp32     ; intOp32 contains number of screen columns
    lda #0
    sta intOp32+1
    sta intOp32+2
    sta intOp32+3
    sta colorPtrs
    sta colorPtrs+1
    sta intOp1      ; Set colorPtrs[0] and intOp1/2 to $FF80000
    sta intOp1+1
    lda #$f8
    sta intOp2
    sta colorPtrs+2
    lda #$0f
    sta colorPtrs+3
    sta intOp2+1
L1: dec tmp1
    beq :+
    neg
    neg
    lda intOp1
    clc
    neg
    neg
    adc intOp32
    neg
    neg
    sta intOp1
    lda intOp1
    ldx tmp2
    sta colorPtrs,x
    inx
    lda intOp1+1
    sta colorPtrs,x
    inx
    lda intOp2
    sta colorPtrs,x
    inx
    lda intOp2+1
    sta colorPtrs,x
    inx
    stx tmp2
    bne L1
:   rts
.endproc

.proc calcRowPtrs
    ; Force screen memory to be at $800 if 25 rows
    lda screenrows
    cmp #DEFAULT_ROWS+1
    bcs :+
    lda #8
    sta $d061
    sta intOp1+1
    sta rowPtrs+1
    lda #0
    sta $d060
    sta $d062
    sta intOp1
    sta intOp2
    sta intOp2+1
    sta rowPtrs
    sta rowPtrs+2
    sta rowPtrs+3
    lda $d063
    and #$0
    sta $d063
    bra L1
    ; 50 rows - screen RAM is at $40800
:   lda #$00
    sta $d060
    sta intOp1
    sta rowPtrs
    lda #$08
    sta $d061
    sta intOp1+1
    sta rowPtrs+1
    lda #$04
    sta $d062
    sta intOp2
    sta rowPtrs+2
    lda $d063
    and #$f0
    sta $d063
    lda #0
    sta intOp2+1
    sta rowPtrs+3
L1: lda screencols
    sta intOp32     ; intOp32 contains number of screen columns
    lda #0
    sta intOp32+1
    sta intOp32+2
    sta intOp32+3
    ldy screenrows
    iny
    iny
    sty tmp1        ; tmp1 contains screen rows
    lda #4
    sta tmp2        ; tmp2 contains colorPtrs index
L2: dec tmp1
    beq :+
    neg
    neg
    lda intOp1
    clc
    neg
    neg
    adc intOp32
    neg
    neg
    sta intOp1
    lda intOp1
    ldx tmp2
    sta rowPtrs,x
    inx
    lda intOp1+1
    sta rowPtrs,x
    inx
    lda intOp2
    sta rowPtrs,x
    inx
    lda intOp2+1
    sta rowPtrs,x
    inx
    stx tmp2
    bne L2
:   rts
.endproc

; This routine calculates the X and Y coordinate in screen memory into ptr4
; Y contains zero-based row
.proc calcScreenPtr
    ; Multiply y * 4
    tya
    asl a
    asl a
    tay
    lda rowPtrs,y
    sta ptr4
    lda rowPtrs+1,y
    sta ptr4+1
    lda rowPtrs+2,y
    sta ptr4+2
    lda rowPtrs+3,y
    sta ptr4+3
    rts
.endproc

; Zero-based row passed in Y, starting column in X
.proc clearRow
    jsr calcScreenPtr
    txa
    taz
    lda #' '
:   nop
    sta (ptr4),z
    inz
    cpz screencols
    bcc :-
DN: rts
.endproc

.proc clearScreen
    lda #CH_CLRSCR
    jsr CHROUT
    rts
.endproc

; Zero-based row in Y
; Column in X
; Length in A
; Buffer in ptr1
; C flag is set if row is to be reversed
; Note: ptr4 is destroyed as well as tmp1, tmp2, tmp3, and tmp4
.proc drawRow
    sta tmp1            ; length in tmp1
    lda #0
    sta tmp2            ; reverse flag in tmp2
    bcc :+
    lda #1
    sta tmp2
:   jsr calcScreenPtr
    stx tmp4            ; starting column in tmp4
    lda #0
    sta tmp3            ; caller's buffer offset in tmp3
L1: ldz tmp3
    nop
    lda (ptr1),z        ; load current character from buffer
    jsr petsciiToScreenCode
    ldx tmp2            ; reverse?
    beq :+              ; skip if not
    ora #$80            ; reverse character
:   ldz tmp4
    nop
    sta (ptr4),z        ; draw on screen
    inc tmp3
    inc tmp4
    dec tmp1
    bne L1
    rts
.endproc

.proc editorRefreshScreen
    ldq currentFile
    jsr isQZero
    beq :+
    jsr editorScroll

:   lda anyDirtyRows
    beq :+
    jsr editorDrawRows
    jsr editorHighlightSelection
    sta anyDirtyRows

    ; Check if a file is currently open
:   ldq currentFile
    jsr isQZero
    beq :+
    sec
    jsr renderCursor

:   jsr editorDrawMessageBar
    jsr editorDrawStatusBar
    rts
.endproc

.proc editorScroll
    ; Skip if currentFile is null
    ldq currentFile
    jsr isQZero
    bne :+
    rts

:   lda #0
    sta tmp1                ; tmp1 will be non-zero if the screen needs to scroll

    ; Copy cy to intOp1
    ldz #EDITFILE::cy
    nop
    lda (currentFile),z             ; Copy cy to intOp1
    sta intOp1
    inz
    nop
    lda (currentFile),z
    sta intOp1+1

    ; Check if the cursor is above the top of the screen
    ldz #EDITFILE::rowOff
    nop
    lda (currentFile),z             ; Copy rowOff to intOp2
    sta intOp2
    inz
    nop
    lda (currentFile),z
    sta intOp2+1
    jsr ltInt16                     ; Is cy < rowOff?
    beq :+                          ; Branch if not
    ldz #EDITFILE::rowOff
    lda intOp1
    nop
    sta (currentFile),z             ; Copy cy to rowOff
    inz
    lda intOp1+1
    nop
    sta (currentFile),z
    lda #1
    sta tmp1

:   ; Check if the cursor is below the bottom of the screen
    ldz #EDITFILE::rowOff           ; Copy rowOff + screenrows to intOp2
    nop
    lda (currentFile),z
    clc
    adc screenrows
    sta intOp2
    inz
    nop
    lda (currentFile),z
    adc #0
    sta intOp2+1
    jsr geInt16                     ; Is cy >= rowOff + screenrows?
    beq :+                          ; Branch if not
    ; Set rowOff = cy - screenrows + 1
    lda screenrows
    sta intOp2
    lda #0
    sta intOp2+1
    dew intOp2
    jsr subInt16
    ldz #EDITFILE::rowOff
    lda intOp1
    nop
    sta (currentFile),z
    lda intOp1+1
    inz
    nop
    sta (currentFile),z
    lda #1
    sta tmp1

:   lda tmp1                        ; Did the screen need to scroll?
    beq :+
    jsr editorSetAllRowsDirty
:   rts
.endproc

.proc editorDrawStatusBar
    ldq currentFile
    jsr isQZero
    beq L1

    stq ptr1
    ldz #EDITFILE::cx
    nop
    lda (ptr1),z
    clc
    adc #1
    sta intOp1
    lda #0
    sta intOp1+1
    lda #<intBuf
    ldx #>intBuf
    jsr writeInt16

    ldx #STATUSCOL_X
    ldy #0
:   lda intBuf,y
    beq :+
    sta statusbar,x
    inx
    iny
    bne :-
:   ldy #1
    lda #' '
:   sta statusbar,x
    inx
    dey
    bpl :-

    ldz #EDITFILE::cy+1
    nop
    lda (currentFile),z
    tax
    dez
    nop
    lda (currentFile),z
    clc
    adc #1
    bcc :+
    inx
:   sta intOp1
    stx intOp1+1
    lda #<intBuf
    ldx #>intBuf
    jsr writeInt16

    ldx #STATUSCOL_Y
    ldy #0
:   lda intBuf,y
    beq :+
    sta statusbar,x
    inx
    iny
    bne :-
:   lda #' '
:   cpy #3
    bcs L1
    sta statusbar,x
    inx
    iny
    bne :-

L1: ldy screenrows
    ldx #0
    lda #<statusbar
    sta ptr1
    lda #>statusbar
    sta ptr1+1
    lda #0
    sta ptr1+2
    sta ptr1+3
    lda screencols
    sec
    jsr drawRow
    rts
.endproc

.proc editorDrawMessageBar
    lda statusmsg_dirty
    bne :+
    rts
    ; Calculate length of status message
:   ldx #0
:   lda statusmsg,x
    beq :+
    inx
    bne :-
:   ldy screenrows          ; Draw the status bar at the bottom of the screen
    iny
    lda #<statusmsg
    sta ptr1
    lda #>statusmsg
    sta ptr1+1
    lda #0
    sta ptr1+2
    sta ptr1+3
    txa                     ; Copy length to A
    pha                     ; Save length on CPU stack
    ldx #0
    clc
    jsr drawRow
    lda #0
    sta statusmsg_dirty

    plx                     ; Pop length to X
    ldy screenrows
    iny
    jsr clearRow            ; Clear the row from the last of the status msg

    rts
.endproc

.proc editorDrawRows
    ; Is there a file currently open?
    ldq currentFile
    jsr isQZero
    bne :+              ; Branch if a file is open
    jmp editorDrawTitleScreen

:   ldz #EDITFILE::rowOff+1
    nop
    lda (currentFile),z
    tax
    dez
    nop
    lda (currentFile),z
    jsr editorRowAt     ; Find the row at the row offset (top visible row)

    lda #0
    sta screenY         ; Current screen row
    ; Clear ptr3 (next line)
    tax
    tay
    taz
    stq ptr3

    ; If the row is null, clear the screen row and be done
    ldq ptr2
    jsr isQZero
    bne L1
    jmp NX

    ; Step through the lines
L1: lda screenY
    cmp screenrows      ; Have we drawn all the screen rows?
    bne :+              ; Branch if so
    jmp DN

    ; If ptr2 is null that means all the lines in file have been
    ; rendered but there are still visible rows on the screen.
    ; Those rows need to be cleared.
:   ldq ptr2
    jsr isQZero         ; Is ptr2 null?
    bne L2              ; Branch if not
    lda #0
    sta screenX
    jmp NX

    ; Copy the next row pointer to ptr3
L2: ldz #EDITLINE::next
    neg
    neg
    nop
    lda (ptr2),z
    stq ptr3

    lda #0
    sta screenX         ; Starting column

    ldz #EDITLINE::dirty
    nop
    lda (ptr2),z        ; Is the row dirty?
    beq MV              ; Branch if not

    ; Row is dirty and needs to be rendered
    ldz #EDITLINE::buffer
    neg
    neg
    nop
    lda (ptr2),z
    jsr isQZero
    beq L3

    ldz #EDITFILE::colOff
    nop
    lda (currentFile),z
    sta intOp32
    lda #0
    sta intOp32+1
    sta intOp32+2
    sta intOp32+3
    ldz #EDITLINE::buffer
    neg
    neg
    nop
    lda (ptr2),z
    clc
    adcq intOp32
    stq ptr4            ; Store buffer pointer in ptr4

    ; Calculate the number of chars to render
    ldz #EDITFILE::colOff
    nop
    lda (currentFile),z
    sta tmp3
    ldz #EDITLINE::length
    nop
    lda (ptr2),z
    beq NX              ; Skip drawing if line length is zero
    sec
    sbc tmp3
    sta screenX

    ; Copy ptr4 to ptr1
    ldq ptr4
    stq ptr1
    ldx #0
    ldy screenY
    lda screenX
    clc
    jsr drawRow

    ; Clear the dirty flag for the current row
L3: ldz #EDITLINE::dirty
    lda #0
    nop
    sta (ptr2),z

NX: ldx screenX
    ldy screenY
    jsr clearRow        ; Clear the row from the last column
    ; Move to the next line
MV: ldq ptr3
    stq ptr2
    inc screenY
    jmp L1

DN: rts
.endproc

.proc editorDrawTitleScreen
    ldq titleScreen
    stq ptr1            ; Store pointer to title file in ptr1
    ; Calculate first line position to center contents vertically
    lda screenrows
    sta intOp1
    lsr intOp1          ; Divide screen rows by 2
    ldz #EDITFILE::numLines
    nop
    lda (ptr1),z
    sta intOp2          ; Put number of title screen rows in intOp2
    lsr intOp2          ; Divide title screen rows by 2
    jsr subInt16        ; screenrows / 2 - titlerows / 2
    lda intOp1
    sta screenY         ; starting row
    dec screenY         ; zero-based
    ; Start at first line of title screen
    ldz #EDITFILE::firstLine
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr2            ; current line in ptr2
L1: ldz #EDITLINE::buffer
    neg
    neg
    nop
    lda (ptr2),z
    beq L2              ; Skip if the line is blank
    stq ptr1            ; line buffer in ptr1
    ldz #EDITLINE::length
    nop
    lda (ptr2),z
    sta tmp2            ; length
    lsr a               ; divide by 2
    sta tmp1            ; store line length / 2 in tmp1
    lda screencols
    lsr a
    sec
    sbc tmp1
    tax                 ; starting column
    lda tmp2            ; line length
    ldy screenY
    clc
    jsr drawRow
    ; Go to the line in the title screen
L2: inc screenY
    ldz #EDITLINE::next
    neg
    neg
    nop
    lda (ptr2),z
    stq ptr2
    jsr isQZero
    bne L1
    rts
.endproc

.proc currentEditorRow
    ldz #EDITFILE::cy+1
    nop
    lda (currentFile),z
    tax
    dez
    nop
    lda (currentFile),z
    ; fall through to editorRowAt
.endproc

; This routine walks through the lines in the current file
; and finds the line number in A/X.
;
; Returns - ptr2 contains pointer to desired EDITLINE structure
.proc editorRowAt
    sta intOp2          ; Store desired row in intOp2
    stx intOp2+1

    lda #0
    sta intOp1          ; Start at row 1
    sta intOp1+1

    ; Start at the first row
    ldz #EDITFILE::firstLine
    neg
    neg
    nop
    lda (currentFile),z
    ; Store the first line in ptr2
    stq ptr2

    ; Loop through the lines
L1: jsr eqInt16         ; Is this the line we are looking for?
    bne DN              ; Branch if so.

    ; If ptr2 is NULL then jump out
    ldq ptr2
    jsr isQZero
    beq DN

    ; Update ptr2 to the next line
    ldz #EDITLINE::next
    neg
    neg
    nop
    lda (ptr2),z
    stq ptr2

    ; Increment the line number
    inw intOp1
    jmp L1

DN: rts
.endproc

.proc petsciiToScreenCode
    cmp #$20
    bcc RV              ; branch is A < 32 (reverse character)

    cmp #$60
    bcc B1              ; branch if A < 96 (clear bits 6 and 7)

    cmp #$80
    bcc B2              ; branch if A < 128

    cmp #$a0
    bcc B3              ; branch if A < 160

    cmp #$c0
    bcc B4              ; branch if A < 192

    cmp #$ff
    bcc RV              ; branch if A < 255
    
    lda #$7e            ; set A = 126
    bne DN

B2: and #$5f            ; clear bits 5 and 7
    bne DN

B3: ora #$40            ; if A between 128 and 159, set bit 6
    bne DN

B4: eor #$c0            ; if A between 160 and 191, flip bits 6 and 7
    bne DN

B1: and #$3f            ; clear bits 6 and 7
    bpl DN

RV: eor #$80            ; flip bit 7
DN: rts   
.endproc

; This routine renders the cursor at the current position
; Carry is set if the cursor is to be drawn, cleared otherwise
; If the cursor is to be drawn, the color is orange. White otherwise.
.proc renderCursor
    lda #0
    bcc :+
    lda #1
:   sta tmp1
    ; Calculate the screen row
    ldz #EDITFILE::cy
    nop
    lda (currentFile),z
    sta intOp1
    inz
    nop
    lda (currentFile),z
    sta intOp1+1
    ldz #EDITFILE::rowOff
    nop
    lda (currentFile),z
    sta intOp2
    inz
    nop
    lda (currentFile),z
    sta intOp2+1
    jsr subInt16
    ldy intOp1
    phy                 ; Push row number onto CPU stack
    jsr calcScreenPtr
    ldz #EDITFILE::cx
    nop
    lda (currentFile),z
    ldz #EDITFILE::colOff
    sec
    nop
    sbc (currentFile),z
    taz
    nop
    lda (ptr4),z
    ldx tmp1
    bne DR              ; draw the cursor
    and #$7f
    ldx #COLOR_WHITE
    bne ST
DR: ora #$80
    ldx #COLOR_ORANGE
ST: nop
    sta (ptr4),z
    phx                 ; Store color on the CPU stack
    tza
    tax                 ; Transfer column to X
    pla                 ; Pop color off CPU stack
    ply                 ; Pop row number off CPU stack
    ; Fall through to setCharColor
.endproc

; This routine sets the color of a character on the screen
;    A contains color code
;    X contains zero-based column
;    Y contains zero-based row
.proc setCharColor
    sta tmp1
    stx tmp2

    tya             ; Copy row to A
    asl a           ; Multiply by 4
    rol a
    tax
    lda colorPtrs,x
    sta ptr1
    inx
    lda colorPtrs,x
    sta ptr1+1
    inx
    lda colorPtrs,x
    sta ptr1+2
    inx
    lda colorPtrs,x
    sta ptr1+3
    ldz tmp2        ; Column number
    lda tmp1        ; Color
    nop
    sta (ptr1),z
    rts
.endproc

.proc resetScreenSettings
    jsr calcRowPtrs
    rts
.endproc

; rows in Y
.proc setupScreenCols
    cpy #25
    beq L1
    ldx #'5'            ; 50 rows
    bra L2
L1: ldx #'8'            ; 25 rows
L2: lda #CH_ESC
    jsr CHROUT
    txa
    jsr CHROUT
    rts
.endproc
