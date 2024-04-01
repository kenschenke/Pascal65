;;;
 ; loadMemBufDataCache.s
 ; Ken Schenke (kenschenke@gmail.com)
 ; 
 ; Memory Buffer Storage and Retrieval
 ; 
 ; Copyright (c) 2024
 ; Use of this source code is governed by an MIT-style
 ; license that can be found in the LICENSE file or at
 ; https://opensource.org/licenses/MIT
;;;

.include "membuf.inc"

.export loadMemBufDataCache

.import _cachedMemBufData, _cachedMemBufDataChunkNum
.import _retrieveChunk, _storeChunk
.import pushax

.bss

chunkNum: .res 2

.code

; void loadMemBufDataCache(CHUNKNUM chunkNum)
.proc loadMemBufDataCache
    ; Store the chunkNum parameter
    sta chunkNum
    stx chunkNum + 1
    ; Compare _cachedMemBufDataChunkNum to chunkNum
    ; If they're the same value, nothing to do
    lda _cachedMemBufDataChunkNum
    cmp chunkNum
    bne L1
    lda _cachedMemBufDataChunkNum + 1
    cmp chunkNum + 1
    beq L3                      ; chunknum didn't change - nothing to do

L1:
    ; See if _cachedMemBufDataChunkNum is non-zero
    ; If it is, store the chunk
    lda _cachedMemBufDataChunkNum
    ora _cachedMemBufDataChunkNum + 1
    beq L2                      ; it's zero - skip to retrieving

    ; first parameter to storeChunk
    lda _cachedMemBufDataChunkNum
    ldx _cachedMemBufDataChunkNum + 1
    jsr pushax
    ; second parameter to storeChunk
    lda #<_cachedMemBufData
    ldx #>_cachedMemBufData
    jsr _storeChunk

L2:
    ; first parameter to retrieveChunk
    lda chunkNum
    sta _cachedMemBufDataChunkNum
    ldx chunkNum + 1
    stx _cachedMemBufDataChunkNum + 1
    jsr pushax
    ; second parameter to retrieveChunk
    lda #<_cachedMemBufData
    ldx #>_cachedMemBufData
    jsr _retrieveChunk

L3:
    rts

.endproc
