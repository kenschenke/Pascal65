;
; heapSummary.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; heapSummary routine

.include "asmlib.inc"
.include "zeropage.inc"
.include "cbm_kernal.inc"
.include "4510macros.inc"

.export heapSummary

.data

strNumAlloc: .asciiz ", Num alloc: "
strNumFree: .asciiz ", Num free: "
strHeapAlloc: .asciiz "Mem alloc: "

.bss

bankNum: .res 1
intBuf: .res 10
matPtr: .res 4
entriesAlloc: .res 2
entriesFree: .res 2
totalAlloc: .res 4

.code

; This routine prints a one-line summary of the memory heap.
;    Total memory allocated
;    Number of MAT entries for free blocks
;    Number of MAT entries for allocated blocks
.proc heapSummary
    ; Keep a running total in intOp32
    lda #0
    sta totalAlloc
    sta totalAlloc+1
    sta totalAlloc+2
    sta totalAlloc+3
    sta intOp2
    sta intOp2+1

    sta entriesAlloc
    sta entriesAlloc+1
    sta entriesFree
    sta entriesFree+1

    ; Loop through the banks
    lda #0
    sta bankNum
BN: lda bankNum
    jsr getMemHeapForBank
    jsr isQZero
    beq L5
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
    inc bankNum
    bra BN

    ; Is the MAT entry allocated?
L2: ldz #1
    nop
    lda (ptr1),z
    bpl L3                  ; Branch if not allocated
    and #$7f
    sta intOp1+1
    dez
    nop
    lda (ptr1),z
    sta intOp1
    ldq totalAlloc
    clc
    adcq intOp1
    stq totalAlloc
    jsr incEntriesAlloc
    bra L4

    ; Entry is not allocated
L3: jsr incEntriesFree

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
    bra L1

    ; Print the message and allocated memory
L5: ldx #0
:   lda strHeapAlloc,x
    beq :+
    jsr CHROUT
    inx
    bne :-
:   ldq totalAlloc
    stq intOp1
    lda #<intBuf
    ldx #>intBuf
    jsr writeInt32
    ldx #0
:   lda intBuf,x
    beq :+
    jsr CHROUT
    inx
    bne :-

:   ldx #0
:   lda strNumAlloc,x
    beq :+
    jsr CHROUT
    inx
    bne :-
:   lda entriesAlloc
    sta intOp1
    lda entriesAlloc+1
    sta intOp1+1
    jsr writeIntOp1

    ldx #0
:   lda strNumFree,x
    beq :+
    jsr CHROUT
    inx
    bne :-
:   lda entriesFree
    sta intOp1
    lda entriesFree+1
    sta intOp1+1
    jsr writeIntOp1

    lda #13
    jsr CHROUT

    rts
.endproc

.proc incEntriesAlloc
    inc entriesAlloc
    bne :+
    inc entriesAlloc+1
:   rts
.endproc

.proc incEntriesFree
    inc entriesFree
    bne :+
    inc entriesFree+1
:   rts
.endproc

.proc writeIntOp1
    lda #<intBuf
    ldx #>intBuf
    jsr writeInt16
    ldx #0
:   lda intBuf,x
    beq :+
    jsr CHROUT
    inx
    bne :-
:   rts
.endproc
