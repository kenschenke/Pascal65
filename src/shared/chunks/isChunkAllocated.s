.export _isChunkAllocated

.import _isBlockAllocated, isChunkAlloc, _retrieveBlock, _storeBlock, extractBlockAndChunkNum
.import _blockData, _currentBlock

.bss

blockNum: .res 2
chunkNum: .res 1

.code

; char isChunkAllocated(CHUNKNUM chunkNum)
.proc _isChunkAllocated
    jsr extractBlockAndChunkNum
    sta blockNum
    stx blockNum + 1
    dey
    sty chunkNum

    jsr _isBlockAllocated
    cmp #0
    beq No

    lda _blockData
    ora _blockData + 1
    beq GetBlock

    lda blockNum
    cmp _currentBlock
    bne StoreBlock
    lda blockNum + 1
    cmp _currentBlock + 1
    beq CheckChunk

StoreBlock:
    lda blockNum
    ldx blockNum + 1
    jsr _storeBlock
    lda #0
    sta _currentBlock
    sta _currentBlock + 1
    sta _blockData
    sta _blockData + 1

GetBlock:
    lda blockNum
    ldx blockNum + 1
    jsr _retrieveBlock
    sta _blockData
    stx _blockData + 1
    ora _blockData + 1
    beq No
    lda blockNum
    sta _currentBlock
    lda blockNum + 1
    sta _currentBlock + 1

CheckChunk:
    lda chunkNum
    jsr isChunkAlloc
    ldx #0
    rts

No:
    lda #0
    ldx #0
    rts

.endproc
