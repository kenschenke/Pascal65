;;;
 ; getAvailChunks.s
 ; Ken Schenke (kenschenke@gmail.com)
 ; 
 ; _getAvailChunks
 ; 
 ; Copyright (c) 2022
 ; Use of this source code is governed by an MIT-style
 ; license that can be found in the LICENSE file or at
 ; https://opensource.org/licenses/MIT
;;;

.include "blocks.inc"
.include "chunks.inc"

.export _getAvailChunks
.import _currentBlock, _storeBlock, _FullBlocks, _isBlockAllocated, __chunkGetBlock, _blockData
.importzp ptr1

avail:
    .byte 0, 0
blockNum:
    .byte 0

; int getAvailChunks(void)
.proc _getAvailChunks

    lda #0
    sta avail
    sta avail+1

    ; Do we have a current block?
    lda _currentBlock
    beq CheckBlocks              ; no - get on with it
    ; Store the block before we start.
    jsr _storeBlock
    cmp #0
    beq Done
    lda #0
    sta _currentBlock

CheckBlocks:
    lda #0
    sta blockNum
@LoopBlocks:
    ldy blockNum
    cpy #TOTAL_BLOCKS
    beq Done
    ; If the block is full there is no need to check it
    lda _FullBlocks,y
    bne @IncBlockLoop
    ; If the block has not been allocated yet,
    ; all chunks are available.
    iny
    tya
    jsr _isBlockAllocated
    cmp #0
    beq @AddEmptyBlock
    ; Retrieve the block
    ldy blockNum
    iny
    tya
    jsr __chunkGetBlock
    beq @FailGetBlock
    jsr AddBlockChunks
    jmp @IncBlockLoop

@FailGetBlock:
    lda #0
    sta avail
    sta avail+1
    jmp Done

@AddEmptyBlock:
    lda avail
    clc
    adc #CHUNKS_PER_BLOCK
    sta avail
    lda avail+1
    adc #0
    sta avail+1
    ; Fall through to @IncBlockLoop

@IncBlockLoop:
    inc blockNum
    jmp @LoopBlocks

Done:
    lda avail
    ldx avail+1
    rts

.endproc

AddBlockChunks:
    lda _blockData
    sta ptr1
    lda _blockData+1
    sta ptr1+1
    ldy #0
    ldx #CHUNKS_PER_BLOCK
@Loop:
    lda (ptr1),y
    bne @Inc
    lda avail
    clc
    adc #1
    sta avail
    lda avail+1
    adc #0
    sta avail+1
@Inc:
    iny
    dex
    bne @Loop
    rts
