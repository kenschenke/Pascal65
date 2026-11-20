;
; buildnav.s
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Stepping through the errors and warnings of the last build (BUILDRESULT
; in buildresult.inc, buildResultPtr). F11 goes to the next entry and F9
; to the previous one. From the summary F11 goes to the first and F9 to the
; last, and both wrap at the ends. With no entries they do nothing.
;
; Going to an entry makes it the one the build line shows (current). Then
; the editor moves to its file: the current file if it is open, or the file
; on the disk, which is opened. An entry with no filename, or with a file
; that isn't on the disk (a library unit), is shown but the editor doesn't
; move. The cursor goes to column 0 of the entry's line, or the last line
; if the file is shorter now, and the line is put in the middle of the
; text rows if the file is long enough. An entry with line 0 only switches
; to the file.
;
; The entry's line is highlighted in its file: calcBuildHighlight finds it
; and editorDrawRows draws it reversed in the theme's error or warning
; color. Once a line is added to or deleted from the file, the entry's line
; may have moved, so the highlight is erased until F9 or F11 is pressed
; again (BUILDRESULT::hlState).

.include "editor.inc"
.include "buildresult.inc"
.include "zeropage.inc"
.include "4510macros.inc"
.include "asmlib.inc"

.export editorBuildNext, editorBuildPrev, calcBuildHighlight
.export hlLine, hlColor

.import buildResultPtr, buildDirty, firstFile, fnBuf, openFile, screenrows
.import closeEditBuf, renderCursor, editorClearSelection
.import editorSetAllRowsDirty, updateStatusBarFilename
.import editorSetDefaultStatusMessage, themeColors

.bss

entryLine: .res 2           ; The entry's line
newY: .res 2                ; The cursor's new line
numLines: .res 2            ; The file's numLines
target: .res 4              ; The entry's file if it is open, or 0
hlLine: .res 2              ; The highlighted line, from 0, or $FFFF
hlColor: .res 1             ; Its color

.code

; F11: the next entry
.proc editorBuildNext
    jsr loadResult
    beq DN                  ; No entries
    inc a                   ; The summary (BUILD_SUMMARY) goes to 0
    cmp tmp1
    bcc :+
    lda #0                  ; Past the last: wrap to the first
:   jmp gotoEntry
DN: rts
.endproc

; F9: the previous entry
.proc editorBuildPrev
    jsr loadResult
    beq DN                  ; No entries
    cmp tmp1
    bcs :+                  ; The summary goes to the last
    dec a
    bpl gotoEntry
:   lda tmp1                ; Before the first: wrap to the last
    dec a
    bra gotoEntry
DN: rts
.endproc

; Points ptr3 at the build result. Returns current in A and numEntries in
; tmp1, with Z set if there are no entries.
.proc loadResult
    lda buildResultPtr
    sta ptr3
    lda buildResultPtr+1
    sta ptr3+1
    ldy #BUILDRESULT::numEntries
    lda (ptr3),y
    sta tmp1
    ldy #BUILDRESULT::current
    lda (ptr3),y
    ldx tmp1
    rts
.endproc

; Goes to entry A of the build result (ptr3)
.proc gotoEntry
    ldy #BUILDRESULT::current
    sta (ptr3),y
    jsr entryPtr
    lda #BUILD_HL_NEW
    ldy #BUILDRESULT::hlState
    sta (ptr3),y
    lda #1
    sta buildDirty

    ; The old highlight is erased, even if the editor doesn't move
    jsr editorSetAllRowsDirty

    ldy #BUILDENTRY::line
    lda (ptr4),y
    sta entryLine
    iny
    lda (ptr4),y
    sta entryLine+1

    ; Copy its filename to fnBuf
    jsr entryFileOffset
    ldx #0
:   lda (ptr3),y
    sta fnBuf,x
    beq :+
    iny
    inx
    bne :-
:   cpx #0
    beq DN                  ; No filename

    ; Is the file open?
    ldq firstFile
L1: stq target
    jsr isQZero
    beq L3                  ; It isn't
    stq ptr1
    ldz #EDITFILE::filename
    ldx #0
L2: nop
    lda (ptr1),z
    cmp fnBuf,x
    bne :+                  ; Not this one
    inx
    inz
    cmp #0
    bne L2
    bra L4                  ; This one
:   ldz #EDITFILE::nextFile
    neg
    neg
    nop
    lda (ptr1),z
    bra L1

    ; It isn't open. Is it on the disk?
L3: lda #<fnBuf
    ldx #>fnBuf
    ldy #0
    ldz #0
    jsr doesFileExist
    cmp #0
    beq DN                  ; It isn't

    ; Leave the current file
L4: ldq currentFile
    jsr isQZero
    beq :+
    clc
    jsr renderCursor
    jsr closeEditBuf
    jsr editorClearSelection

    ; Switch to the file, or open it
:   ldq target
    jsr isQZero
    beq :+
    stq currentFile
    bra :++
:   jsr openFile
:   jsr setCursor
    jsr editorSetAllRowsDirty
    jsr editorSetDefaultStatusMessage
    jmp updateStatusBarFilename
DN: rts
.endproc

; Puts the cursor at column 0 of entryLine and centers the line, unless it
; is line 0
.proc setCursor
    lda entryLine
    ora entryLine+1
    bne :+
    rts

    ; newY = entryLine - 1, or numLines if the file is shorter now
:   sec
    lda entryLine
    sbc #1
    sta newY
    lda entryLine+1
    sbc #0
    sta newY+1
    ldz #EDITFILE::numLines
    nop
    lda (currentFile),z
    sta numLines
    inz
    nop
    lda (currentFile),z
    sta numLines+1
    lda numLines
    cmp newY
    lda numLines+1
    sbc newY+1
    bcs :+                  ; Branch if numLines >= newY
    lda numLines
    sta newY
    lda numLines+1
    sta newY+1

:   ldz #EDITFILE::cy
    lda newY
    nop
    sta (currentFile),z
    inz
    lda newY+1
    nop
    sta (currentFile),z
    lda #0
    ldz #EDITFILE::cx
    nop
    sta (currentFile),z
    ldz #EDITFILE::colOff
    nop
    sta (currentFile),z

    ; rowOff = newY - screenrows / 2, but at most numLines - screenrows
    ; (as Ctrl+E has it) and at least 0
    lda screenrows
    lsr a
    sta tmp1
    sec
    lda newY
    sbc tmp1
    sta intOp1
    lda newY+1
    sbc #0
    sta intOp1+1
    sec
    lda numLines
    sbc screenrows
    sta intOp2
    lda numLines+1
    sbc #0
    sta intOp2+1
    jsr gtInt16
    beq :+
    lda intOp2
    sta intOp1
    lda intOp2+1
    sta intOp1+1
:   lda intOp1+1
    bpl :+
    lda #0
    sta intOp1
    sta intOp1+1
:   ldz #EDITFILE::rowOff
    lda intOp1
    nop
    sta (currentFile),z
    inz
    lda intOp1+1
    nop
    sta (currentFile),z
    rts
.endproc

; Points ptr4 at entry A of the build result (ptr3)
.proc entryPtr
    ; ptr4 = ptr3 + entries + A * 8
    .assert .sizeof(BUILDENTRY) = 8, error, "see entryPtr"
    sta ptr4
    lda #0
    sta ptr4+1
    asl ptr4
    rol ptr4+1
    asl ptr4
    rol ptr4+1
    asl ptr4
    rol ptr4+1
    clc
    lda ptr4
    adc #<BUILDRESULT::entries
    sta ptr4
    lda ptr4+1
    adc #>BUILDRESULT::entries
    sta ptr4+1
    clc
    lda ptr4
    adc ptr3
    sta ptr4
    lda ptr4+1
    adc ptr3+1
    sta ptr4+1
    rts
.endproc

; Returns in Y the offset in the build result (ptr3) of the filename of the
; entry at ptr4: files + fileIdx * BUILD_FILENAME_SIZE
.proc entryFileOffset
    .assert BUILD_FILENAME_SIZE = 17, error, "see entryFileOffset"
    .assert BUILDRESULT::files + BUILD_FILES_SIZE <= 256, error, "files"
    ldy #BUILDENTRY::fileIdx
    lda (ptr4),y
    sta tmp1
    asl a
    asl a
    asl a
    asl a
    clc
    adc tmp1
    adc #BUILDRESULT::files
    tay
    rts
.endproc

; Finds the line to highlight in the current file: the line of the entry
; the build line shows, if it is in this file. Sets hlLine to it (from 0)
; and hlColor to the theme's error or warning color. hlLine is $FFFF if
; there is none: no file is open, the build line shows the summary, the
; entry has line 0 or no filename, its line is in another file or past
; the end of this one, or the highlight is stale (BUILD_HL_STALE: a line
; was added or deleted in the file). editorRefreshScreen calls it first.
.proc calcBuildHighlight
    lda #$ff
    sta hlLine
    sta hlLine+1
    ldq currentFile
    jsr isQZero
    lbeq DN
    jsr loadResult
    cmp tmp1
    lbcs DN                 ; The summary
    jsr entryPtr

    ; intOp1 = line - 1, but not for line 0
    ldy #BUILDENTRY::line
    lda (ptr4),y
    sta intOp1
    iny
    lda (ptr4),y
    sta intOp1+1
    ora intOp1
    lbeq DN
    lda intOp1
    bne :+
    dec intOp1+1
:   dec intOp1

    ; Is it the current file's?
    jsr entryFileOffset
    lda (ptr3),y
    beq DN                  ; No filename
    ldz #EDITFILE::filename
L1: nop
    lda (currentFile),z
    cmp (ptr3),y
    bne DN                  ; Another file
    iny
    inz
    cmp #0
    bne L1

    ldz #EDITFILE::numLines
    nop
    lda (currentFile),z
    sta intOp2
    inz
    nop
    lda (currentFile),z
    sta intOp2+1

    ; Has a line been added or deleted since the entry was gone to?
    ldy #BUILDRESULT::hlState
    lda (ptr3),y
    cmp #BUILD_HL_STALE
    beq DN                  ; Yes, before
    cmp #BUILD_HL_KEPT
    beq :+
    lda #BUILD_HL_KEPT      ; The first time: keep numLines
    sta (ptr3),y
    ldy #BUILDRESULT::hlLines
    lda intOp2
    sta (ptr3),y
    iny
    lda intOp2+1
    sta (ptr3),y
    bra RG
:   ldy #BUILDRESULT::hlLines
    lda (ptr3),y
    cmp intOp2
    bne ST
    iny
    lda (ptr3),y
    cmp intOp2+1
    beq RG
ST: lda #BUILD_HL_STALE     ; Yes: the highlight is erased
    ldy #BUILDRESULT::hlState
    sta (ptr3),y
    jmp editorSetAllRowsDirty

    ; Is the line in the file?
RG: lda intOp1
    cmp intOp2
    lda intOp1+1
    sbc intOp2+1
    bcs DN                  ; Branch if line - 1 >= numLines

    lda intOp1
    sta hlLine
    lda intOp1+1
    sta hlLine+1
    ldy #BUILDENTRY::kind
    lda (ptr4),y
    ldx #SYNTAXHL_ERROR
    cmp #BUILD_ERROR
    beq :+
    ldx #SYNTAXHL_WARNING
:   lda themeColors,x
    sta hlColor
DN: rts
.endproc
