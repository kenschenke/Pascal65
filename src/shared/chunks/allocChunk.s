;;;
 ; allocChunk.s
 ; Ken Schenke (kenschenke@gmail.com)
 ; 
 ; _allocChunk
 ; 
 ; Copyright (c) 2022
 ; Use of this source code is governed by an MIT-style
 ; license that can be found in the LICENSE file or at
 ; https://opensource.org/licenses/MIT
;;;

.include "blocks.inc"
.include "chunks.inc"

.importzp ptr1
.import _allocBlock, _storeBlock, _isBlockAllocated, _retrieveBlock, _FullBlocks, _currentBlock, _blockData
.import __chunkGetBlock

.export _allocChunk

chunkNum:
    .byte 0, 0
idx:
    .byte 0

; char __fastcall__ allocChunk(CHUNKNUM *chunkNum)
.proc _allocChunk

    ; Save argument

    sta chunkNum
    stx chunkNum+1

    ; Do we have a current block allocated?

    lda _currentBlock
    bne @HasFreeChunk
    ; No we don't.  Allocate a new block
    jsr allocNewBlock
    beq @F1
    ldy #0
    jmp @FoundFreeChunk

@F1:
    jmp @Failure

    ; See if the current block has a free chunk

@HasFreeChunk:
    ldy _currentBlock
    dey
    lda _FullBlocks,y
    beq @FindFreeChunk      ; it has a free chunk

    ; Current block is full.  Store it and
    ; look at other blocks that might have free chunks.
    lda _currentBlock
    jsr _storeBlock
    cmp #0
    beq @F2
    lda #0
    sta _currentBlock
    jmp @LookForOtherBlocks

@F2:
    jmp @Failure
    
@LookForOtherBlocks:
    ; Look for other blocks that have free chunks
    lda #0
    sta idx
@L1:
    ldy idx
    cpy #TOTAL_BLOCKS
    beq @NoAvailBlocks      ; been through all the blocks
    iny
    tya
    jsr _isBlockAllocated   ; is the block allocated?
    cmp #0
    beq @IncL1              ; block is not allocated
    ldy idx
    lda _FullBlocks,y       ; is the block full?
    beq @NotFull            ; no, it's not full
@IncL1:
    inc idx
    jmp @L1

@NotFull:
    ; This currently-allocated block has at least one spare chunk.
    iny
    tya
    jsr __chunkGetBlock
    beq @Failure
    jmp @FindFreeChunk

@NoAvailBlocks:
    ; We looked through all the blocks and there were
    ; no allocated blocks with available chunks.
    jsr allocNewBlock
    beq @Failure
    ldy #0
    jmp @FoundFreeChunk

@FindFreeChunk:
    ; Loop through the chunk table at the beginning of
    ; the block looking for an available chunk.
    lda _blockData
    sta ptr1
    lda _blockData+1
    sta ptr1+1
    ldy #0
    ldx #CHUNKS_PER_BLOCK
@L2:
    lda (ptr1),y
    beq @FoundFreeChunk
    iny
    dex
    beq @Failure
    jmp @L2

@FoundFreeChunk:    ; Chunk num (zero-based) in .Y
    ; First, mark the chunk as allocated in the block's
    ; chunk table
    lda _blockData
    sta ptr1
    lda _blockData+1
    sta ptr1+1
    lda #1
    sta (ptr1),y
    ; Next, store the chunk number and block number
    ; in chunkNum for return to the caller.
    iny             ; The chunknum is returned as 1-based
    lda chunkNum
    sta ptr1
    lda chunkNum+1
    sta ptr1+1
    tya
    ldy #0          ; Chunk number in low byte
    sta (ptr1),y
    ldy #1
    lda _currentBlock
    sta (ptr1),y    ; Block number in high byte

    ; Need to look through the chunk allocation table at the
    ; beginning of the block and if all chunks are now allocated
    ; mark the block as full.

    lda _blockData
    sta ptr1
    lda _blockData+1
    sta ptr1+1
    ldx #CHUNKS_PER_BLOCK
    ldy #0
@L3:
    lda (ptr1),y
    beq @Done       ; This chunk isn't allocated yet
    iny
    dex
    bne @L3

    ; Block is now full

    ldy _currentBlock
    dey
    lda #1
    sta _FullBlocks,y

@Done:
    lda #1
    ldx #0
    rts

@Failure:
    lda #0
    sta _currentBlock
    rts

.endproc

; Allocate a new block by calling _allocBlock
; Return zero in .A on failure - non-zero on success
.proc allocNewBlock

    lda #<_currentBlock     ; Pass currentBlock address
    ldx #>_currentBlock     ; to _allocBlock
    jsr _allocBlock         ; allocate new block
    sta _blockData          ; store low byte of block address
    stx _blockData+1        ; store high byte of block address
    bne @IsBlockNumZero     ; high byte is non-zero
    lda _blockData          ; check low byte
    bne @IsBlockNumZero     ; low byte is non-zero
    lda #0                  ; _allocBlock retured NULL
    rts                     ; that's an error - we're done

@IsBlockNumZero:
    lda _currentBlock       ; check currentBlock number
    bne @ZeroOutUsedChunks  ; non-zero
    lda #0                  ; currentBlock is zero - that's an error
    rts

@ZeroOutUsedChunks:
    ldx #CHUNKS_PER_BLOCK
    lda _blockData
    sta ptr1
    lda _blockData+1
    sta ptr1+1
    lda #0
    ldy #0
@Loop:
    sta (ptr1),y
    iny
    dex
    bne @Loop

    ; Make sure the new block is not marked as full
    ldy _currentBlock
    dey
    lda #0
    sta _FullBlocks,y

    lda #1                  ; Success
    rts

.endproc
