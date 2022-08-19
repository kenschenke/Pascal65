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

.import _isBlockAllocated, _currentBlock, _storeBlock, _blockData, _FullBlocks, _freeBlock, _retrieveBlock
.import __chunkGetBlock
.importzp ptr1

blockNum:
    .byte 0
chunkNum:
    .byte 0

; void freeChunk(CHUNKNUM chunkNum)
.proc _freeChunk
    sta chunkNum
    stx blockNum

    ; is chunkNum < 1 or > CHUNKS_PER_BLOCK
    cmp #1
    bmi Done
    cmp #CHUNKS_PER_BLOCK + 1
    bpl Done

    ; is blockNum < 1 or > TOTAL_BLOCKS 
    cpx #1
    bmi Done
    cpx #TOTAL_BLOCKS + 1
    bpl Done

    ; is blockNum allocated?
    lda blockNum
    jsr _isBlockAllocated
    cmp #0
    beq Done

    ; Do we have a current block?
    lda _currentBlock
    beq GetBlock            ; no

    ; Is the chunk in a different block?
    cmp blockNum
    beq FreeChunk           ; no

    ; Store the current block
    jsr _storeBlock
    cmp #0
    beq Failure
    lda #0
    sta _currentBlock

GetBlock:
    ; Retrieve the block we need
    lda blockNum
    jsr __chunkGetBlock
    bne FreeChunk
    jmp Failure             ; retrieveBlock returned NULL

FreeChunk:
    ; Set the chunk to show free in the chunk allocation table
    ; at the beginning of the block
    lda _blockData
    sta ptr1
    lda _blockData+1
    sta ptr1+1
    ldy chunkNum
    dey
    lda #0
    sta (ptr1),y
    ; The block is no longer full either
    ldy blockNum
    dey
    sta _FullBlocks,y

    ; Check if all other chunks in this block are also freed
    ldy #0
    ldx #CHUNKS_PER_BLOCK
Loop:
    lda (ptr1),y
    bne Done                ; There's another chunk still allocated
    iny
    dex
    bne Loop

    ; All chunks in this block are freed.
    ; The block can be freed as well.
    lda blockNum
    jsr _freeBlock
    lda #0
    sta _currentBlock
    jmp Done

Failure:
    lda #0
    sta _currentBlock

Done:
    rts

.endproc
