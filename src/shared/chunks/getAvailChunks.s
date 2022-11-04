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
.import _getTotalBlocks, isBlockFull, isChunkAlloc, _availChunks
.importzp ptr1

.bss

avail: .res 2
blockNum: .res 2
chunkNum: .res 1
totalBlocks: .res 2

.code

; int getAvailChunks(void)
.proc _getAvailChunks

    lda _availChunks
    ldx _availChunks + 1
    rts

    lda #0
    sta avail
    sta avail + 1

    ; Do we have a current block?
    lda _blockData
    ora _blockData + 1
    beq CheckBlocks              ; no - get on with it
    ; Store the block before we start.
    lda _currentBlock
    ldx _currentBlock + 1
    jsr _storeBlock
    cmp #0
    beq @D1
    lda #0
    sta _currentBlock
    sta _currentBlock + 1
    jmp CheckBlocks

@D1:
    jmp Done

CheckBlocks:
    jsr _getTotalBlocks
    sta totalBlocks
    stx totalBlocks + 1
    lda #0
    sta blockNum
    sta blockNum + 1
@LoopBlocks:
    lda blockNum
    cmp totalBlocks
    bne @IsBlockFull
    lda blockNum + 1
    cmp totalBlocks + 1
    beq Done
@IsBlockFull:
    ; If the block is full there is no need to check it
    lda blockNum
    ldx blockNum + 1
    jsr isBlockFull
    cmp #0
    bne @IncBlockLoop
    ; If the block has not been allocated yet,
    ; all chunks are available.
    lda blockNum
    ldx blockNum + 1
    jsr _isBlockAllocated
    cmp #0
    beq @AddEmptyBlock
    ; Retrieve the block
    lda blockNum
    ldx blockNum + 1
    jsr __chunkGetBlock
    cmp #0
    beq @FailGetBlock
    jsr AddBlockChunks
    jmp @IncBlockLoop

@FailGetBlock:
    lda #0
    sta avail
    sta avail + 1
    jmp Done

@AddEmptyBlock:
    clc
    lda avail
    adc #CHUNKS_PER_BLOCK
    sta avail
    lda avail + 1
    adc #0
    sta avail + 1
    ; Fall through to @IncBlockLoop

@IncBlockLoop:
    clc
    lda blockNum
    adc #1
    sta blockNum
    lda blockNum + 1
    adc #0
    sta blockNum + 1
    jmp @LoopBlocks

Done:
    lda avail
    ldx avail + 1
    rts

.endproc

AddBlockChunks:
    lda _blockData
    sta ptr1
    lda _blockData + 1
    sta ptr1 + 1
    lda #0
    sta chunkNum
@Loop:
    jsr isChunkAlloc
    cmp #0
    bne @Inc
    clc
    lda avail
    adc #1
    sta avail
    lda avail + 1
    adc #0
    sta avail + 1
@Inc:
    inc chunkNum
    lda chunkNum
    cmp #CHUNKS_PER_BLOCK
    bne @Loop
    rts
