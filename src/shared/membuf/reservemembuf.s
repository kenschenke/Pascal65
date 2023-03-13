
.include "membuf.inc"

.export _reserveMemBuf

.import loadMemBufDataCache, loadMemBufHeaderCache
.import _cachedMemBufData, _cachedMemBufHdr
.import _allocChunk, _retrieveChunk, _storeChunk
.import popax, pushax

.importzp ptr1

.bss

hdrChunkNum: .res 2
lastChunkNum: .res 2
currentChunkNum: .res 2
size: .res 2

.code

.proc isSizeLeCapacity
    ; Compare high bytes first.
    ; If high byte of size is > capacity then the answer is false.
    lda _cachedMemBufHdr + MEMBUF::capacity + 1
    cmp size + 1
    bcc L2
    ; If low byte of size <= capacity then answer is true
    lda _cachedMemBufHdr + MEMBUF::capacity
    cmp size
    bcs L1
    jmp L2
L1:
    lda #1
    rts

L2:
    lda #0
    rts
.endproc

.proc isCapacityGeSize
    ; Compare high bytes first.
    ; If high byte of size > capacity then the answer is false.
    lda _cachedMemBufHdr + MEMBUF::capacity + 1
    cmp size + 1
    bcc L1
    ; If low byte of size > capacity then answer is false
    lda _cachedMemBufHdr + MEMBUF::capacity
    cmp size
    bcc L1
    lda #1
    rts

L1:
    lda #0
    rts
.endproc

; hdrChunkNum : the header
; lastChunkNum : previous chunknum or 0 if no chunk yet
; currentChunkNum : the current chunknum

; void reserveMemBuf(CHUNKNUM header, unsigned size)
.proc _reserveMemBuf
    ; Store the second parameter
    sta size
    stx size + 1
    ; Store the first parameter
    jsr popax
    sta hdrChunkNum
    stx hdrChunkNum + 1

    ; Call loadMemBufHeaderCache
    lda hdrChunkNum
    ldx hdrChunkNum + 1
    jsr loadMemBufHeaderCache

    ; If size is <= current capacity, nothing to do.
    jsr isSizeLeCapacity
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
    jsr isCapacityGeSize
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
