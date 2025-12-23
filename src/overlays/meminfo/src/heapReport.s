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

.include "asmlib.inc"
.include "zeropage.inc"
.include "cbm_kernal.inc"
.include "4510macros.inc"

.export heapReport

.import dumpHex

.data

header1: .asciiz "Addr   Size  Used"
header2: .asciiz "-----  ----  ----"
yes: .byte "yes", 13, 0
no: .byte "no", 13, 0

.bss

intBuf: .res 10
matPtr: .res 4

.code

.proc heapReport
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

    ; Start at heapTop
    ldq heapTop
    stq matPtr

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
L2: ldz #1
    nop
    lda (ptr1),z
    and #$80
    beq L4
    
    ; Print the entry's address
    ldz #2
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
    bpl L3                  ; Branch if not allocated
    ldx #0
:   lda yes,x
    beq L4
    jsr CHROUT
    inx
    bne :-
    bra L4

    ; Entry is not allocated
L3: ldx #0
:   lda no,x
    beq L4
    jsr CHROUT
    inx
    bne :-

    ; Move to the next MAT entry
L4: lda #6
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
