;
; memheap.s
; Ken Schenke (kenschenke@gmail.com)
;
; Memory heap routines
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;

.include "error.inc"
.include "runtime.inc"

.export heapAlloc, heapFree, heapInit

.import runtimeError, geInt16, ltInt16, popax

; The memory heap starts at the end of program code going to the top of the
; runtime stack (the runtime stack grows downward). Assuming a 2K stack
; size, the heap would go from the end of program code to $C800 on a
; C64 and $B800 on a MEGA65.

; Memory Allocation Table (MAT)
; Each entry in the MAT is four bytes.
;    The first two bytes are the length of the allocation for this entry.
;    The second two bytes are the pointer to the memory for the entry.
;    The high bit of the second size byte is 0 if the block is currently unallocated.
; The MAT is at the high end of the heap and grows downward until the heap is full.
; The end of the MAT is signaled by $00000000.

heapPtr: .res 2
heapTop: .res 2
heapBottom: .res 2

; This routine initializes the heap MAT.  The caller passes the pointer to the
; top and bottom of the heap.  The bottom is passed in A/X and the top is
; passed in ptr1.
.proc heapInit
    sta heapBottom
    stx heapBottom + 1
    lda ptr1
    sta heapTop
    sta heapPtr
    lda ptr1 + 1
    sta heapTop + 1
    sta heapPtr + 1
    lda #0
    ldy #3
L1:
    sta (ptr1),y
    dey
    bpl L1
    rts
.endproc

; Size to allocate in A/X
; If allocation fails, a runtime error is triggered.
; Pointer to memory returned in A/X
;    tmp1/tmp2 - requested buffer size
;    ptr1 - current location in MAT
;    ptr2 - location in MAT of smallest available block
;           that satisfies requested buffer size.
;    ptr3 - location in MAT of last allocated block.
;           This is used when a new block is to be added
;           to the end of heap.
;
; Note: intOp1 and intOp2 are destroyed.
.proc heapAlloc
    ; Algorithm:
    ;    Store A/X in tmp1+tmp2
    ;    Start with ptr1 pointing to $cffc and $0000 in ptr2
    ;    Loop through entire MAT and update ptr2 when a smaller
    ;       available block is found.
    ;    If ptr2 is still $0000 then allocate a new block and
    ;       add it to the end of the MAT.
    ;    If ptr2 contains a block, mark it as allocated and
    ;       return the memory address in A/X.

    ; Initialization
    sta tmp1
    stx tmp2
    lda heapTop
    sta ptr1
    lda heapTop + 1
    sta ptr1 + 1
    lda #0
    sta ptr2
    sta ptr2 + 1
    sta ptr3
    sta ptr3 + 1

    ; Loop through entire MAT looking for the smallest available
    ; block that can satisfy the requested allocation size.
L1:
    ldy #3
L2:
    ; Look for $00000000 in current MAT entry
    lda (ptr1),y
    bne L4              ; This entry is not empty
    dey
    bpl L2
    ; End of MAT reached
    ; If ptr3 is zero, this is the first heap entry
    lda ptr3
    ora ptr3 + 1
    bne L3
    ; First entry in heap
    beq NewEntry
L3:
    ; Reached the end of the MAT. Check if ptr2 is non-zero.
    ; It points to the smallest available MAT entry.
    lda ptr2
    ora ptr2 + 1
    bne L31
    ; ptr2 is zero which means there are no available blocks
    ; in the MAT that can hold the requested allocation.
    ; jsr incMATPtr
    beq NewEntry
L31:
    ; ptr2 is non-zero which means it points to the MAT entry
    ; for the smallest block that can hold the requested allocation.
    clc
    bcc ReUseEntry
L4:
    ldy #1
    lda (ptr1),y        ; Look at second byte of size of allocation
    and #$80            ; Isolate the high bit
    bne L5              ; If set, this block is allocated.  Move on.
    ; Block is available, but is it big enough?
    lda (ptr1),y
    sta intOp1 + 1      ; Store current block's size in intOp1
    dey
    lda (ptr1),y
    sta intOp1
    lda tmp1
    sta intOp2          ; Store desired block size in intOp2
    lda tmp2
    sta intOp2 + 1
    jsr geInt16         ; Is current block size > desired block size
    beq L5              ; Is it not.
    ; The block is big enough, but is it larger than
    ; previous blocks that were big enough?
    ; intOp1 still contains the current block's size.
    lda ptr2            ; Is ptr2 zero?
    ora ptr2 + 1
    bne L41
    ; Ptr2 is zero, which means the current block is the
    ; first one that has been big enough.
    lda ptr1            ; Save the current MAT address
    sta ptr2            ; in ptr2 for future reference
    lda ptr1 + 1
    sta ptr2 + 1
    clc
    bcc L5              ; Move on to the next MAT entry.
L41:
    ; Ptr2 contains a previously-seen block that was
    ; big enough.  Compare the current block's size
    ; to the block pointed to by ptr2.
    ; intOp1 still contains the current block's size.
    ldy #0
    lda (ptr2),y
    sta intOp2
    iny
    lda (ptr2),y
    sta intOp2 + 1
    jsr ltInt16         ; Is current size < last seen size
    beq L5              ; It is not.  Ignore this block.
    ; The current block is smaller than previously-examined
    ; blocks.  Remember this block as the new smallest one.
    lda ptr1
    sta ptr2
    lda ptr1 + 1
    sta ptr2 + 1
L5:
    ldy #2
    lda ptr1
    sta ptr3
    iny
    lda ptr1 + 1
    sta ptr3 + 1
    jsr incMATPtr       ; Move to the next block in the MAT
    clc
    bcc L1
L99:
    lda tmp1
    ldx tmp2
    rts
ReUseEntry:
    ldy #1              ; Second byte in MAT entry
    lda (ptr2),y        ; Load it
    ora #$80            ; Set the high bit
    sta (ptr2),y        ; Save it back
    ldy #2              ; Third byte in MAT entry
    lda (ptr2),y        ; Load low byte of address block
    sta tmp1            ; Store it in tmp1
    iny                 ; Fourth byte in MAT entry
    lda (ptr2),y        ; Load high byte of address block
    sta tmp2            ; Store it in tmp2
    clc
    bcc L99             ; Done
NewEntry:               ; Add a new entry to the MAT
    ldy #0
    lda tmp1            ; Load the requested buffer size
    sta (ptr1),y        ; Store it in the first two bytes
    iny                 ; of the MAT entry.
    lda tmp2            ; Load the high byte of the buffer size
    ora #$80            ; Set the "allocated" bit
    sta (ptr1),y
    iny
    lda ptr3            ; Check if ptr3 is non-zero.
    ora ptr3 + 1        ; If so, use it to calculate the address of the next heap block
    bne L6
    lda heapBottom    ; Store the memory pointer
    sta (ptr1),y        ; in the next two bytes of the MAT entry.
    sta tmp1            ; Also store the pointer in tmp1/tmp2.
    iny
    lda heapBottom + 1
    sta (ptr1),y
    sta tmp2
    clc
    bcc L7
L6:
    ; Add the last block's pointer and its size
    ldy #2
    lda (ptr3),y        ; low byte of address
    sta tmp1
    iny
    lda (ptr3),y        ; high byte of address
    sta tmp2
    ldy #0
    lda (ptr3),y        ; low byte of size
    clc
    adc tmp1
    sta tmp1
    iny
    lda (ptr3),y        ; high byte of size
    and #$7f
    adc tmp2
    sta tmp2
    ldy #2
    lda tmp1
    sta (ptr1),y
    iny
    lda tmp2
    sta (ptr1),y
L7:
    jsr incMATPtr       ; Move to the next entry in the MAT
    lda #0              ; Store zeros in all four bytes
    ldy #3
L98:
    sta (ptr1),y
    dey
    bmi L99
    bpl L98
.endproc

.proc incMATPtr
    lda ptr1
    sec
    sbc #4
    sta ptr1
    bcc L1
    rts
L1:
    dec ptr1 + 1
    rts
.endproc

; Free a block of memory from the heap.
; A/X contains the pointer to the memory block.
.proc heapFree
    ; Algorithm:
    ;    Walk through the MAT, looking for the caller's memory block.
    ;    When found, clear the high bit of the second byte.
    ;
    ; ptr1 - the current MAT entry
    ; ptr2 - the memory block to free

    ; Initialization
    sta ptr2
    stx ptr2 + 1
    lda heapTop
    sta ptr1
    lda heapTop + 1
    sta ptr1 + 1
L1:
    ldy #3              ; Is the current MAT entry $00000000?
L11:
    lda (ptr1),y
    bne L2              ; This byte is non-zero
    dey
    bmi L4              ; All four bytes were zero. No more MAT entries.
    bpl L11
L2:
    ldy #2              ; Compare this entry's address to ptr2
    lda (ptr1),y
    cmp ptr2
    bne L21
    iny
    lda (ptr1),y
    cmp ptr2 + 1
    bne L21             ; The address matches
    beq L3
L21:
    jsr incMATPtr       ; Move to the next MAT entry
    clc
    bcc L1
L3:
    ; Found it.
    ldy #1
    lda (ptr1),y
    and #$7f
    sta (ptr1),y
L4:
    clc
    bcc trimFreeBlocks
.endproc

; This routine trims free blocks from the end of the MAT.
; It starts by going to the last entry in the MAT and writing
; zeros to each free entry until it reaches an allocated entry
; or the start of the MAT.
;
; This is called after each free to help reduce fragmentation.
.proc trimFreeBlocks
    ; Initialization
    lda heapTop
    sta ptr1
    lda heapTop + 1
    sta ptr1 + 1
    ; Find the last entry in the MAT
L1:
    ldy #3
L2:
    lda (ptr1),y
    bne L3
    dey
    bpl L2
    bmi L4
L3:
    ; This entry is used.
    ; Go to the next one.
    lda ptr1
    sec
    sbc #4
    sta ptr1
    lda ptr1 + 1
    sbc #0
    sta ptr1 + 1
    jmp L1
L4:
    ; Found the last entry.  Work backwards setting entries to zero until
    ; (1) We're at the first entry.
    ;   -or-
    ; (2) We reach an allocated entry.
    lda ptr1
    cmp heapTop
    bne L5
    lda ptr1 + 1
    cmp heapTop + 1
    beq L9              ; Branch if this is the first MAT entry
L5:
    ; Is the entry allocated
    ldy #1
    lda (ptr1),y
    and #$80
    bne L9              ; Branch if the entry is allocated
    ; Zero out this entry
    ldy #3
    lda #0
L6:
    sta (ptr1),y
    dey
    bpl L6
    ; Go to the next entry
    lda ptr1
    clc
    adc #4
    sta ptr1
    lda ptr1 + 1
    adc #0
    sta ptr1 + 1
    jmp L4
L9:
    rts
.endproc
