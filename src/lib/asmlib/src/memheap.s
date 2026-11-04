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

.export initMemHeap, heapAlloc, heapFree, getMemHeapForBank, clearMemHeap
.ifdef __DEBUG__
.export isHeapAllocated
.endif

.import ltUint32, geUint32, runtimeError, rtPushQ, rtPopQ, isQZero

.bss

lastBlock: .res 4
bankIndex: .res 1
allocSize: .res 2
splitMode: .res 1
triedDefrag: .res 1
runActive: .res 1
runSize: .res 2

.data

memBanks:
    .dword $12000, $1cffa   ; bank 1
    .dword $42000, $4fffa   ; bank 4
    .dword $50000, $5effa   ; bank 5
    .dword $0               ; terminator

.code

; Memory Allocation Table (MAT)
; Each entry in the MAT is two bytes: the length of the allocation for this
; entry. The high bit of the second byte is 0 if the block is currently
; unallocated.
; Blocks are contiguous, so an entry has no pointer. The address of a block is
; the bottom of the heap plus the lengths of all the entries before it.
; The MAT is at the end of the heap and grows downward until the heap is full.
; The end of the MAT is signaled by two $00 bytes.

; The MAT is scanned for a free block of exactly the requested size.
; If there is none then a new block of the requested size is allocated
; and added to the end of the MAT. Free blocks at the end of the MAT
; are released when a block is freed (see trimFreeBlocks).
;
; A free block larger than the request is not used. That would be a
; best fit, but doing so crashes the compiler (icodetest test 16).

; This routine initializes the memory banks.
.proc initMemHeap
    lda #0
    sta splitMode
    ; Initialize the MAT for each of the memory banks
    lda #<memBanks
    sta ptr1
    lda #>memBanks
    sta ptr1+1
    lda #0
    sta ptr1+2
    sta ptr1+3

    lda #0
    sta bankIndex
L1: lda bankIndex
    asl a
    asl a
    asl a
    taz
    clc
    adc #4
    pha
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    beq L2

    plz
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr2
    lda #0
    taz
:   nop
    sta (ptr2),z
    inz
    cpz #2
    bne :-

    inc bankIndex
    bra L1

L2: pla
    rts
.endproc

; This routine returns the top of the memory heap MAT for a given bank.
; The bank number is passed in A and the address of the MAT is returned in Q.
;
; Bank numbers start at 0.
;
; If a bank number is out of range, NULL is returned.
.proc getMemHeapForBank
    sta tmp1                ; caller's bank number in tmp1

    ; Start at bank index 0
    lda #0
    sta bankIndex

    ; Loop through the banks
L1: lda bankIndex
    asl a
    asl a
    asl a
    tax

    ; Copy the heap bottom into ptr1
    ldy #0
:   lda memBanks,x
    sta ptr1,y
    inx
    iny
    cpy #4
    bne :-

    ; Is this the last entry?
    phx                     ; Save the X register
    ldq ptr1
    jsr isQZero
    bne L2
    pla                     ; Discard the X register
    lda #0
    tax
    tay
    taz
    rts                     ; Return null

    ; Is this the bank the caller wants?
L2: plx                     ; Restore the X register
    lda tmp1
    cmp bankIndex
    bne L3                  ; Branch if not

    ; This is the bank the caller wants. ptr1 still holds the heap bottom.
    ; Set heapBottom and heapTop so a caller walking the MAT can work out the
    ; address of each block, then return the heap top.
    phx
    ldq ptr1
    stq heapBottom
    plx
    ldy #0
:   lda memBanks,x
    sta ptr1,y
    inx
    iny
    cpy #4
    bne :-
    ldq ptr1
    stq heapTop
    rts

    ; Move to the next bank
L3: inc bankIndex
    bra L1
.endproc

; This routine sets heapBottom and heapTop for the address
; passed in Q. It looks through the memBanks list to find
; the bank containing the address.
;
; The carry is clear on return if a bank was found. It is set if the
; address is above the top of the last bank.
.proc setHeapForAddress
    stq intOp1              ; Store the address in intOp1/intOp2

    lda #0
    sta bankIndex

    ; Loop through the banks
L1: lda bankIndex
    asl a
    asl a
    asl a                   ; Multiply by 8
    tax

    ; Is this the terminator? It has no heap top to compare against.
    lda memBanks,x
    ora memBanks+1,x
    ora memBanks+2,x
    ora memBanks+3,x
    bne :+
    sec                     ; Past the last bank
    rts

:   inx                     ; Move to the heap top
    inx
    inx
    inx
    ldy #0
:   lda memBanks,x
    sta intOp32,y
    inx
    iny
    cpy #4
    bne :-
    jsr ltUint32            ; Is address < heapTop?
    bne L2                  ; Branch if so

    inc bankIndex
    bra L1

L2: ldq intOp32
    stq heapTop

    lda bankIndex
    asl a
    asl a
    asl a
    tax
    ldy #0
:   lda memBanks,x
    sta heapBottom,y
    inx
    iny
    cpy #4
    bne :-

    clc
    rts
.endproc

; This routine clears the memory heap, leaving only the first entry.
; The first entry is the error messages.
.proc clearMemHeap
    lda #0
    sta splitMode
    ; Start at the first bank
    lda #0
    sta bankIndex

L1: lda bankIndex
    asl a
    asl a
    asl a                   ; multiply by 8
    tax

    ; Copy heap bottom for the current bank to ptr1
    ldy #0
    phx
:   lda memBanks,x
    sta ptr1,y
    inx
    iny
    cpy #4
    bne :-

    ; Is this the last bank?
    ldq ptr1
    jsr isQZero
    beq L3

    ; Copy heap top for the current bank to ptr1
    plx
    ldy #0
:   lda memBanks+4,x
    sta ptr1,y
    inx
    iny
    cpy #4
    bne :-

    ; Is this the first bank?
    lda bankIndex
    bne L2              ; Branch if not first bank
    ; First bank - skip first entry
    lda #2
    ldx #0
    ldy #0
    ldz #0
    stq intOp32
    ldq ptr1
    sec
    sbcq intOp32
    stq ptr1

    ; Clear the entry at ptr1
L2: lda #0
    taz
:   nop
    sta (ptr1),z
    inz
    cpz #2
    bne :-

    ; Next memory bank
    inc bankIndex
    bne L1

L3: pla
    rts
.endproc

; Size to allocate in A/X
; If allocation fails, a runtime error is triggered. A size of $8000 or
; more always fails. A size of zero allocates one byte.
; Pointer to memory returned in Q
;   ptr1 - current location in MAT
;   ptr2 - location in MAT of smallest availble block
;          that satisfies requested buffer size.
;   ptr3 - location in MAT of last allocated block.
;          This is used when a new block is to be added
;          at the end of the heap.
.proc heapAlloc
    sta allocSize
    stx allocSize+1

    ; A MAT entry holds a size of up to $7fff. The high bit is the
    ; "allocated" flag, so a larger request can never be satisfied.
    txa
    bpl :+
    lda #rteOutOfMemory
    jmp runtimeError

    ; A size of zero would make an entry of $00 $80, which is a spare
    ; entry. Allocate one byte instead so the block has an address of
    ; its own.
:   ora allocSize
    bne :+
    inc allocSize

:   lda #0
    sta triedDefrag

    ; Start at the first bank
    lda #0
    sta bankIndex

L1: lda bankIndex
    asl a
    asl a
    asl a                   ; multiply by 8
    tax

    ; Populate heapBottom
    ldy #0
:   lda memBanks,x
    sta heapBottom,y
    inx
    iny
    cpy #4
    bne :-

    ; Is heapBottom null?
    phx                     ; Save X
    ldq heapBottom
    jsr isQZero
    bne L2

    ; Out of memory. Try once to merge free blocks so they can be split.
    pla                     ; Discard the X register
    lda triedDefrag
    bne OOM
    inc triedDefrag
    jsr defragHeap
    lda #1
    sta splitMode
    lda #0
    sta bankIndex
    jmp L1
OOM:
    lda #rteOutOfMemory
    jsr runtimeError
    rts

    ; Populate heapTop
L2: plx                     ; Get X back off the stack
    ldy #0
:   lda memBanks,x
    sta heapTop,y
    inx
    iny
    cpy #4
    bne :-

    jsr heapAllocBank
    jsr isQZero
    bne L3

    ; heapAllocBank returned null.
    ; Move to the next bank and try again.
    inc bankIndex
    bra L1

L3: rts
.endproc

.proc heapAllocBank
    ; Algorithm:
    ;   Walk the MAT from the first entry. tmp1 holds the address of the
    ;   block the current entry describes, which is the heap bottom plus the
    ;   sizes of all the entries before it.
    ;   If a free entry has exactly the requested size, reuse it.
    ;   At the end of the MAT, add a new entry and a new block after the
    ;   last block.

    ldq heapTop
    stq ptr1
    ldq heapBottom
    stq tmp1

L1: jsr readEntry
    bne :+
    jmp NewEntry            ; Reached the end of the MAT
:   lda intOp1+1
    bmi L2                  ; Branch if allocated
    lda intOp1
    cmp allocSize
    bne NotExact
    lda intOp1+1
    cmp allocSize+1
    bne NotExact
    jmp Reuse

L2: jsr addSize
    jsr incMATPtr
    jmp L1

; The free block is not the exact size. After the heap has been defragmented a
; larger free block can be split if it is followed by a spare entry (see
; defragHeap) to hold the remainder.
NotExact:
    lda splitMode
    beq L2
    sec
    lda intOp1
    sbc allocSize
    sta intOp2
    lda intOp1+1
    sbc allocSize+1
    sta intOp2+1
    bcc L2                  ; Smaller than the request
    ; ptr2 = the next MAT entry
    sec
    lda ptr1
    sbc #2
    sta ptr2
    lda ptr1+1
    sbc #0
    sta ptr2+1
    lda ptr1+2
    sbc #0
    sta ptr2+2
    lda ptr1+3
    sbc #0
    sta ptr2+3
    ldz #0
    nop
    lda (ptr2),z
    bne L2
    inz
    nop
    lda (ptr2),z
    cmp #$80
    bne L2
    ; The next entry is a spare. It becomes the free remainder.
    ldz #0
    lda intOp2
    nop
    sta (ptr2),z
    inz
    lda intOp2+1
    nop
    sta (ptr2),z
    ; This entry becomes the allocated block.
    ldz #0
    lda allocSize
    nop
    sta (ptr1),z
    inz
    lda allocSize+1
    ora #$80
    nop
    sta (ptr1),z
    jmp ZeroStart


Reuse:

    ; Reuse this free block. Only an exact size is reused. Reusing a larger
    ; block (best fit) makes the compiler crash in icodetest test 16 for
    ; reasons not yet understood. Something depends on where blocks land.
    ora #$80
    ldz #1
    nop
    sta (ptr1),z

    ; Callers expect new memory to be zeroed, which is true of fresh heap
    ; but not of a block that has been used before. Clear it.
ZeroStart:
    ldq tmp1
    stq ptr4
    lda allocSize
    sta intOp1
    lda allocSize+1
    sta intOp1+1
ZeroLoop:
    lda intOp1
    ora intOp1+1
    beq ZeroDone
    lda #0
    ldz #0
    nop
    sta (ptr4),z
    inc ptr4
    bne :+
    inc ptr4+1
    bne :+
    inc ptr4+2
    bne :+
    inc ptr4+3
:   lda intOp1
    bne :+
    dec intOp1+1
:   dec intOp1
    bra ZeroLoop
ZeroDone:
    ldq tmp1
    rts

NewEntry:
    ; ptr1 is the terminating entry and tmp1 is the end of the last block.
    ; The new block ends at tmp1 + allocSize.
    lda allocSize
    sta intOp32
    lda allocSize+1
    sta intOp32+1
    lda #0
    sta intOp32+2
    sta intOp32+3
    clc
    ldq tmp1
    adcq intOp32
    stq intOp32

    ; The new block must end before the new terminating entry at ptr1 - 2.
    lda #2
    sta intOp1
    lda #0
    sta intOp1+1
    sta intOp2
    sta intOp2+1
    sec
    ldq ptr1
    sbcq intOp1
    stq intOp1
    jsr geUint32            ; Is the limit >= the end of the new block?
    bne :+
    ; Not enough space. Return null.
    lda #0
    tax
    tay
    taz
    rts

:   ldz #0
    lda allocSize
    nop
    sta (ptr1),z            ; Store the size in the new entry
    inz
    lda allocSize+1
    ora #$80                ; Set the "allocated" bit
    nop
    sta (ptr1),z

    ; Write the new terminating entry
    jsr incMATPtr
    lda #0
    ldz #0
    nop
    sta (ptr1),z
    inz
    nop
    sta (ptr1),z

    ; Fresh heap is not necessarily zero. The block may be where freed blocks
    ; were trimmed from the end of the MAT earlier, so clear it.
    jmp ZeroStart
.endproc

; Reads the MAT entry at ptr1 into intOp1. The size is in the low 15 bits
; and the "allocated" flag is bit 7 of intOp1+1. The Z flag is set if the
; entry is all zeros (the end of the MAT).
.proc readEntry
    ldz #0
    nop
    lda (ptr1),z
    sta intOp1
    inz
    nop
    lda (ptr1),z
    sta intOp1+1
    ora intOp1
    rts
.endproc

; Adds the size of the entry in intOp1 to the address in tmp1-tmp4
.proc addSize
    clc
    lda tmp1
    adc intOp1
    sta tmp1
    lda intOp1+1
    and #$7f
    adc tmp2
    sta tmp2
    lda tmp3
    adc #0
    sta tmp3
    lda tmp4
    adc #0
    sta tmp4
    rts
.endproc

; Moves ptr1 to the next MAT entry
.proc incMATPtr
    sec
    lda ptr1
    sbc #2
    sta ptr1
    lda ptr1+1
    sbc #0
    sta ptr1+1
    lda ptr1+2
    sbc #0
    sta ptr1+2
    lda ptr1+3
    sbc #0
    sta ptr1+3
    rts
.endproc

; Free a block of memory from the heap
; Q contains the pointer to the memory block
.proc heapFree
    ; Algorithm:
    ;   Walk through the MAT, adding up the sizes of the entries to find the
    ;   address of each block, looking for the caller's memory block.
    ;   When found, clear the high bit of the second byte.
    ;
    ;   ptr1 - the current MAT entry
    ;   ptr2 - the memory block to free
    ;   tmp1 - the address of the block the current entry describes

    ; Initialization
    jsr isQZero
    bne :+
    rts
:   stq ptr2            ; Save the memory block ptr in ptr2
.ifdef __DEBUG__
    ldq ptr2
    jsr rtPushQ
    ldq ptr2
    jsr isHeapAllocated
    bne :+
    jsr rtPopQ
    ldz #$22
    brk
:   jsr rtPopQ
    stq ptr2
.endif ; end of ifdef __DEBUG__
    ldq ptr2
    jsr setHeapForAddress
    bcc :+
    rts                 ; Above the last bank. Not a heap address.
:   ldq heapTop         ; Load the MAT pointer into ptr1
    stq ptr1
    ldq heapBottom
    stq tmp1
L1: jsr readEntry
    beq L4              ; End of the MAT. Not found.
    lda intOp1
    bne HF
    lda intOp1+1
    and #$7f
    beq L2              ; Spare entry (zero size). Skip it.
HF:
    ldx #0              ; Compare this block's address to ptr2
:   lda tmp1,x
    cmp ptr2,x
    bne L2
    inx
    cpx #4
    bne :-
    ; Found it.
    ldz #1
    nop
    lda (ptr1),z
    and #$7f
    nop
    sta (ptr1),z
    bra L4
L2: jsr addSize
    jsr incMATPtr       ; Move to the next MAT entry
    jmp L1
L4: ; Fall through to trimFreeBlocks
.endproc

; This routine trims free blocks from the end of the MAT.
; It starts by going to the last entry in the MAT and writing
; zeros to each free entry until it reaches an allocated entry
; or the start of the MAT.
;
; This is called after each free to help reduce fragmentation.
.proc trimFreeBlocks
    ; Find the terminating entry
    ldq heapTop
    stq ptr1
T1: jsr readEntry
    beq T2
    jsr incMATPtr
    bra T1

    ; ptr1 is the terminating entry. Is it also the first entry?
T2: lda ptr1
    cmp heapTop
    bne T3
    lda ptr1+1
    cmp heapTop+1
    bne T3
    lda ptr1+2
    cmp heapTop+2
    bne T3
    lda ptr1+3
    cmp heapTop+3
    bne T3
    rts                     ; The MAT is empty

    ; Look at the entry before the terminating one (two bytes higher)
T3: clc
    lda ptr1
    adc #2
    sta tmp1
    lda ptr1+1
    adc #0
    sta tmp2
    lda ptr1+2
    adc #0
    sta tmp3
    lda ptr1+3
    adc #0
    sta tmp4
    ldq tmp1
    stq ptr1
    jsr readEntry
    lda intOp1+1
    bpl TZ
    lda intOp1              ; Allocated, unless it is a spare entry
    bne T9
    lda intOp1+1
    cmp #$80
    bne T9
TZ:

    ; Free. Zero it so it becomes the new terminating entry.
    lda #0
    ldz #0
    nop
    sta (ptr1),z
    inz
    nop
    sta (ptr1),z
    jmp T2
T9: rts
.endproc

; This routine merges runs of adjacent free blocks. It is called when the heap
; is full. The first free entry in a run takes the total size and every other
; free entry in the run becomes a spare entry (size zero, allocated bit set).
; A spare entry never changes the address of the blocks after it. heapAllocBank
; uses the spare entries to hold the remainder when it splits a larger free
; block, and heapFree and trimFreeBlocks ignore them.
.proc defragHeap
    lda #0
    sta bankIndex

D1: lda bankIndex
    asl a
    asl a
    asl a
    tax
    ldy #0
:   lda memBanks,x
    sta heapBottom,y
    inx
    iny
    cpy #4
    bne :-
    ldq heapBottom
    jsr isQZero
    bne :+
    rts                     ; No more banks

    ; The terminating entry has no heap top, so only read it for a real bank
:   lda bankIndex
    asl a
    asl a
    asl a
    tax
    ldy #0
:   lda memBanks+4,x
    sta heapTop,y
    inx
    iny
    cpy #4
    bne :-
    ldq heapTop
    stq ptr1
    lda #0
    sta runActive

D3: jsr readEntry
    beq DEnd                ; End of the MAT
    lda intOp1+1
    bmi D5                  ; Allocated or spare
    lda runActive
    bne D4

    ; Start a new run at this entry
StartRun:
    lda #1
    sta runActive
    ldq ptr1
    stq ptr2
    lda intOp1
    sta runSize
    lda intOp1+1
    sta runSize+1
    bra Next

    ; Add this free entry to the run if the total still fits in 15 bits
D4: clc
    lda runSize
    adc intOp1
    tax
    lda runSize+1
    adc intOp1+1
    bmi Over
    sta runSize+1
    stx runSize
    ldz #0
    lda #0
    nop
    sta (ptr1),z
    inz
    lda #$80
    nop
    sta (ptr1),z
    bra Next
Over:
    jsr closeRun
    bra StartRun

    ; Allocated entries end a run. Spare entries do not.
D5: lda intOp1
    bne :+
    lda intOp1+1
    cmp #$80
    beq Next
:   jsr closeRun

Next:
    jsr incMATPtr
    bra D3

DEnd:
    jsr closeRun
    inc bankIndex
    jmp D1
.endproc

; Writes the size of the run being merged into its first entry (at ptr2).
.proc closeRun
    lda runActive
    beq :+
    ldz #0
    lda runSize
    nop
    sta (ptr2),z
    inz
    lda runSize+1
    nop
    sta (ptr2),z
    lda #0
    sta runActive
:   rts
.endproc


.ifdef __DEBUG__
; This routine checks the memory allocation table and determines if
; a block of memory is allocated or not.
; The address of the memory is passed in Q.
;
; On exit: The Z flag is set if the block is not allocated.
.proc isHeapAllocated
    jsr isQZero
    bne :+
    lda #0
    rts

    ; Pointer to block in ptr2
:   stq ptr2
    jsr setHeapForAddress
    bcc :+
    lda #0                  ; Above the last bank: not allocated
    rts

    ; Copy heapTop to ptr1
:
    ldq heapTop
    stq ptr1
    ldq heapBottom
    stq tmp1

L1: jsr readEntry
    bne :+
    rts                     ; Return if the end of MAT is reached (Z flag set)

    ; Compare the current block's address to the one the caller is looking for.
:   lda intOp1
    bne IH
    lda intOp1+1
    cmp #$80
    beq L3                  ; Spare entry. Skip it.
IH: ldx #0
:   lda tmp1,x
    cmp ptr2,x
    bne L3
    inx
    cpx #4
    bne :-

    ; Found the block. Is it allocated?
    lda intOp1+1
    and #$80
    rts

    ; Not a match - go to the next MAT entry
L3: jsr addSize
    jsr incMATPtr
    bra L1
.endproc
.endif ; end of ifdef __DEBUG__
