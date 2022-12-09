;;;
 ; setMemBufPos.s
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

.export _setMemBufPos

.import loadMemBufDataCache, loadMemBufHeaderCache, _retrieveChunk
.import _cachedMemBufData, _cachedMemBufHdr, _reserveMemBuf
.import geUint16, ltUint16, intOp1, intOp2
.import popax, pushax

.bss

hdrChunkNum: .res 2
position: .res 2

.code

; void setMemBufPos(CHUNKNUM hdrChunkNum, unsigned position)
.proc _setMemBufPos
    ; Store the second parameter
    sta position
    sta intOp1              ; for later
    stx position + 1
    stx intOp1 + 1          ; for later
    ; Store the first parameter
    jsr popax
    sta hdrChunkNum
    stx hdrChunkNum + 1

    ; Call reserveMemBuf for the requested position in case the caller
    ; is trying to seek past the end of the current capacity.
    lda hdrChunkNum
    ldx hdrChunkNum + 1
    jsr pushax
    lda position
    ldx position + 1
    jsr _reserveMemBuf

    ; Call loadMemBufHeaderCache
    lda hdrChunkNum
    ldx hdrChunkNum + 1
    jsr loadMemBufHeaderCache

L0:
    ; Reset the buffer position
    lda #0
    sta _cachedMemBufHdr + MEMBUF::posGlobal
    sta _cachedMemBufHdr + MEMBUF::posGlobal + 1
    sta _cachedMemBufHdr + MEMBUF::posChunk
    sta _cachedMemBufHdr + MEMBUF::posChunk + 1

    ; Copy the firstChunkNum to currentChunkNum
    lda _cachedMemBufHdr + MEMBUF::firstChunkNum
    sta _cachedMemBufHdr + MEMBUF::currentChunkNum
    lda _cachedMemBufHdr + MEMBUF::firstChunkNum + 1
    sta _cachedMemBufHdr + MEMBUF::currentChunkNum + 1

    ; Loop until we get to the position we want
L1:
    ; Retrieve the chunk
    lda _cachedMemBufHdr + MEMBUF::currentChunkNum
    ldx _cachedMemBufHdr + MEMBUF::currentChunkNum + 1
    jsr loadMemBufDataCache

    ; If position < MEMBUF_CHUNK_LEN, this is the chunk we want
    lda position
    sta intOp1
    lda position + 1
    sta intOp1 + 1
    lda #MEMBUF_CHUNK_LEN
    sta intOp2
    lda #0
    sta intOp2 + 1
    jsr ltUint16
    beq L2      ; greater than or equal

    ; This is the chunk we want - set the buffer header positions
    clc
    lda _cachedMemBufHdr + MEMBUF::posGlobal
    adc position
    sta _cachedMemBufHdr + MEMBUF::posGlobal
    lda _cachedMemBufHdr + MEMBUF::posGlobal + 1
    adc position + 1
    sta _cachedMemBufHdr + MEMBUF::posGlobal + 1
    ; set the chunk position
    lda position
    sta _cachedMemBufHdr + MEMBUF::posChunk
    lda position + 1
    sta _cachedMemBufHdr + MEMBUF::posChunk + 1
    jmp L3

L2:
    ; Increment the global position
    clc
    lda _cachedMemBufHdr + MEMBUF::posGlobal
    adc #MEMBUF_CHUNK_LEN
    sta _cachedMemBufHdr + MEMBUF::posGlobal
    lda _cachedMemBufHdr + MEMBUF::posGlobal + 1
    adc #0
    sta _cachedMemBufHdr + MEMBUF::posGlobal + 1

    ; Decrement position
    sec
    lda position
    sbc #MEMBUF_CHUNK_LEN
    sta position
    lda position + 1
    sbc #0
    sta position + 1

    ; Set the next chunkNum
    lda _cachedMemBufData + MEMBUF_CHUNK::nextChunk
    sta _cachedMemBufHdr + MEMBUF::currentChunkNum
    lda _cachedMemBufData + MEMBUF_CHUNK::nextChunk + 1
    sta _cachedMemBufHdr + MEMBUF::currentChunkNum + 1

    jmp L1

L3:
    rts

.endproc
