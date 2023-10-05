;;;
 ; freeChunk.s
 ; Ken Schenke (kenschenke@gmail.com)
 ; 
 ; _freeChunk
 ; 
 ; Copyright (c) 2022
 ; Use of this source code is governed by an MIT-style
 ; license that can be found in the LICENSE file or at
 ; https://opensource.org/licenses/MIT
;;;

.include "blocks.inc"
.include "chunks.inc"

.export _freeChunk

.import _currentBlock, _storeBlock, _blockData, _FullBlocks, _freeBlock, _retrieveBlock
.import __chunkGetBlock, clearChunkAlloc, clearBlockFull, isChunkAlloc, extractBlockAndChunkNum
.import incAvailChunks
.importzp ptr1

.bss

blockNum: .res 2
chunkNum: .res 1

.code

; void freeChunk(CHUNKNUM chunkNum)
.proc _freeChunk
    jsr extractBlockAndChunkNum
    sta blockNum
    stx blockNum + 1
    dey
    sty chunkNum

    ; Do we have a current block?
    lda _blockData
    ora _blockData + 1
    beq GetBlock            ; no

    ; Is the chunk in a different block?
    lda _currentBlock
    cmp blockNum
    bne @StoreCurrentBlock  ; yes
    lda _currentBlock + 1
    cmp blockNum + 1
    beq IsChunkAlreadyFreed ; no

@StoreCurrentBlock:
    ; Store the current block
    lda _currentBlock
    ldx _currentBlock + 1
    jsr _storeBlock
    cmp #0
    beq Failure
    lda #0
    sta _currentBlock
    sta _currentBlock + 1
    sta _blockData
    sta _blockData + 1

GetBlock:
    ; Retrieve the block we need
    lda blockNum
    ldx blockNum + 1
    jsr __chunkGetBlock
    cmp #0
    bne IsChunkAlreadyFreed
    jmp Failure             ; retrieveBlock returned NULL

JmpDone:
    jmp Done

IsChunkAlreadyFreed:
    ; Check if this chunk is already freed
    lda chunkNum
    jsr isChunkAlloc
    cmp #0                  ; Is is free?
    beq Failure             ; Yes. Nothing to do.

    ; Set the chunk to show free in the chunk allocation table
    ; at the beginning of the block
    lda chunkNum
    jsr clearChunkAlloc
    ; The block is no longer full either
    lda blockNum
    ldx blockNum + 1
    jsr clearBlockFull

    ; Check if all other chunks in this block are also freed
    lda #0
    sta chunkNum
Loop:
    jsr isChunkAlloc
    cmp #0
    bne Done
    inc chunkNum
    lda chunkNum
    cmp #CHUNKS_PER_BLOCK
    bne Loop

    ; All chunks in this block are freed.
    ; The block can be freed as well.
    lda blockNum
    ldx blockNum + 1
    jsr _freeBlock
    lda #0
    sta _currentBlock
    sta _currentBlock + 1
    sta _blockData
    sta _blockData + 1
    jmp Done

Failure:
    lda #0
    sta _currentBlock
    sta _currentBlock + 1
    sta _blockData
    sta _blockData + 1
    rts

Done:
    jmp incAvailChunks

.endproc
