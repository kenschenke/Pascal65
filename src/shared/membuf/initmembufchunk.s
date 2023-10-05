;;;
 ; initMemBufChunk.s
 ; Ken Schenke (kenschenke@gmail.com)
 ; 
 ; Memory Buffer Storage and Retrieval
 ; 
 ; Copyright (c) 2022
 ; Use of this source code is governed by an MIT-style
 ; license that can be found in the LICENSE file or at
 ; https://opensource.org/licenses/MIT
;;;

.include "membuf.inc"

.export initMemBufChunk

.import _allocChunk, flushMemBufCache
.import loadMemBufDataCache, loadMemBufHeaderCache, _retrieveChunk, _storeChunk
.import _cachedMemBufData, _cachedMemBufHdr
.import pushax
.importzp ptr1

.bss

chunkNum: .res 2
hdrChunkNum: .res 2

.code

; void initMemBufChunk(CHUNKNUM hdrChunkNum)
.proc initMemBufChunk
    ; Store the parameter
    sta hdrChunkNum
    stx hdrChunkNum + 1

    jsr flushMemBufCache

    ; Call loadMemBufHeaderCache
    lda hdrChunkNum
    ldx hdrChunkNum + 1
    jsr loadMemBufHeaderCache

    ; Allocate a new chunk
    lda #<chunkNum
    ldx #>chunkNum
    jsr _allocChunk

    ; Is this the first chunk in the MEMBUF table?
    lda _cachedMemBufHdr + MEMBUF::firstChunkNum
    ora _cachedMemBufHdr + MEMBUF::firstChunkNum + 1
    bne @SetNextChunk
    ; First chunk in MEMBUF table
    lda chunkNum
    sta _cachedMemBufHdr + MEMBUF::firstChunkNum
    lda chunkNum + 1
    sta _cachedMemBufHdr + MEMBUF::firstChunkNum + 1
    jmp @SetupDataChunk

@SetNextChunk:
    ; Is cachedMemBufHdr currentChunkNum zero?
    lda _cachedMemBufHdr + MEMBUF::currentChunkNum
    ora _cachedMemBufHdr + MEMBUF::currentChunkNum + 1
    beq @SetupDataChunk ; It's zero - skip to setting up the new data chunk

    ; Set the previous chunk's nextChunk to point to this new node

    ; Retrieve the current chunk
    ; First parameter to retrieveChunk
    lda _cachedMemBufHdr + MEMBUF::currentChunkNum
    ldx _cachedMemBufHdr + MEMBUF::currentChunkNum + 1
    jsr pushax
    ; Second parameter
    lda #<_cachedMemBufData
    ldx #>_cachedMemBufData
    jsr _retrieveChunk

@SetChunkNum:
    ; Set the next chunk number
    lda chunkNum
    sta _cachedMemBufData + MEMBUF_CHUNK::nextChunk
    lda chunkNum + 1
    sta _cachedMemBufData + MEMBUF_CHUNK::nextChunk + 1

    ; Store the chunk
    ; First parameter
    lda _cachedMemBufHdr + MEMBUF::currentChunkNum
    ldx _cachedMemBufHdr + MEMBUF::currentChunkNum + 1
    jsr pushax
    ; Second parameter
    lda #<_cachedMemBufData
    ldx #>_cachedMemBufData
    jsr _storeChunk

@SetupDataChunk:
    ; Set the new data chunk to 0's
    ldy #.sizeof(MEMBUF_CHUNK) - 1
    lda #<_cachedMemBufData
    sta ptr1
    lda #>_cachedMemBufData
    sta ptr1 + 1
    lda #0
@Loop:
    sta (ptr1),y
    dey
    bpl @Loop

    ; Store the zero'd out chunk
    lda chunkNum
    ldx chunkNum + 1
    jsr pushax
    lda #<_cachedMemBufData
    ldx #>_cachedMemBufData
    jsr _storeChunk

    ; Set the header's currentChunkNum to the new chunkNum
    lda chunkNum
    sta _cachedMemBufHdr + MEMBUF::currentChunkNum
    lda chunkNum + 1
    sta _cachedMemBufHdr + MEMBUF::currentChunkNum + 1
    lda #0
    sta _cachedMemBufHdr + MEMBUF::posChunk
    sta _cachedMemBufHdr + MEMBUF::posChunk + 1

    ; Update the capacity in the header
    clc
    lda _cachedMemBufHdr + MEMBUF::capacity
    adc #MEMBUF_CHUNK_LEN
    sta _cachedMemBufHdr + MEMBUF::capacity
    lda _cachedMemBufHdr + MEMBUF::capacity + 1
    adc #0
    sta _cachedMemBufHdr + MEMBUF::capacity + 1

    ; Load the data cache with the new data chunk
    lda chunkNum
    ldx chunkNum + 1
    jmp loadMemBufDataCache

.endproc
