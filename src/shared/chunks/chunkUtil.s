.import _blockData, _availChunks, _retrieveBlock
.importzp ptr1, ptr2, tmp1, tmp2

.export extractBlockAndChunkNum, isBlockFull, isCurrentBlockFull
.export clearChunkAlloc, isChunkAlloc, setChunkAlloc, packBlockAndChunkNum
.export incAvailChunks, decAvailChunks

.bss

blockNum: .res 2
chunkNum: .res 1
remBlock: .res 1

.rodata

allocReadMasks:
    .byte %00000001
    .byte %00000010
    .byte %00000100
    .byte %00001000
    .byte %00010000
    .byte %00100000
    .byte %01000000
    .byte %10000000

allocClearMasks:
    .byte %11111110
    .byte %11111101
    .byte %11111011
    .byte %11110111
    .byte %11101111
    .byte %11011111
    .byte %10111111
    .byte %01111111

.code

; This routine separates out the block number from the chunk number.
; The input is an unsigned 16-bit number in .A (LB) and .X (HB).
; The lower nibble of the LB is the 1-based chunk number.
; The upper nibble of the LB and both nibbles of the HB are the
; zero-based 12-bit block number.
;
; This routine is used internally by isBlockFull
; to access the block number.  It is also available to callers from other routines to
; access the block number and chunk number.
;
; Returns:
;   LB blockNum in A
;   HB blockNum in X
;   chunkNum in Y
;   blockNum and chunkNum set.

.proc extractBlockAndChunkNum
    sta blockNum
    and #$0f
    sta chunkNum
    stx blockNum + 1

    ; Process:
    ;    1. Move the upper nibble to the lower nibble of the low byte
    ;    2. Move the lower nibble of the high byte to the upper nibble of the low byte.

    ldy #4
@L1:
    lsr blockNum + 1
    ror blockNum
    dey
    bne @L1

    ; Return the values
    
    lda blockNum
    ldx blockNum + 1
    ldy chunkNum

    rts
.endproc

; This routine packs the block number and chunk number into a
; 16-bitvalue.  The input is a 12-bit block number (zero-based)
; in .A (LB) and .X (HB).  The 1-based chunk number is passed
; in .Y.  The resulting 16-bit value is returned in
; .A (LB) and .X (HB).

; This routine is used internally by allocChunk.

.proc packBlockAndChunkNum
    sta blockNum
    stx blockNum + 1
    ; Zero out the upper nibble of chunkNum
    tya
    and #$0f
    sta chunkNum

    ; Process:
    ;    1. Move the lower nibble of the high byte to the upper nibble
    ;    2. Move the upper nibble of the low byte to the lower nibble of the high byte.
    ;    3. Move the lower nibble of the low byte to the upper nibble.
    ;    4. Move the chunkNum to the lower nibble of the low byte.

    ldy #4
@L1:
    asl blockNum
    rol blockNum + 1
    dey
    bne @L1

    ; Move the chunkNum to the lower nibble of the low byte.

    lda blockNum
    ora chunkNum

    ; Return the combined blockNum and chunkNum
    ; LB of blockNum already in A
    ldx blockNum + 1

    rts

.endproc

.proc incAvailChunks
    clc
    lda _availChunks
    adc #1
    sta _availChunks
    lda _availChunks + 1
    adc #0
    sta _availChunks + 1
    rts
.endproc

.proc decAvailChunks
    sec
    lda _availChunks
    sbc #1
    sta _availChunks
    lda _availChunks + 1
    sbc #0
    sta _availChunks + 1
    rts
.endproc

; This routine gets the block allocation index used to 
; determine whether or not a block is allocated or full.
;
; Inputs:
;   blockNum in A (LB) and X (HB).
; Outputs:
;   None. blockNum converted to index in _AllocatedBlocks and remBlock set.

.proc getBlockAllocIndex
    sta blockNum
    stx blockNum + 1
    and #7
    sta remBlock

    ; Divide the blockNum by 8
    ldy #3
@Rot:
    clc
    ror blockNum + 1
    ror blockNum
    dey
    bne @Rot

    rts
.endproc

; This routine checks if a block is currently full.
; The 16-bit block number is passed in .A (LB) and .X (HB).
; Zero is returned in .A if not full, non-zero otherwise.
; The block number is zero-based.
isBlockFull:
    jsr _retrieveBlock
isBlockFull2:
    sta ptr1
    stx ptr1 + 1
    ldy #0
    lda (ptr1),y
    cmp #%11111111
    bne @L1
    iny
    lda (ptr1),y
    cmp #%00000111
    bne @L1

    lda #1
    ldx #0
    rts

@L1:
    lda #0
    ldx #0
    rts

; This routine checks if the current block is full.
; Zero is returned in .A if not full, non-zero otherwise.
.proc isCurrentBlockFull
    lda _blockData
    ldx _blockData + 1
    jmp isBlockFull2
.endproc

; This routine clears a chunk as allocated in the current block.
; The zero-based chunk number is passed in A.
; The current block is in _blockData.
.proc clearChunkAlloc
    sta tmp2        ; remainder
    cmp #8
    bpl @SubEight   ; chunk number > 7
    ; Chunk number is 7 or less
    lda #0
    sta tmp1
    jmp @ClearAlloc
@SubEight:
    ; Chunk number is 8 or more.
    sec
    sbc #8          ; subtract 8
    sta tmp2        ; what's left is the remainder
    lda #1          ; index is 1
    sta tmp1        ; store it in tmp1
@ClearAlloc:
    lda _blockData
    sta ptr1        ; ptr1 is _blockData
    lda _blockData + 1
    sta ptr1 + 1
    ; ptr2 is allocClearMasks
    lda #<allocClearMasks
    sta ptr2
    lda #>allocClearMasks
    sta ptr2 + 1
    ; Get the current allocation entry
    ldy tmp1
    lda (ptr1),y
    ; Clear the bit for this chunk
    ldy tmp2
    and (ptr2),y
    ; Store the current allocation entry
    ldy tmp1
    sta (ptr1),y

    rts
.endproc

; This routine checks if a chunk as allocated in the current block.
; The zero-based chunk number is passed in A.
; A non-zero value is returned in A if the chunk is allocated.
; The current block is in _blockData.
.proc isChunkAlloc
    sta tmp2        ; remainder
    cmp #8
    bpl @SubEight   ; chunk number > 7
    ; Chunk number is 7 or less
    lda #0
    sta tmp1
    jmp @IsAlloc
@SubEight:
    ; Chunk number is 8 or more.
    sec
    sbc #8          ; subtract 8
    sta tmp2        ; what's left is the remainder
    lda #1          ; index is 1
    sta tmp1        ; store it in tmp1
@IsAlloc:
    lda _blockData
    sta ptr1        ; ptr1 is _blockData
    lda _blockData + 1
    sta ptr1 + 1
    ; ptr2 is allocReadMasks
    lda #<allocReadMasks
    sta ptr2
    lda #>allocReadMasks
    sta ptr2 + 1
    ; Get the current allocation entry
    ldy tmp1
    lda (ptr1),y
    ; Clear other bits for this chunk
    ldy tmp2
    and (ptr2),y

    rts
.endproc

; This routine sets a chunk as allocated in the current block.
; The zero-based chunk number is passed in A.
; The current block is in _blockData.
.proc setChunkAlloc
    sta tmp2        ; remainder
    cmp #8
    bpl @SubEight   ; chunk number > 7
    ; Chunk number is 7 or less
    lda #0
    sta tmp1
    jmp @SetAlloc
@SubEight:
    ; Chunk number is 8 or more.
    sec
    sbc #8          ; subtract 8
    sta tmp2        ; what's left is the remainder
    lda #1          ; index is 1
    sta tmp1        ; store it in tmp1
@SetAlloc:
    lda _blockData
    sta ptr1        ; ptr1 is _blockData
    lda _blockData + 1
    sta ptr1 + 1
    ; ptr2 is allocReadMasks
    lda #<allocReadMasks
    sta ptr2
    lda #>allocReadMasks
    sta ptr2 + 1
    ; Get the current allocation entry
    ldy tmp1
    lda (ptr1),y
    ; Set the bit for this chunk
    ldy tmp2
    ora (ptr2),y
    ; Store the current allocation entry
    ldy tmp1
    sta (ptr1),y

    rts
.endproc
