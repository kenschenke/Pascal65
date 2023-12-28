; This routine adds a newly-created chunk to the index

.include "membuf.inc"

.import _allocChunk, _retrieveChunk, _storeChunk, pushax, loadMemBufDataCache
.import _cachedMemBufHdr

.export addChunkToIndex

.bss

chunk: .res CHUNK_LEN
chunkNum: .res 2
newChunkNum: .res 2
thisChunkNum: .res 2

.code

.proc allocNewIndexChunk
    lda #<newChunkNum
    ldx #>newChunkNum
    jsr _allocChunk
    lda #0
    ldx #CHUNK_LEN - 1
:   sta chunk,x
    dex
    bpl :-

    ; Store the new chunkNum in the index
    lda chunkNum
    sta chunk + MEMBUF_CHUNK::data
    lda chunkNum + 1
    sta chunk + MEMBUF_CHUNK::data + 1

    ; Store the index chunk
    lda newChunkNum
    ldx newChunkNum + 1
    jsr pushax
    lda #<chunk
    ldx #>chunk
    jmp _storeChunk
.endproc

; New chunkNum in A/X
.proc addChunkToIndex
    sta chunkNum
    stx chunkNum + 1

    ; Is this the first index chunk?
    lda _cachedMemBufHdr + MEMBUF::firstIndexChunk
    ora _cachedMemBufHdr + MEMBUF::firstIndexChunk + 1
    bne L1              ; Branch if not the first index

    ; Allocate a new index chunk
    jsr allocNewIndexChunk

    ; Set the new index chunk as the first one
    lda newChunkNum
    sta _cachedMemBufHdr + MEMBUF::firstIndexChunk
    lda newChunkNum + 1
    sta _cachedMemBufHdr + MEMBUF::firstIndexChunk + 1

    jmp L6

    ; Look for the first index chunk with an empty slot
L1:
    lda _cachedMemBufHdr + MEMBUF::firstIndexChunk
    sta thisChunkNum
    lda _cachedMemBufHdr + MEMBUF::firstIndexChunk + 1
    sta thisChunkNum + 1

L2:
    ; Load the current index chunk
    lda thisChunkNum
    ldx thisChunkNum + 1
    jsr pushax
    lda #<chunk
    ldx #>chunk
    jsr _retrieveChunk

    ; Look for an empty spot in this chunk
    ldx #2
L3:
    ; Is the current spot empty?
    lda chunk,x
    inx
    ora chunk,x
    bne L4              ; Branch if the spot is not empty
    lda chunkNum + 1
    sta chunk,x
    dex
    lda chunkNum
    sta chunk,x
    lda thisChunkNum
    ldx thisChunkNum + 1
    jsr pushax
    lda #<chunk
    ldx #>chunk
    jsr _storeChunk
    jmp L6
L4:
    inx
    cpx #CHUNK_LEN-1
    bne L3              ; Branch if not all spots have been checked
    ; All spots in this index chunk have been checked.
    ; Is there another index chunk to go to?
    lda chunk
    ora chunk + 1
    bne L5
    ; Need to allocate another index chunk
    jsr allocNewIndexChunk
    ; Link the last index chunk to the new index chunk
    lda thisChunkNum
    ldx thisChunkNum + 1
    jsr pushax
    lda #<chunk
    ldx #>chunk
    jsr _retrieveChunk
    lda newChunkNum
    sta chunk
    lda newChunkNum + 1
    sta chunk + 1
    lda thisChunkNum
    ldx thisChunkNum + 1
    jsr pushax
    lda #<chunk
    ldx #>chunk
    jsr _storeChunk
    jmp L6
L5:
    ; Move to the next index chunk
    lda chunk
    sta thisChunkNum
    lda chunk + 1
    sta thisChunkNum + 1
    jmp L2
L6:
    lda chunkNum
    ldx chunkNum + 1
    jmp loadMemBufDataCache

.endproc
