;
; covpatch.s
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Coverage build support for memtest.
;
; covInstall points asmlib's jump table entries for the heap routines at the
; instrumented copy of memheap.s, so the tests run it without any changes.
; covSave writes the coverage map to the disk as "memtest.cov".

.include "cbm_kernal.inc"
.include "c64.inc"
.include "asmlib.inc"
.include "zeropage.inc"

.export covInstall, covSave

.import cov_initMemHeap, cov_heapAlloc, cov_heapFree
.import cov_getMemHeapForBank, cov_clearMemHeap
.import covMap, covSize

; Replaces the address of the JMP at entry with target
.macro PATCH entry, target
    lda #<target
    sta entry+1
    lda #>target
    sta entry+2
.endmacro

.data

fname: .byte "memtest.cov"
fnameEnd:

.code

.proc covInstall
    PATCH initMemHeap, cov_initMemHeap
    PATCH heapAlloc, cov_heapAlloc
    PATCH heapFree, cov_heapFree
    PATCH getMemHeapForBank, cov_getMemHeapForBank
    PATCH clearMemHeap, cov_clearMemHeap

    ; Clear the coverage map
    lda #<covMap
    sta ptr1
    lda #>covMap
    sta ptr1+1
    lda #<covSize
    sta ptr2
    lda #>covSize
    sta ptr2+1
    ldy #0
L1: lda ptr2
    ora ptr2+1
    beq L3
    tya
    sta (ptr1),y
    inc ptr1
    bne :+
    inc ptr1+1
:   lda ptr2
    bne L2
    dec ptr2+1
L2: dec ptr2
    bra L1
L3: rts
.endproc

.proc covSave
    lda #fnameEnd-fname
    ldx #<fname
    ldy #>fname
    jsr SETNAM
    lda #1
    ldx DEVNUM
    ldy #0
    jsr SETLFS
    lda #<covMap
    sta ptr1
    lda #>covMap
    sta ptr1+1
    lda #ptr1
    ldx #<(covMap+covSize)
    ldy #>(covMap+covSize)
    jmp SAVE
.endproc
