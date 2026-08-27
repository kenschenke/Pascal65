;
; editorDebug.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Editor debug functionality

.include "c64.inc"
.include "meminfo.inc"
.include "cbm_kernal.inc"

.ifdef __DEBUG__

.export editorDebug

.import initMemInfo

.data

stateFn: .byte "zzstate,s,w"
stateFn2:

heapFn: .byte "heap.txt"
heapFn2:

.code

.proc editorDebug
    ; Load the meminfo overlay
    jsr initMemInfo

    ; Set up the heap report
    jsr openHeapReport

    ; Write the heap report
    jsr heapReport

    ; Close the heap report
    jsr closeHeapReport

    ; Write an editor state file which opens "heap.txt" automatically
    jsr editorWriteHeapStateFile

    rts
.endproc

.proc editorWriteHeapStateFile
    ldx DEVNUM
    lda #1
    tay
    iny
    jsr SETLFS
    lda #stateFn2-stateFn
    ldx #<stateFn
    ldy #>stateFn
    jsr SETNAM
    jsr OPEN
    ldx #1
    jsr CHKOUT

    ; Write number of files
    lda #1              ; one open file
    jsr CHROUT

    ; Write a block for heap.txt
    lda #1              ; is current file
    jsr CHROUT
    lda #heapFn2-heapFn ; length of filename
    jsr CHROUT
    ldx #0
:   lda heapFn,x
    jsr CHROUT
    inx
    cpx #heapFn2-heapFn
    bne :-
    lda #0
    jsr CHROUT          ; cursor X position
    lda #0
    jsr CHROUT
    lda #0
    jsr CHROUT          ; cursor Y position (2 bytes)
    lda #0
    jsr CHROUT          ; column offset
    lda #0
    jsr CHROUT
    lda #0
    jsr CHROUT          ; row offset (2 bytes)

    ; Close the state file
    lda #1
    jsr CLOSE
    ldx #0
    jsr CHKOUT

    rts
.endproc

.endif ; end of ifdef __DEBUG__
