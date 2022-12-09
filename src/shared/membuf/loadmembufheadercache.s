;;;
 ; loadMemBufHeaderCache.s
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

.export loadMemBufHeaderCache

.import _cachedMemBufHdr, _cachedMemBufHdrChunkNum
.import _retrieveChunk, _storeChunk
.import pushax

.bss

chunkNum: .res 2

.code

; void loadMemBufHeaderCache(CHUNKNUM chunkNum)
.proc loadMemBufHeaderCache
    ; Store the chunkNum parameter
    sta chunkNum
    stx chunkNum + 1
    ; Compare _cachedMemBufHdrChunkNum to chunkNum
    ; If they're the same value, nothing to do
    lda _cachedMemBufHdrChunkNum
    cmp chunkNum
    bne L1
    lda _cachedMemBufHdrChunkNum + 1
    cmp chunkNum + 1
    beq L3                      ; chunknum didn't change - nothing to do

L1:
    ; See if _cachedMemBufHdrChunkNum is non-zero
    ; If it is, store the chunk
    lda _cachedMemBufHdrChunkNum
    ora _cachedMemBufHdrChunkNum + 1
    beq L2                      ; it's zero - skip to retrieving

    ; first parameter to storeChunk
    lda _cachedMemBufHdrChunkNum
    ldx _cachedMemBufHdrChunkNum + 1
    jsr pushax
    ; second parameter to storeChunk
    lda #<_cachedMemBufHdr
    ldx #>_cachedMemBufHdr
    jsr _storeChunk

L2:
    ; first parameter to retrieveChunk
    lda chunkNum
    sta _cachedMemBufHdrChunkNum
    ldx chunkNum + 1
    stx _cachedMemBufHdrChunkNum + 1
    jsr pushax
    ; second parameter to retrieveChunk
    lda #<_cachedMemBufHdr
    ldx #>_cachedMemBufHdr
    jsr _retrieveChunk

L3:
    rts

.endproc
