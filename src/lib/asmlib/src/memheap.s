;
; memheap.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Memory heap routines

.include "zeropage.inc"
.include "error.inc"
.include "4510macros.inc"

.export initMemHeap, heapAlloc, heapFree

.import geInt16, ltInt16, geUint32, runtimeError

.bss

lastBlock: .res 4

.code

; Memory Allocation Table (MAT)
; Each entry in the MAT is six bytes.
;   The first two bytes are the length of the allocation for this entry.
;   The last four bytes are the 32-bit pointer to the memory for the entry.
;   The high bit of the second size byte is 0 if the block is current unallocated.
; The MAT is at the end of the heap and grows downward until the heap is full.
; The end of the MAT signaled by six $00 bytes.

; This memory heap is allocated using a Best Fit algorithm.
; The MAT is scanned for the smallest free block large enough
; to satisfy the request. If no free blocks are found in the
; MAT then a new block of the requested size is allocated and
; added to the end of the MAT.

; This routine intiailizes the two memory heap pointers in zero page.
; heapBottom = bottom of heap where memory is allocated
; heapTop = top of heap where memory allocation table goes
.proc initMemHeap
    ; The memory heap starts at $42000
    ; This leaves room for screen RAM at $407fc
    lda #$00
    ldy #$04
    ldx #$20
    taz
    stq heapBottom          ; Store 0x00042000 in heapBottom

    ;  Z  Y  X  A
    ; 00 05 ff fa
    lda #$fa
    ldy #$05
    ldx #$ff
    ldz #$00
    stq heapTop             ; Store 0x00060000-6 in heapTop

    ; Store six zeros for the first entry in the MAT
    ldz #5
    lda #0
:   nop
    sta (heapTop),z
    dez
    bpl :-

    rts
.endproc

; Size to allocate in A/X
; If allocation fails, a runtime error is triggered.
; Pointer to memory returned in Q
;   tmp1/tmp2 - requested buffer size
;   ptr1 - current location in MAT
;   ptr2 - location in MAT of smallest availble block
;          that satisfies requested buffer size.
;   ptr3 - location in MAT of last allocated block.
;          This is used when a new block is to be added
;          at the end of the heap.
.proc heapAlloc
    ; Algorithm:
    ;   Store A/X in tmp1/tmp2
    ;   Start with ptr1 pointing to heapTop and $00000000 in ptr2
    ;   Loop through entire MAT and update ptr2 when a smaller
    ;       available block is found.
    ;   If ptr2 is still $00000000 then allocate a new block and
    ;       add it to the end of the MAT.
    ;   If ptr2 contains a block, mark it as allocated and
    ;       return the memory address in Q.

    ; Initialization
    sta tmp1
    stx tmp2
    ; Copy heapTop to ptr1
    neg
    neg
    lda heapTop
    neg
    neg
    sta ptr1
    ; Zero out ptr2 and ptr3
    lda #0
    ldx #3
:   sta ptr2,x
    sta ptr3,x
    dex
    bpl :-

    ; Loop through the entire MAT looking for the smallest available
    ; block that can satisfy the requested allocation size.
L1: ldz #5
L2: nop
    lda (ptr1),z
    bne L4
    dez
    bpl L2
    ; End of MAT reached.
    ; If ptr3 is zero, this is the first heap entry.
    lda ptr3
    ora ptr3+1
    ora ptr3+2
    ora ptr3+3
    bne L3
    ; This is the first entry in the heap
    jmp NewEntry
L3: ; Reached the end of the MAT. Check if ptr2 is non-zero.
    ; It points to the smallest available MAT entry.
    lda ptr2
    ora ptr2+1
    ora ptr2+2
    ora ptr2+3
    bne L31
    ; ptr2 is zero which means there are no available blocks
    ; in the MAT that can hold the requested allocation.
    jmp NewEntry
L31:
    ; ptr2 is non-zero which means it points to the MAT entry
    ; for the smallest block that can hold the requested allocation.
    jmp ReUseEntry
L4: ldz #1
    nop
    lda (ptr1),z        ; Look at the second byte of the block size
    and #$80            ; Isolate the high bit
    bne L5              ; If set, this block is allocated. Move on.
    ; Block is available, but is it big enough?
    nop
    lda (ptr1),z
    sta intOp1 + 1      ; Store current block's size in intOp1
    dez
    nop
    lda (ptr1),z
    sta intOp1
    lda tmp1
    sta intOp2          ; Store desired block size in intOp2
    lda tmp2
    sta intOp2+1
    jsr geInt16         ; Is current block size > desired block size?
    beq L5              ; It is not.
    ; The block is big enough, but is it larger than
    ; previous blocks that were big enough?
    ; intOp1 still contains the current block's size
    lda ptr2            ; Is ptr2 zero?
    ora ptr2+1
    ora ptr2+2
    ora ptr2+3
    bne L41
    ; Ptr2 is zero, which means the current block is the
    ; first on that has been big enough.
    ldz #3              ; Save the current MAT address
:   nop                 ; in ptr2 for future reference.
    lda (ptr1),z
    nop
    sta (ptr1),z
    dez
    bpl :-
    jmp L5              ; Move on to the next MAT entry
L41:
    ; Prt2 contains a previously-seen block that was
    ; big enough. Compare the current block's size
    ; to the block pointed to by ptr2.
    ; intOp1 still contains the current block's size.
    ldz #0
    nop
    lda (ptr2),z
    sta intOp2
    iny
    nop
    lda (ptr2),z
    sta intOp2 + 1
    jsr ltInt16         ; Is current size < last seen size?
    beq L5              ; It is not. Ignore this block.
    ; The current block is smaller than previously-examined
    ; blocks. Remember this block as the new smallest one.
    ldz #3
:   nop
    lda (ptr1),z
    nop
    sta (ptr2),z
    dez
    bpl :-
L5: ldq ptr1
    stq ptr3
    jsr incMATPtr       ; Move to the next block in the MAT
    jmp L1
ReUseEntry:
    ldz #1              ; Second byte in MAT entry
    nop
    lda (ptr2),z        ; Load it
    ora #$80            ; Set the high bit
    nop
    sta (ptr2),z        ; Save it back
    ldz #5              ; Address of block in MAT entry
    ldx #3
:   nop
    lda (ptr2),z
    sta tmp1,x
    dex
    dez
    bpl :-
    jmp L99
NewEntry:               ; Add a new entry to the MAT
    jsr checkFreeSpace
    ldz #0
    lda tmp1            ; Load the requested buffer size
    nop
    sta (ptr1),z        ; Store it in the first two bytes
    inz                 ; of the MAT entry.
    lda tmp2            ; Load the high byte of the buffer size
    ora #$80            ; Set the "allocated" bit
    nop
    sta (ptr1),z
    lda ptr3            ; Check if ptr3 is non-zero
    ora ptr3+1          ; If so, use it to calculate the address
    ora ptr3+2          ; of the next heap block.
    ora ptr3+3
    bne L6
    ; ptr3 is zero, which means this is the first block in the MAT.
    ; Copy the heapBottom pointer into the first MAT entry and store
    ; it in tmp1-tmp4.
    ldz #5
    ldx #3
:   lda heapBottom,x
    nop
    sta (ptr1),z
    sta tmp1,x
    dez
    dex
    bpl :-
    jmp L7
L6: ; Add the last block's pointer and size. The last block's pointer
    ; is stored in ptr3. Store the size in ptr4, add them, and store
    ; the result in tmp1-tmp4 then copy it into the MAT entry in ptr1.
    ldz #5                  ; First, copy the block pointer from ptr3
    ldx #3                  ; to ptr4
:   nop
    lda (ptr3),z
    sta ptr4,x
    dez
    dex
    bpl :-
    ; Next, copy the block size into tmp1-tmp4
    ldz #0
    nop
    lda (ptr3),z
    sta tmp1
    inz
    nop
    lda (ptr3),z
    and #$7f                ; Clear the "allocated" bit
    sta tmp2
    lda #0
    sta tmp3
    sta tmp4
    ; Next, add ptr4 and tmp1-tmp4 and store the result in tmp1-tmp4
    clc
    ldq ptr4
    adcq tmp1
    stq tmp1
    ; Store the pointer in the new block entry
    ldz #5
    ldx #3
:   lda tmp1,x
    nop
    sta (ptr1),z
    dez
    dex
    bpl :-
L7: ; Increment ptr1 to the next block entry
    jsr incMATPtr
    lda #0                  ; Store zeros in all six bytes
    ldz #5
:   nop
    sta (ptr1),z
    dez
    bpl :-
L99:neg                 ; Load the block's address into Q
    neg                 ; for return to the caller.
    lda tmp1
    rts
.endproc

.proc incMATPtr
    lda #6
    sta intOp32
    lda #0
    sta intOp32+1
    sta intOp32+2
    sta intOp32+3
    sec
    ldq ptr1
    sbcq intOp32
    stq ptr1
    rts
.endproc

; This routine calculates the address of the last allocated block
; and returns it in Q
; ptr4 is used to walk through the MAT
; lastBlock points to the end of the last allocated block
.proc getEndOfLastBlock
    ldq heapBottom
    stq lastBlock
    ldq heapTop
    stq ptr4
L1: ldz #5              ; Is the current entry all zeros?
:   nop
    lda (ptr4),z
    bne :+
    dez
    bpl :-
    bmi L3              ; Entry is all zeros (end of MAT)
    ; Is the current entry allocated?
:   ldz #1
    nop
    lda (ptr4),z
    and #$80
    beq L2              ; Skip this entry if allocated
    ; Update lastBlock and add size
    ldz #0
    nop
    lda (ptr4),z
    sta lastBlock
    inz
    nop
    lda (ptr4),z
    and #$7f            ; Clear the allocated bit
    sta lastBlock+1
    lda #0
    sta lastBlock+2
    sta lastBlock+3
    inz
    ; Add the block pointer in ptr4 to lastBlock
    clc
    nop
    lda (ptr4),z
    adc lastBlock
    sta lastBlock
    inz
    nop
    lda (ptr4),z
    adc lastBlock+1
    sta lastBlock+1
    inz
    nop
    lda (ptr4),z
    adc lastBlock+2
    sta lastBlock+2
    inz
    nop
    lda (ptr4),z
    adc lastBlock+3
    sta lastBlock+3
    ; Move to the next MAT entry
L2: lda ptr4
    sec
    sbc #6
    sta ptr4
    lda ptr4+1
    sbc #0
    sta ptr4+1
    lda ptr4+2
    sbc #0
    sta ptr4+2
    lda ptr4+3
    sbc #0
    sta ptr4+3
    jmp L1
L3: neg
    neg
    lda lastBlock
    rts
.endproc

; This routine checks the amount of free space in the heap to see if
; there's enough left for the requested block. If not, a runtime error is triggered.
.proc checkFreeSpace
    jsr getEndOfLastBlock
    stq intOp1
    lda tmp1
    sta intOp32
    lda tmp2
    sta intOp32+1
    lda #0
    sta intOp32+2
    sta intOp32+3
    clc
    ldq intOp1
    adcq intOp32
    stq intOp1
    ldq ptr4
    stq intOp32
    jsr geUint32
    beq :+
    ; The block won't fit. Abort with a runtime error
    lda #rteOutOfMemory
    jsr runtimeError
:   rts
.endproc

; Free a block of memory from the heap
; Q contains the pointer to the memory block
.proc heapFree
    ; Algorithm:
    ;   Walk through the MAT, looking for the caller's memory block.
    ;   When found, clear the high bit of the second byte.
    ;
    ;   ptr1 - the current MAT entry
    ;   ptr2 - the memory block to free

    ; Initialization
    stq ptr2            ; Save the memory block ptr in ptr2
    ldq heapTop         ; Load the MAT pointer into ptr1
    stq ptr1
L1: ldz #5              ; Is the current MAT entry all zeros?
L11:
    nop
    lda (ptr1),z
    bne L2              ; Branch if this byte is non-zero
    dez
    bmi L4              ; All six bytes are zero. No more MAT entries.
    bpl L11
L2: ldz #2              ; Compare this entry's address to ptr2
    nop
    lda (ptr1),z
    cmp ptr2
    bne L21
    inz
    nop
    lda (ptr1),z
    cmp ptr2+1
    bne L21
    inz
    nop
    lda (ptr1),z
    cmp ptr2+2
    bne L21
    inz
    nop
    lda (ptr1),z
    cmp ptr2+3
    bne L21             ; This address matches
    beq L3
L21:
    jsr incMATPtr       ; Move to the next MAT entry
    jmp L1
L3: ; Found it.
    ldz #1
    nop
    lda (ptr1),z
    and #$7f
    nop
    sta (ptr1),z
L4: ; Fall through to trimFreeBlocks
.endproc

; This routine trims free blocks from the end of the MAT.
; It starts by going to the last entry in the MAT and writing
; zeros to each free entry until it reaches an allocated entry
; or the start of the MAT.
;
; This is called after each free to help reduce fragmentation.
;
; Algorithm:
;   1. Walk through the entire MAT to find the last entry.
;   2. Work backwards through the MAT entries until we find
;      an allocated entry or reach the top of the MAT.
;   3. When working backwards, if an unallocated entry is found,
;      zero it out.

.proc trimFreeBlocks
    ; Initialization
    ldq heapTop
    stq ptr1                ; Copy the start of the MAT to ptr1
    lda #6                  ; Initialize tmp1-tmp4 as $06.
    sta tmp1                ; This is used to walk backwords through the MAT.
    lda #0
    sta tmp2
    sta tmp3
    sta tmp4
L1: ldz #5                  ; Check if this entry is anything but six zeros
L2: nop
    lda (ptr1),z
    bne L3                  ; Branch if one of the bytes is non-zero
    dez
    bpl L2
    bmi L4                  ; All six bytes are zero
L3: ; This entry is used.
    ; Go to the next one.
    jsr incMATPtr
    jmp L1
L4: ; Found the last entry. Work backwards setting entries to zero until
    ; (1) We're at the first entry.
    ;   -or-
    ; (2) We reach an allocated entry.
    ; Is this entry allocated?
    ldz #1
    nop
    lda (ptr1),z
    and #$80
    bne L9                  ; Branch if entry is allocated.
    ; Zero out this entry
    ldz #5
    lda #0
L6: nop
    sta (ptr1),z
    dez
    bpl L6
    ; See if this is the first entry in the MAT
    lda ptr1
    cmp heapTop
    bne L7
    lda ptr1+1
    cmp heapTop+1
    bne L7
    lda ptr1+2
    cmp heapTop+2
    bne L7
    lda ptr1+3
    cmp heapTop+3
    beq L9                  ; Branch if this is the first MAT entry.
    ; Go to the next entry by adding 6 to ptr1
L7: clc
    ldq ptr1
    adcq tmp1
    stq ptr1
    jmp L4
L9: rts
.endproc
