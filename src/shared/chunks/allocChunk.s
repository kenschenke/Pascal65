;;;
 ; allocChunk.s
 ; Ken Schenke (kenschenke@gmail.com)
 ; 
 ; _allocChunk
 ; 
 ; Copyright (c) 2024
 ; Use of this source code is governed by an MIT-style
 ; license that can be found in the LICENSE file or at
 ; https://opensource.org/licenses/MIT
;;;

.include "blocks.inc"
.include "chunks.inc"

.importzp ptr1
.import _allocBlock, _storeBlock, _isBlockAllocated, _retrieveBlock, _currentBlock, _blockData
.import __chunkGetBlock, isChunkAlloc, isBlockFull, _getTotalBlocks, setChunkAlloc, packBlockAndChunkNum
.import setBlockFull, clearChunkAlloc, clearBlockFull, packBlockAndChunkNum, decAvailChunks, _flushChunkBlock

.export _allocChunk

.bss

pChunkNum: .res 2
idx: .res 2
totalBlocks: .res 2

.code

; char __fastcall__ allocChunk(CHUNKNUM *chunkNum)
.proc _allocChunk

    ; Save argument

    sta pChunkNum
    stx pChunkNum + 1

    ; Do we have a current block allocated?

    lda _blockData
    ora _blockData + 1
    bne @HasFreeChunk
    ; No we don't.  Allocate a new block
    jsr allocNewBlock
    cmp #0
    beq @F1
    lda #0
    sta idx
    jmp @FoundFreeChunk

@F1:
    jmp @Failure

    ; See if the current block has a free chunk

@HasFreeChunk:
    lda _currentBlock
    ldx _currentBlock + 1
    jsr isBlockFull
    cmp #0
    beq @J3                 ; it has a free chunk

    ; Current block is full.  Store it and
    ; look at other blocks that might have free chunks.
    lda _currentBlock
    ldx _currentBlock + 1
    jsr _storeBlock
    cmp #0
    beq @F2                 ; Failed to store the block
    lda #0
    sta _blockData
    sta _blockData + 1
    jmp @LookForOtherBlocks

@F2:
    jmp @Failure

@J3:
    jmp @FindFreeChunk

@LookForOtherBlocks:
    ; Look for other blocks that have free chunks
    jsr _getTotalBlocks
    sta totalBlocks
    stx totalBlocks + 1
    ; Keep a counter of blocknum
    lda #0
    sta idx
    sta idx + 1
    ; Store the current block before continuing
    jsr _flushChunkBlock
@L1:
    lda idx
    ldx idx + 1
    jsr _isBlockAllocated       ; is the block allocated?
    cmp #0
    beq @IncL1                  ; it's not.  check the next block
    lda idx
    ldx idx + 1
    jsr isBlockFull             ; block is allocated.  is it full?
    cmp #0
    beq @NotFull                ; it's not.  we'll use this one.
@IncL1:
    ; Increment the block number
    clc
    lda idx
    adc #1
    sta idx
    lda idx + 1
    adc #0
    sta idx + 1
    ; Have we checked all the blocks?
    lda idx
    cmp totalBlocks
    bne @L1                     ; nope
    lda idx + 1
    cmp totalBlocks + 1
    beq @NoAvailBlocks          ; yes
    jmp @L1

@NotFull:
    ; This currently-allocated block has at least one spare chunk.
    ; block number in idx
    lda idx
    ldx idx + 1
    jsr __chunkGetBlock
    cmp #0
    beq @FailNotFull
    jmp @FindFreeChunk

@FailNotFull:
    jmp @Failure

@NoAvailBlocks:
    ; We looked through all the blocks and there were
    ; no allocated blocks with available chunks.
    jsr allocNewBlock
    cmp #0
    beq @Failure
    ldy #0
    jmp @FoundFreeChunk

@FindFreeChunk:
    ; Loop through the chunk table at the beginning of
    ; the block looking for an available chunk.
    lda #0
    sta idx
@L2:
    lda idx
    jsr isChunkAlloc
    cmp #0
    beq @FoundFreeChunk
    inc idx
    lda idx
    cmp #CHUNKS_PER_BLOCK
    beq @Failure
    jmp @L2

@FoundFreeChunk:    ; Chunk num (zero-based) in idx
    ; First, mark the chunk as allocated in the block's
    ; chunk table
    lda idx
    jsr setChunkAlloc

    ; Next, store the chunk number and block number
    ; in pChunkNum for return to the caller.
    lda pChunkNum
    sta ptr1
    lda pChunkNum + 1
    sta ptr1 + 1
    lda _currentBlock
    ldx _currentBlock + 1
    ldy idx
    iny             ; The chunknum is returned as 1-based
    jsr packBlockAndChunkNum
    ldy #0
    sta (ptr1),y
    iny
    txa
    sta (ptr1),y

    ; Need to look through the chunk allocation table at the
    ; beginning of the block and if all chunks are now allocated
    ; mark the block as full.

    ldy #CHUNKS_PER_BLOCK
    dey
    sty idx
@L3:
    lda idx
    jsr isChunkAlloc
    cmp #0
    beq @Done       ; This chunk isn't allocated yet
    dec idx
    bpl @L3

    ; Block is now full

    lda _currentBlock
    ldx _currentBlock + 1
    jsr setBlockFull

@Done:
    jsr decAvailChunks
    lda #1
    ldx #0
    rts

@Failure:
    lda #0
    sta _blockData
    sta _blockData + 1
    rts

.endproc

; Allocate a new block by calling _allocBlock
; Return zero in .A on failure - non-zero on success
.proc allocNewBlock

    lda #<_currentBlock     ; Pass currentBlock address
    ldx #>_currentBlock     ; to _allocBlock
    jsr _allocBlock         ; allocate new block
    sta _blockData          ; store low byte of block address
    stx _blockData + 1      ; store high byte of block address
    ora _blockData + 1      ; is _blockData NULL?
    bne @ZeroOutUsedChunks  ; it's non-NULL
    lda #0                  ; _allocBlock retured NULL
    rts                     ; that's an error - we're done

@ZeroOutUsedChunks:
    lda _blockData
    sta ptr1
    lda _blockData + 1
    sta ptr1 + 1
    lda #0
    ldy #0
    sta (ptr1),y
    iny
    sta (ptr1),y

    ; Make sure the new block is not marked as full
    lda _currentBlock
    ldx _currentBlock + 1
    jsr clearBlockFull

    lda #1                  ; Success
    rts

.endproc
