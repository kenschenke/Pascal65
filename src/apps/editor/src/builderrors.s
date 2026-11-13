;
; builderrors.s
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Collects the result of a build in the IDE (see buildresult.inc). The
; compiler reports each error and warning to logError and logWarning
; (initCompilerErrors and initCompilerWarnings), which record it and print
; nothing. The result is in the app's BSS, so it lasts while the overlay is
; reloaded and the heap is cleared.

.include "zeropage.inc"
.include "asmlib.inc"
.include "4510macros.inc"
.include "buildresult.inc"

.export initBuildResult, finishBuildResult, buildHasErrors
.export logError, logWarning, buildResult

.bss

buildResult: .tag BUILDRESULT
entry: .tag BUILDENTRY          ; The entry being recorded

RESULT_SIZE = .sizeof(BUILDRESULT)
.assert RESULT_SIZE > 256 && RESULT_SIZE <= 512, error, "result size"
.assert BUILD_ENTRIES_SIZE <= 256, error, "entries indexed by X"

.code

; Clears the result: no build, no entries, no files and the summary shown
.proc initBuildResult
    lda #0
    tax
:   sta buildResult,x
    sta buildResult+RESULT_SIZE-256,x
    inx
    bne :-
    lda #BUILD_SUMMARY
    sta buildResult+BUILDRESULT::current
    rts
.endproc

; Sets the result's state once the build is over: BUILD_FAILED if an error
; was reported, BUILD_SUCCESS otherwise
.proc finishBuildResult
    ldx #BUILD_SUCCESS
    jsr buildHasErrors
    beq :+
    ldx #BUILD_FAILED
:   stx buildResult+BUILDRESULT::state
    rts
.endproc

; The Z flag is clear if the build has reported an error
.proc buildHasErrors
    lda buildResult+BUILDRESULT::numErrors
    ora buildResult+BUILDRESULT::numErrors+1
    rts
.endproc

; Called when the compiler flags an error.
; Inputs:
;    A/X - the source code line
;    Y   - the error number (error.inc)
;    Runtime stack - pointer to the null-terminated error message
; Destroys ptr1 and intOp1
.proc logError
    ldy #BUILD_ERROR
    sty entry+BUILDENTRY::kind
    ldy #BUILDRESULT::numErrors
    bra record
.endproc

; Called when the compiler flags a warning. The inputs are logError's.
.proc logWarning
    ldy #BUILD_WARNING
    sty entry+BUILDENTRY::kind
    ldy #BUILDRESULT::numWarns
    ; Fall through to record
.endproc

; Counts an error or warning in the word at offset Y of the result and
; keeps it if there is room. A/X is the line.
.proc record
    sta entry+BUILDENTRY::line
    stx entry+BUILDENTRY::line+1

    ; Count it. The count stops at $FFFF.
    lda buildResult,y
    and buildResult+1,y
    cmp #$ff
    beq :+
    lda buildResult,y
    clc
    adc #1
    sta buildResult,y
    lda buildResult+1,y
    adc #0
    sta buildResult+1,y

:   jsr popQ
    stq entry+BUILDENTRY::msg

    lda buildResult+BUILDRESULT::numEntries
    cmp #MAX_BUILD_ENTRIES
    bcs DN                      ; No room: counted, not kept
    jsr findFile
    sta entry+BUILDENTRY::fileIdx

    ; Copy it to the end of the entries
    lda buildResult+BUILDRESULT::numEntries
    asl a
    asl a
    asl a
    tax
    ldy #0
:   lda entry,y
    sta buildResult+BUILDRESULT::entries,x
    inx
    iny
    cpy #.sizeof(BUILDENTRY)
    bne :-
    inc buildResult+BUILDRESULT::numEntries
DN: rts
.endproc

.assert .sizeof(BUILDENTRY) = 8, error, "record multiplies by 8"

; Returns in A the files table index of the file the compiler is in
; (getCompilerFilename), giving it a slot if it has none. It is
; BUILD_FILE_UNKNOWN if the table is full or there is no filename.
; Destroys ptr1 and intOp1.
.proc findFile
    jsr getCompilerFilename
    sta ptr1
    stx ptr1+1
    ldy #0
    lda (ptr1),y
    beq UN                      ; No filename

    ; intOp1 walks the slots in use
    lda #<(buildResult+BUILDRESULT::files)
    sta intOp1
    lda #>(buildResult+BUILDRESULT::files)
    sta intOp1+1
    ldx #0
L1: cpx buildResult+BUILDRESULT::numFiles
    beq NW
    ldy #0
:   lda (ptr1),y
    cmp (intOp1),y
    bne NX
    iny
    cmp #0
    bne :-
    txa                         ; The same name
    rts
NX: clc
    lda intOp1
    adc #BUILD_FILENAME_SIZE
    sta intOp1
    bcc :+
    inc intOp1+1
:   inx
    bra L1

    ; A new name. intOp1 is the next slot.
NW: cpx #MAX_BUILD_FILES
    beq UN                      ; The table is full
    ldy #0
:   lda (ptr1),y
    sta (intOp1),y
    beq :+
    iny
    cpy #BUILD_FILENAME_SIZE-1
    bne :-
    lda #0
    sta (intOp1),y
:   inc buildResult+BUILDRESULT::numFiles
    txa
    rts

UN: lda #BUILD_FILE_UNKNOWN
    rts
.endproc
