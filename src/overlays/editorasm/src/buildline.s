;
; buildline.s
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; The build line: the row between the status bar and the message bar
; (see setupScreen). It shows the result of the last build, which the
; editor app keeps (BUILDRESULT in buildresult.inc, buildResultPtr):
;
;    No build
;    Build Success: Error(s): 0, Warning(s): 3
;    Error <msg>, line <n>, <file>                         Showing x of y
;
; The last is the entry BUILDRESULT::current names, while it is less than
; numEntries. ", line n" is left out for line 0 and ", file" for an entry
; with no filename. It is drawn in the theme's UI color, only when
; buildDirty is set. clearScreen sets it.

.include "editor.inc"
.include "buildresult.inc"
.include "zeropage.inc"
.include "4510macros.inc"
.include "asmlib.inc"

.export editorDrawBuildLine, buildDirty

.import buildResultPtr, screenrows, screencols, drawRow

.data

strNoBuild: .asciiz "No build"
strSuccess: .asciiz "Build Success: Error(s): "
strFailed: .asciiz "Build Failed: Error(s): "
strWarnings: .asciiz ", Warning(s): "
strError: .asciiz "Error "
strWarning: .asciiz "Warning "
strLine: .asciiz ", line "
strComma: .asciiz ", "
strShowing: .asciiz "Showing "
strOf: .asciiz " of "

.bss

buildDirty: .res 1          ; Non-zero if the build line needs drawing
buildLine: .res DEFAULT_COLS
lineLen: .res 1             ; The characters in buildLine so far
rightCol: .res 1            ; Where "Showing x of y" starts in buildLine
numBuf: .res 7              ; For writeInt32
entry: .tag BUILDENTRY      ; A copy of the entry shown

.code

.proc editorDrawBuildLine
    lda buildDirty
    bne :+
    rts
:   lda #0
    sta buildDirty
    sta lineLen
    ldx #DEFAULT_COLS-1
    lda #' '
:   sta buildLine,x
    dex
    bpl :-

    lda buildResultPtr
    sta ptr3
    lda buildResultPtr+1
    sta ptr3+1
    ldy #BUILDRESULT::state
    lda (ptr3),y
    .assert BUILD_NONE = 0, error, "see editorDrawBuildLine"
    bne :+
    lda #<strNoBuild
    ldx #>strNoBuild
    jsr appendStr
    bra DR
:   ldy #BUILDRESULT::current
    lda (ptr3),y
    ldy #BUILDRESULT::numEntries
    cmp (ptr3),y
    bcc :+                  ; Branch if current names an entry
    jsr drawSummary
    bra DR
:   jsr drawEntry

    ; Draw the line in the UI color (drawRow with no highlighting)
DR: lda #0
    tax
    tay
    taz
    stq ptr2
    lda #<buildLine
    sta ptr1
    lda #>buildLine
    sta ptr1+1
    lda #0
    sta ptr1+2
    sta ptr1+3
    ldy screenrows
    iny
    ldx #0
    lda screencols
    clc
    jmp drawRow
.endproc

; "Build Success: Error(s): n, Warning(s): n" or "Build Failed: ..."
; ptr3 is the build result.
.proc drawSummary
    ldy #BUILDRESULT::state
    lda (ptr3),y
    cmp #BUILD_FAILED
    beq :+
    lda #<strSuccess
    ldx #>strSuccess
    bra :++
:   lda #<strFailed
    ldx #>strFailed
:   jsr appendStr
    ldy #BUILDRESULT::numErrors
    jsr appendResultNum
    lda #<strWarnings
    ldx #>strWarnings
    jsr appendStr
    ldy #BUILDRESULT::numWarns
    ; Fall through to appendResultNum
.endproc

; Appends the word at offset Y of the build result (ptr3)
.proc appendResultNum
    lda (ptr3),y
    pha
    iny
    lda (ptr3),y
    tax
    pla
    jmp appendNum
.endproc

; "Error <msg>, line <n>, <file>", then "Showing x of y" at the right.
; ptr3 is the build result and A the entry to show.
.proc drawEntry
    ; ptr4 = the entry: ptr3 + entries + A * 8
    .assert .sizeof(BUILDENTRY) = 8, error, "see drawEntry"
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
    ldy #.sizeof(BUILDENTRY)-1
:   lda (ptr4),y
    sta entry,y
    dey
    bpl :-

    ; The kind
    lda entry+BUILDENTRY::kind
    cmp #BUILD_WARNING
    beq :+
    lda #<strError
    ldx #>strError
    bra :++
:   lda #<strWarning
    ldx #>strWarning
:   jsr appendStr

    ; The message, which can be in any bank
    ldx #3
:   lda entry+BUILDENTRY::msg,x
    sta ptr4,x
    dex
    bpl :-
    ldz #0
:   nop
    lda (ptr4),z
    beq :+
    jsr appendChar
    inz
    bne :-

    ; The line, if it isn't 0
:   lda entry+BUILDENTRY::line
    ora entry+BUILDENTRY::line+1
    beq :+
    lda #<strLine
    ldx #>strLine
    jsr appendStr
    lda entry+BUILDENTRY::line
    ldx entry+BUILDENTRY::line+1
    jsr appendNum

    ; The file, if it has a name: files + fileIdx * BUILD_FILENAME_SIZE
:   .assert BUILD_FILENAME_SIZE = 17, error, "see drawEntry"
    .assert BUILDRESULT::files + BUILD_FILES_SIZE <= 256, error, "see drawEntry"
    lda entry+BUILDENTRY::fileIdx
    asl a
    asl a
    asl a
    asl a
    clc
    adc entry+BUILDENTRY::fileIdx
    adc #BUILDRESULT::files
    tay
    lda (ptr3),y
    beq SH                  ; No filename
    phy
    lda #<strComma
    ldx #>strComma
    jsr appendStr
    ply
:   lda (ptr3),y
    beq SH
    jsr appendChar
    iny
    bne :-

    ; "Showing x of y", put at the right end of the line
SH: lda lineLen
    sta rightCol
    lda #<strShowing
    ldx #>strShowing
    jsr appendStr
    ldy #BUILDRESULT::current
    lda (ptr3),y
    inc a
    ldx #0
    jsr appendNum
    lda #<strOf
    ldx #>strOf
    jsr appendStr
    ldy #BUILDRESULT::numEntries
    lda (ptr3),y
    ldx #0
    jsr appendNum

    ; Move the characters from rightCol to lineLen to the end of the line,
    ; from the last one back, and put spaces where they were.
    ldx lineLen
    ldy #DEFAULT_COLS
:   cpx rightCol
    beq :+
    dex
    dey
    lda buildLine,x
    sta buildLine,y
    bra :-
:   lda #' '
:   dey                     ; Space from rightCol to the moved text
    cpy rightCol
    bcc :+
    sta buildLine,y
    bra :-
:   rts
.endproc

; Appends the unsigned number in A/X to buildLine
.proc appendNum
    sta intOp1
    stx intOp1+1
    lda #0
    sta intOp2
    sta intOp2+1
    lda #<numBuf
    ldx #>numBuf
    jsr writeInt32
    lda #<numBuf
    ldx #>numBuf
    ; Fall through to appendStr
.endproc

; Appends the zero-terminated string at A/X (in bank 0) to buildLine
.proc appendStr
    sta ptr1
    stx ptr1+1
    ldy #0
:   lda (ptr1),y
    beq :+
    jsr appendChar
    iny
    bne :-
:   rts
.endproc

; Appends the character in A to buildLine, unless it's full. X is kept.
.proc appendChar
    phx
    ldx lineLen
    cpx #DEFAULT_COLS
    bcs :+
    sta buildLine,x
    inc lineLen
:   plx
    rts
.endproc
