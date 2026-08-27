;
; heapwalk.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Code to walk the memory heap and provide some stats

.include "asmlib.inc"
.include "zeropage.inc"
.include "cbm_kernal.inc"
.include "4510macros.inc"

.export heapWalk

.bss

heapEntries: .res 2
numAlloc: .res 2
totalAlloc: .res 4
intBuf: .res 10

.data

strNumEntries: .asciiz "Heap entries: "
strNumAlloc: .asciiz "Allocated entries: "
strTotalAlloc: .asciiz "Total allocated size: "

.code

.proc heapWalk
    lda #0
    ldx #0
:   sta heapEntries,x
    inx
    cpx #8
    bne :-

    ldq heapTop
    stq ptr1

L1: ldz #0
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    beq L2              ; end of the heap entries

    jsr incHeapEntries
    jsr isEntryAllocated
    bpl :+
    jsr addTotalAlloc
    jsr incNumAlloc
:   jsr decPtr
    bra L1

L2: lda #13
    jsr CHROUT
    jsr showHeapEntries
    jsr showNumAlloc
    jsr showTotalAlloc
    rts
.endproc

.proc decPtr
    lda #6
    sta intOp32
    lda #0
    sta intOp32+1
    sta intOp32+2
    sta intOp32+3
    ldq ptr1
    sec
    sbcq intOp32
    stq ptr1
    rts
.endproc

.proc incHeapEntries
    inc heapEntries
    bne :+
    inc heapEntries+1
:   rts
.endproc

.proc incNumAlloc
    inc numAlloc
    bne :+
    inc numAlloc+1
:   rts
.endproc

.proc addTotalAlloc
    ldz #0
    nop
    lda (ptr1),z
    sta intOp32
    inz
    nop
    lda (ptr1),z
    and #$7f
    sta intOp32+1
    lda #0
    sta intOp32+2
    sta intOp32+3
    ldq totalAlloc
    clc
    adcq intOp32
    stq totalAlloc
    rts
.endproc

; This routine sets the N flag if the memory is allocated.
; The flag is cleared if the memory is unallocated.
.proc isEntryAllocated
    ldz #1
    nop
    lda (ptr1),z
    bit #$80
    rts
.endproc

.proc showHeapEntries
    ldx #0
:   lda strNumEntries,x
    beq :+
    jsr CHROUT
    inx
    bne :-
:   lda heapEntries
    sta intOp1
    lda heapEntries+1
    sta intOp1+1
    lda #<intBuf
    ldx #>intBuf
    jsr writeInt16
    jsr writeIntBuf
    lda #13
    jsr CHROUT
    rts
.endproc

.proc showNumAlloc
    ldx #0
:   lda strNumAlloc,x
    beq :+
    jsr CHROUT
    inx
    bne :-
:   lda numAlloc
    sta intOp1
    lda numAlloc+1
    sta intOp1+1
    lda #<intBuf
    ldx #>intBuf
    jsr writeInt16
    jsr writeIntBuf
    lda #13
    jsr CHROUT
    rts
.endproc

.proc showTotalAlloc
    lda totalAlloc+2
    beq :+
    brk
:   lda totalAlloc+3
    beq :+
    brk
:   ldx #0
:   lda strTotalAlloc,x
    beq :+
    jsr CHROUT
    inx
    bne :-
:   lda totalAlloc
    sta intOp1
    lda totalAlloc+1
    sta intOp1+1
    lda #<intBuf
    ldx #>intBuf
    jsr writeInt16
    jsr writeIntBuf
    lda #13
    jsr CHROUT
    rts
.endproc

.proc writeIntBuf
    ldx #0
:   lda intBuf,x
    beq :+
    jsr CHROUT
    inx
    bne :-
:   rts
.endproc
