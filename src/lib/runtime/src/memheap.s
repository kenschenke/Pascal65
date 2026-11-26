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

.import runtimeError, geInt16, ltInt16

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

heapTop: .res 2         ; Pointer to the start of the MAT (the top of the heap)
heapBottom: .res 2      ; Pointer to the bottom of the heap where mem starts getting allocated

; This routine initializes the heap MAT.  The caller passes the pointer to the
; top and bottom of the heap.  The bottom is passed in A/X and the top is
; passed in ptr1.
.proc heapInit
    sta heapBottom
    stx heapBottom + 1
    lda ptr1
    sta heapTop
    lda ptr1 + 1
    sta heapTop + 1
    lda #0
    ldy #3
L1: sta (ptr1),y
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
;    ptr3 - location in MAT of the last entry, free or not.
;           This is used when a new block is to be added
;           to the end of heap.
;
; A request of $8000 bytes or more is out of memory.
;
; Note: intOp1 and intOp2 are destroyed.
;
; Special call:
;   If A/X are $FFFF then the top of the heap (start of MAT)
;   is returned instead of allocating memory.
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

    ; Look for special call. If $FFFF is passed in A and X,
    ; return the top of the memory heap (start of MAT).
    cmp #$ff
    bne :+
    cpx #$ff
    bne :+
    lda heapTop         ; Return the bottom of the heap in A/X.
    ldx heapTop+1
    rts

    ; A size's high bit is the allocated bit, so no block can be $8000
    ; bytes or more. (The sizes are compared as signed numbers, so such a
    ; request fit any free block.)
:   cpx #$80
    bcc :+
    jmp outOfMemory

    ; Initialization
:   sta tmp1
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
    jmp NewEntry
L3:
    ; Reached the end of the MAT. Check if ptr2 is non-zero.
    ; It points to the smallest available MAT entry.
    lda ptr2
    ora ptr2 + 1
    bne L31
    ; ptr2 is zero which means there are no available blocks
    ; in the MAT that can hold the requested allocation.
    ; jsr incMATPtr
    jmp NewEntry
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
    jsr splitEntry      ; Keep what the request doesn't need free
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
    jsr checkFreeSpace
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

; heapAlloc is reusing the free block whose MAT entry is at ptr2 for a
; request of tmp1/tmp2 bytes, and ptr1 is the MAT's end (its zero entry).
; If the block is larger, this routine makes its entry the request's size
; and puts a free entry for the rest right after it, moving the entries
; after it down. Without this a small request took a whole merged block,
; and a string reassigned in a loop (s := UpCase(s)) grew each time: its
; value parameter's copy and the string merged, and the new string took
; both. The MAT grows by an entry, so the split is skipped if that entry
; would reach the last block. Uses ptr3, intOp1 and intOp2.
.proc splitEntry
    ldy #0              ; intOp1 = the rest: the block's size - the request
    sec
    lda (ptr2),y
    sbc tmp1
    sta intOp1
    iny
    lda (ptr2),y
    sbc tmp2
    sta intOp1 + 1
    ora intOp1
    bne :+
    rts                 ; The block is the request's size
    ; intOp2 = the end of the last block + 4. The last entry is just
    ; before the MAT's end, and the new end will be 4 bytes lower.
:   clc
    lda ptr1
    adc #4
    sta ptr3
    lda ptr1 + 1
    adc #0
    sta ptr3 + 1
    ldy #1
    lda (ptr3),y        ; The size, without the allocated bit
    and #$7f
    sta intOp2 + 1
    dey
    lda (ptr3),y
    clc
    ldy #2
    adc (ptr3),y        ; Plus the address
    sta intOp2
    iny
    lda intOp2 + 1
    adc (ptr3),y
    sta intOp2 + 1
    lda intOp2
    clc
    adc #4
    sta intOp2
    bcc :+
    inc intOp2 + 1
:   lda ptr1 + 1        ; Is the MAT's end below that? Then no room.
    cmp intOp2 + 1
    bcc NO
    bne MV
    lda ptr1
    cmp intOp2
    bcc NO
    ; Move each entry after ptr2's, through the zero entry, down 4 bytes,
    ; starting with the zero entry. ptr3 + 4 is the entry to move.
MV: sec
    lda ptr1
    sbc #4
    sta ptr3
    lda ptr1 + 1
    sbc #0
    sta ptr3 + 1
L1: ldy #0
L2: iny
    iny
    iny
    iny
    lda (ptr3),y
    dey
    dey
    dey
    dey
    sta (ptr3),y
    iny
    cpy #4
    bne L2
    clc                 ; Was that the entry right after ptr2's?
    lda ptr3
    adc #8
    tax
    lda ptr3 + 1
    adc #0
    cmp ptr2 + 1
    bne :+
    cpx ptr2
    beq NE
:   clc
    lda ptr3
    adc #4
    sta ptr3
    bcc L1
    inc ptr3 + 1
    jmp L1
    ; The new entry, at ptr3 + 4: the rest, free, after the request
NE: ldy #4
    lda intOp1
    sta (ptr3),y
    iny
    lda intOp1 + 1
    sta (ptr3),y
    ldy #2
    clc
    lda (ptr2),y
    adc tmp1
    ldy #6
    sta (ptr3),y
    ldy #3
    lda (ptr2),y
    adc tmp2
    ldy #7
    sta (ptr3),y
    ldy #0              ; ptr2's block is now the request's size
    lda tmp1
    sta (ptr2),y
    iny
    lda tmp2
    sta (ptr2),y
NO: rts
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

; heapAlloc is adding a block of tmp1/tmp2 bytes after the last block: its
; MAT entry goes at ptr1 (the MAT's zero entry) and the new zero entry at
; ptr1 - 4, so the block must end at or below ptr1 - 4. The block starts
; where the last entry's block ends (ptr3), free or not, or at the heap's
; bottom if the MAT is empty. If the block doesn't fit, this ends with
; rteOutOfMemory. Uses intOp1.
;
; This once measured from the end of the last allocated block, but the
; last entry can be free, and the block was given memory in the MAT. It
; also added in 16 bits, so a large request near the top of memory
; wrapped around and fit.
.proc checkFreeSpace
    lda ptr3
    ora ptr3 + 1
    bne :+
    lda heapBottom          ; The MAT is empty
    sta intOp1
    lda heapBottom + 1
    sta intOp1 + 1
    jmp L1
:   ldy #0                  ; intOp1 = the end of the last entry's block
    lda (ptr3),y
    ldy #2
    clc
    adc (ptr3),y
    sta intOp1
    ldy #1
    lda (ptr3),y
    and #$7f
    ldy #3
    adc (ptr3),y
    sta intOp1 + 1
    ; intOp1 += the size + 4. Past $FFFF is out of memory.
L1: clc
    lda intOp1
    adc tmp1
    sta intOp1
    lda intOp1 + 1
    adc tmp2
    sta intOp1 + 1
    bcs outOfMemory
    lda intOp1
    adc #4
    sta intOp1
    bcc :+
    inc intOp1 + 1
    beq outOfMemory
    ; Out of memory if ptr1 < intOp1
:   lda ptr1 + 1
    cmp intOp1 + 1
    bcc outOfMemory
    bne :+
    lda ptr1
    cmp intOp1
    bcc outOfMemory
:   rts
.endproc

.proc outOfMemory
    lda #rteOutOfMemory
    jmp runtimeError
.endproc

; Free a block of memory from the heap.
; A/X contains the pointer to the memory block.
.proc heapFree
    ; Algorithm:
    ;    Walk through the MAT, looking for the caller's memory block.
    ;    When found, clear the high bit of the second byte and merge
    ;    the block with free blocks next to it (mergeFreeBlock).
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
    jsr mergeFreeBlock
L4:
    jmp trimFreeBlocks
.endproc

; The MAT's entries are in address order and their blocks are contiguous:
; a new block goes right after the last entry's, a reused block keeps its
; size and trimFreeBlocks only removes entries from the end. So a free
; block can absorb a free block next to it, and a growing string's old
; blocks become one that the next, larger request fits in. Without this a
; string built a character at a time leaves two holes for each character,
; each too small for the next, and runs out of memory.
;
; This routine merges the free block whose MAT entry is at ptr1 with the
; free block after it and the one before it. It uses only ptr1 and ptr2
; (heapFree's callers may keep values in the others).
.proc mergeFreeBlock
    ; ptr2 = the next entry (the MAT grows downward)
    lda ptr1
    sec
    sbc #4
    sta ptr2
    lda ptr1 + 1
    sbc #0
    sta ptr2 + 1
    jsr mergeEntries
    ; Is there an entry before this one?
    lda ptr1
    cmp heapTop
    bne :+
    lda ptr1 + 1
    cmp heapTop + 1
    beq DN              ; Branch if this is the first MAT entry
    ; ptr2 = this entry, ptr1 = the one before it
:   lda ptr1
    sta ptr2
    clc
    adc #4
    sta ptr1
    lda ptr1 + 1
    sta ptr2 + 1
    adc #0
    sta ptr1 + 1
    jmp mergeEntries
DN: rts
.endproc

; If the blocks of the MAT entries at ptr1 and ptr2 (the next entry) are
; both free, this routine adds ptr2's size to ptr1's and removes ptr2's
; entry, moving the entries after it up. A merged size must stay below
; $8000, since the size's high bit is the allocated bit.
.proc mergeEntries
    ldy #2              ; Is ptr2 the end of the MAT? No block is
    lda (ptr2),y        ; at address 0.
    iny
    ora (ptr2),y
    beq DN
    ldy #1
    lda (ptr1),y        ; Is ptr1's block allocated?
    bmi DN
    lda (ptr2),y        ; Is ptr2's block allocated?
    bmi DN
    ; Add the sizes
    dey
    clc
    lda (ptr1),y
    adc (ptr2),y
    pha                 ; The low byte
    iny
    lda (ptr1),y
    adc (ptr2),y        ; Both are below $8000, so there is no carry
    bmi TB              ; Branch if the sum is $8000 or more
    sta (ptr1),y
    dey
    pla
    sta (ptr1),y
    ; Remove ptr2's entry: copy each entry after it up one place,
    ; through the end of the MAT's zero entry.
L1: lda ptr2            ; ptr2 = the entry to copy
    sec
    sbc #4
    sta ptr2
    lda ptr2 + 1
    sbc #0
    sta ptr2 + 1
    ldy #0
L2: lda (ptr2),y        ; Copy byte Y to the entry above it
    iny
    iny
    iny
    iny
    sta (ptr2),y
    dey
    dey
    dey
    cpy #4
    bne L2
    ldy #6              ; Was that the end of the MAT? (its address,
    lda (ptr2),y        ; copied to bytes 6 and 7, is zero)
    iny
    ora (ptr2),y
    bne L1
DN: rts
TB: pla
    rts
.endproc

; This routine trims free blocks from the end of the MAT.
; It starts by going to the last entry in the MAT and writing
; zeros to each free entry until it reaches an allocated entry
; or the start of the MAT. The first entry is trimmed too if it is
; free, so a heap whose blocks are all free is empty. (It once kept a
; free first entry, and a new block larger than it went after it.)
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
    ; ptr1 is the zero entry. Work backwards setting the entries before it
    ; to zero until
    ; (1) The zero entry is the first entry.
    ;   -or-
    ; (2) We reach an allocated entry.
    lda ptr1
    cmp heapTop
    bne L5
    lda ptr1 + 1
    cmp heapTop + 1
    beq L9              ; Branch if the MAT is empty
L5:
    ; Go to the entry before
    lda ptr1
    clc
    adc #4
    sta ptr1
    lda ptr1 + 1
    adc #0
    sta ptr1 + 1
    ; Is the entry allocated
    ldy #1
    lda (ptr1),y
    bmi L9              ; Branch if the entry is allocated
    ; Zero out this entry
    ldy #3
    lda #0
L6:
    sta (ptr1),y
    dey
    bpl L6
    jmp L4
L9:
    rts
.endproc
