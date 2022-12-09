;;;
 ; freeMemBuf.s
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

.export _freeMemBuf

.import flushMemBufCache, _freeChunk
.import loadMemBufHeaderCache, _retrieveChunk
.import _cachedMemBufHdr, _cachedMemBufData
.import _cachedMemBufHdrChunkNum, _cachedMemBufDataChunkNum
.import pushax

.bss

chunkNum: .res 2
hdrChunkNum: .res 2

.code

; void freeMemBuf(CHUNKNUM chunkNum)
.proc _freeMemBuf
    ; Store the parameter
    sta chunkNum
    sta hdrChunkNum
    stx chunkNum + 1
    stx hdrChunkNum + 1

    jsr flushMemBufCache

    ; Call loadHeaderCache
    lda chunkNum
    ldx chunkNum + 1
    jsr loadMemBufHeaderCache

    ; Store the first chunkNum
    lda _cachedMemBufHdr + MEMBUF::firstChunkNum
    sta chunkNum
    lda _cachedMemBufHdr + MEMBUF::firstChunkNum + 1
    sta chunkNum + 1

L1:
    ; While chunkNum != 0
    lda chunkNum
    ora chunkNum + 1
    beq L2

    ; Retrieve the data chunk
    ; first parameter for retrieveChunk
    lda chunkNum
    ldx chunkNum + 1
    jsr pushax
    ; second parameter for retrieveChunk
    lda #<_cachedMemBufData
    ldx #>_cachedMemBufData
    jsr _retrieveChunk
    cmp #0
    beq L2

    ; Free the chunk
    lda chunkNum
    ldx chunkNum + 1
    jsr _freeChunk

    ; Next chunkNum
    lda _cachedMemBufData + MEMBUF_CHUNK::nextChunk
    sta chunkNum
    lda _cachedMemBufData + MEMBUF_CHUNK::nextChunk + 1
    sta chunkNum + 1

    jmp L1

L2:
    ; Free the header chunk
    lda hdrChunkNum
    ldx hdrChunkNum + 1
    jsr _freeChunk

    ; Clear the cached chunk numbers
    lda #0
    sta _cachedMemBufHdrChunkNum
    sta _cachedMemBufHdrChunkNum + 1
    sta _cachedMemBufDataChunkNum
    sta _cachedMemBufDataChunkNum + 1

    rts

.endproc
