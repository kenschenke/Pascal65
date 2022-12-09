;;;
 ; flushMemBufCache.s
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

.export flushMemBufCache

.import _cachedMemBufHdr, _cachedMemBufHdrChunkNum
.import _cachedMemBufData, _cachedMemBufDataChunkNum
.import _storeChunk
.import pushax

; void flushMemBufCache()
.proc flushMemBufCache
    ; Check if _cachedMemBufHdrChunkNum is non-zero
    lda _cachedMemBufHdrChunkNum
    ora _cachedMemBufHdrChunkNum + 1
    beq L1      ; _cachedMemBufHdrChunkNum is zero

    ; first parameter to _storeChunk
    lda _cachedMemBufHdrChunkNum
    ldx _cachedMemBufHdrChunkNum + 1
    jsr pushax
    ; second parameter to _storeChunk
    lda #<_cachedMemBufHdr
    ldx #>_cachedMemBufHdr
    jsr _storeChunk
    ; Set the header chunknum to zero
    lda #0
    sta _cachedMemBufHdrChunkNum
    sta _cachedMemBufHdrChunkNum + 1

L1:
    ; Check if _cachedMemBufDataChunkNum is non-zero
    lda _cachedMemBufDataChunkNum
    ora _cachedMemBufDataChunkNum + 1
    beq L2

    ; first parameter to _storeChunk
    lda _cachedMemBufDataChunkNum
    ldx _cachedMemBufDataChunkNum + 1
    jsr pushax
    ; second parameter to _storeChunk
    lda #<_cachedMemBufData
    ldx #>_cachedMemBufData
    jsr _storeChunk
    ; Set the header chunknum to zero
    lda #0
    sta _cachedMemBufDataChunkNum
    sta _cachedMemBufDataChunkNum + 1

L2:
    rts

.endproc
