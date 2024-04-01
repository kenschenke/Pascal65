;;;
 ; freeMemBuf.s
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

.export _freeMemBuf

.import _freeChunk
.import _retrieveChunk, _storeChunk
.import _cachedMemBufHdr, _cachedMemBufData
.import _cachedMemBufHdrChunkNum, _cachedMemBufDataChunkNum
.import pushax

.bss

chunkNum: .res 2
hdrChunkNum: .res 2

.code

.proc freeIndexChunks
    lda _cachedMemBufHdr + MEMBUF::firstIndexChunk
    sta chunkNum
    lda _cachedMemBufHdr + MEMBUF::firstIndexChunk + 1
    sta chunkNum + 1

L1:
    lda chunkNum
    ora chunkNum + 1
    beq L2
    lda chunkNum
    ldx chunkNum + 1
    jsr pushax
    lda #<_cachedMemBufData
    ldx #>_cachedMemBufData
    jsr _retrieveChunk

    lda chunkNum
    ldx chunkNum + 1
    jsr _freeChunk

    lda _cachedMemBufData
    sta chunkNum
    lda _cachedMemBufData + 1
    sta chunkNum + 1
    jmp L1

L2:
    rts
.endproc

; void freeMemBuf(CHUNKNUM chunkNum)
.proc _freeMemBuf
    ; Store the parameter
    sta chunkNum
    sta hdrChunkNum
    stx chunkNum + 1
    stx hdrChunkNum + 1

    lda _cachedMemBufHdrChunkNum
    ora _cachedMemBufHdrChunkNum + 1
    beq L9
    lda _cachedMemBufHdrChunkNum
    ldx _cachedMemBufHdrChunkNum + 1
    jsr pushax
    lda #<_cachedMemBufHdr
    ldx #>_cachedMemBufHdr
    jsr _storeChunk
    lda #0
    sta _cachedMemBufHdrChunkNum
    sta _cachedMemBufHdrChunkNum + 1

L9:
    lda _cachedMemBufDataChunkNum
    ora _cachedMemBufDataChunkNum + 1
    beq L8
    lda _cachedMemBufDataChunkNum
    ldx _cachedMemBufDataChunkNum + 1
    jsr pushax
    lda #<_cachedMemBufData
    ldx #>_cachedMemBufData
    jsr _storeChunk
    lda #0
    sta _cachedMemBufDataChunkNum
    sta _cachedMemBufDataChunkNum + 1

L8:
    ; Call loadHeaderCache
    lda hdrChunkNum
    ldx hdrChunkNum + 1
    jsr pushax
    lda #<_cachedMemBufHdr
    ldx #>_cachedMemBufHdr
    jsr _retrieveChunk

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
    jsr freeIndexChunks
    
    ; Free the header chunk
    lda hdrChunkNum
    ldx hdrChunkNum + 1
    jsr _freeChunk

    rts

.endproc
