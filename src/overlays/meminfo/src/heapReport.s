;
; heapReport.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; heapReport routine

.include "c64.inc"
.include "asmlib.inc"
.include "zeropage.inc"
.include "cbm_kernal.inc"
.include "4510macros.inc"

.export heapReport, openHeapReport, closeHeapReport

.import dumpHex

.data

bankTitle1: .asciiz "=============================="
bankTitle2: .asciiz "Bank "
header1: .asciiz "Addr   Size  Used"
header2: .asciiz "-----  ----  ----"
yes: .byte "yes", 13, 0
no: .byte "no", 13, 0
filename: .asciiz "heap.txt,s,w"
filename2:

.bss

bankNum: .res 1
intBuf: .res 10
matPtr: .res 4
hasHeader: .res 1           ; non-zero if the header has been printed for the current bank
includeAllEntries: .res 1

.code

; This opens an output file to "heap.txt" and sets it as the current output device.
.proc openHeapReport
    ldx #<filename
    ldy #>filename
    lda #filename2-filename
    jsr SETNAM

    ldx DEVNUM
    lda #1
    tay
    iny
    jsr SETLFS

    jsr OPEN

    ldx #1
    jsr CHKOUT

    rts
.endproc

.proc closeHeapReport
    lda #1
    jsr CLOSE

    ldx #0
    jsr CHKOUT

    rts
.endproc

; This routine loops through the banks, generating a report
; for each one.
;
; A contains a zero if the report should only include allocated entries.
.proc heapReport
    sta includeAllEntries
    lda #0
    sta bankNum

    ; Loop through the banks
L1: lda bankNum
    jsr getMemHeapForBank
    jsr isQZero
    beq L2

    stq matPtr
    jsr heapReportForBank

    inc bankNum
    bra L1

L2: rts
.endproc

; matPtr is already filled in
.proc heapReportForBank
    lda #0
    sta hasHeader

    ; Loop through the MAT entries
L1: ldq matPtr
    stq ptr1

    ; Is the current MAT zero?
    ldz #0
:   nop
    lda (ptr1),z
    bne L2
    inz
    cpz #6
    bne :-
    jmp L5

    ; Is the current entry allocated?
L2: lda includeAllEntries
    bne L3
    ldz #1
    nop
    lda (ptr1),z
    and #$80
    bne L3
    jmp NX

L3: lda hasHeader
    bne :+
    ldq ptr1
    jsr pushQ
    jsr reportHeader
    lda #1
    sta hasHeader
    jsr popQ
    stq ptr1
    
    ; Print the entry's address
:   ldz #2
    neg
    neg
    nop
    lda (ptr1),z
    jsr dumpHex
    lda #' '
    jsr CHROUT
    jsr CHROUT

    ; Print the entry's size
    ldz #0
    nop
    lda (ptr1),z
    sta intOp1
    inz
    nop
    lda (ptr1),z
    and #$7f
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
:   lda #' '
:   cpx #4
    beq :+
    jsr CHROUT
    inx
    bne :-
:   lda #' '
    jsr CHROUT
    jsr CHROUT

    ; Is the MAT entry allocated?
    ldq matPtr
    stq ptr1
    ldz #1
    nop
    lda (ptr1),z
    bpl L4                  ; Branch if not allocated
    ldx #0
:   lda yes,x
    beq NX
    jsr CHROUT
    inx
    bne :-
    bra NX

    ; Entry is not allocated
L4: ldx #0
:   lda no,x
    beq NX
    jsr CHROUT
    inx
    bne :-

    ; Move to the next MAT entry
NX: lda #6
    sta intOp32
    lda #0
    sta intOp32+1
    sta intOp32+2
    sta intOp32+3
    ldq matPtr
    sec
    sbcq intOp32
    stq matPtr
    jmp L1

    ; Done
L5: lda #13
    jsr CHROUT

    rts
.endproc

; This routine prints the report header for a bank.
.proc reportHeader
    ldx #0
:   lda bankTitle1,x
    beq :+
    jsr CHROUT
    inx
    bne :-
:   lda #13
    jsr CHROUT

    ldx #0
:   lda bankTitle2,x
    beq :+
    jsr CHROUT
    inx
    bne :-
:   lda bankNum
    clc
    adc #1
    sta intOp1
    lda #0
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
:   lda #13
    jsr CHROUT

    ldx #0
:   lda bankTitle1,x
    beq :+
    jsr CHROUT
    inx
    bne :-
:   lda #13
    jsr CHROUT
    jsr CHROUT

    ; Print the headers
    ldx #0
:   lda header1,x
    beq :+
    jsr CHROUT
    inx
    bne :-
:   lda #13
    jsr CHROUT
    ldx #0
:   lda header2,x
    beq :+
    jsr CHROUT
    inx
    bne :-
:   lda #13
    jsr CHROUT

    rts
.endproc
