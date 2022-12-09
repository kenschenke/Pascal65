
.include "membuf.inc"

.export _reserveMemBuf

.import loadMemBufDataCache, loadMemBufHeaderCache
.import _cachedMemBufData, _cachedMemBufHdr
.import _allocChunk, _retrieveChunk, _storeChunk
.import intOp1, intOp2, leUint16, geUint16
.import popax, pushax

.importzp ptr1

.bss

hdrChunkNum: .res 2
lastChunkNum: .res 2
currentChunkNum: .res 2
size: .res 2

.code

; hdrChunkNum : the header
; lastChunkNum : previous chunknum or 0 if no chunk yet
; currentChunkNum : the current chunknum

; void reserveMemBuf(CHUNKNUM header, unsigned size)
.proc _reserveMemBuf
    ; Store the second parameter
    sta size
    sta intOp1          ; for later
    stx size + 1
    stx intOp1 + 1      ; for later
    ; Store the first parameter
    jsr popax
    sta hdrChunkNum
    stx hdrChunkNum + 1

    ; Call loadMemBufHeaderCache
    lda hdrChunkNum
    ldx hdrChunkNum + 1
    jsr loadMemBufHeaderCache

    ; If size is less than the current capacity, nothing to do.
    lda _cachedMemBufHdr + MEMBUF::capacity
    sta intOp2
    lda _cachedMemBufHdr + MEMBUF::capacity + 1
    sta intOp2 + 1
    ; size is already in intOp1
    jsr leUint16
    bne L0          ; nothing to do

    ; Reset the buffer position and capacity (recalculated below)
    lda #0
    sta _cachedMemBufHdr + MEMBUF::posGlobal
    sta _cachedMemBufHdr + MEMBUF::posGlobal + 1
    sta _cachedMemBufHdr + MEMBUF::posChunk
    sta _cachedMemBufHdr + MEMBUF::posChunk + 1
    sta _cachedMemBufHdr + MEMBUF::capacity
    sta _cachedMemBufHdr + MEMBUF::capacity + 1

    ; Store the requested size in the "used" header field
    lda size
    sta _cachedMemBufHdr + MEMBUF::used
    lda size + 1
    sta _cachedMemBufHdr + MEMBUF::used + 1

    ; Copy the firstChunkNum to currentChunkNum
    lda _cachedMemBufHdr + MEMBUF::firstChunkNum
    sta currentChunkNum
    lda _cachedMemBufHdr + MEMBUF::firstChunkNum + 1
    sta currentChunkNum + 1

    ; Zero out lastChunkNum
    lda #0
    sta lastChunkNum
    sta lastChunkNum + 1
    jmp L1

L0:
    jmp L6

    ; Loop until the capacity is >= the requested size
L1:
    ; If capacity >= size, we have enough memory allocated
    lda _cachedMemBufHdr + MEMBUF::capacity
    sta intOp1
    lda _cachedMemBufHdr + MEMBUF::capacity + 1
    sta intOp1 + 1
    lda size
    sta intOp2
    lda size + 1
    sta intOp2 + 1
    jsr geUint16
    bne L0

L2:
    ; Is there a chunk allocated?
    lda currentChunkNum
    ora currentChunkNum + 1
    bne L5          ; yes

    ; Allocate a new chunk
    lda #<currentChunkNum
    ldx #>currentChunkNum
    jsr _allocChunk
    ; Set the new chunk to all zeros
    lda #<_cachedMemBufData
    sta ptr1
    lda #>_cachedMemBufData
    sta ptr1 + 1
    ldy #0
    lda #0
L3:
    sta (ptr1),y
    iny
    cpy #CHUNK_LEN
    bne L3
    ; Store the new chunk
    lda currentChunkNum
    ldx currentChunkNum + 1
    jsr pushax
    lda #<_cachedMemBufData
    ldx #>_cachedMemBufData
    jsr _storeChunk

    ; If lastChunkNum is 0, this is the first chunk
    lda lastChunkNum
    ora lastChunkNum + 1
    bne L4
    ; Set the new chunknum in the header
    lda currentChunkNum
    sta _cachedMemBufHdr + MEMBUF::firstChunkNum
    lda currentChunkNum + 1
    sta _cachedMemBufHdr + MEMBUF::firstChunkNum + 1
    jmp L5

L4:
    ; Set the new chunkNum as nextChunk in the current chunk
    lda lastChunkNum
    ldx lastChunkNum + 1
    jsr pushax
    lda #<_cachedMemBufData
    ldx #>_cachedMemBufData
    jsr _retrieveChunk
    lda currentChunkNum
    sta _cachedMemBufData + MEMBUF_CHUNK::nextChunk
    lda currentChunkNum + 1
    sta _cachedMemBufData + MEMBUF_CHUNK::nextChunk + 1
    lda lastChunkNum
    ldx lastChunkNum + 1
    jsr pushax
    lda #<_cachedMemBufData
    ldx #<_cachedMemBufData
    jsr _storeChunk

L5:
    ; Load the chunk
    lda currentChunkNum
    ldx currentChunkNum + 1
    jsr loadMemBufDataCache

    ; Add the size of the chunk
    clc
    lda _cachedMemBufHdr + MEMBUF::capacity
    adc #MEMBUF_CHUNK_LEN
    sta _cachedMemBufHdr + MEMBUF::capacity
    lda _cachedMemBufHdr + MEMBUF::capacity + 1
    adc #0
    sta _cachedMemBufHdr + MEMBUF::capacity + 1

    ; Go to the next chunk
    lda currentChunkNum
    sta lastChunkNum
    lda currentChunkNum + 1
    sta lastChunkNum + 1

    lda _cachedMemBufData
    sta currentChunkNum
    lda _cachedMemBufData + 1
    sta currentChunkNum + 1
    jmp L1

L6:
    rts

.endproc
