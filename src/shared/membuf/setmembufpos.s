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
.import popax, pushax

.bss

hdrChunkNum: .res 2
position: .res 2

.code

.proc isPosLtChunkLen
    ; If high byte of position set, it's definitely
    ; not less than the chunk length.
    ; Compare the high bytes first
    lda position + 1
    bne L1

    ; Compare the lower byte of position
    lda position
    cmp #MEMBUF_CHUNK_LEN
    bcc L2

L1:
    lda #0
    rts

L2:
    lda #1
    rts
.endproc

; void setMemBufPos(CHUNKNUM hdrChunkNum, unsigned position)
.proc _setMemBufPos
    ; Store the second parameter
    sta position
    stx position + 1
    ; Store the first parameter
    jsr popax
    sta hdrChunkNum
    stx hdrChunkNum + 1

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
    jsr isPosLtChunkLen
    beq L2      ; greater than or equal

    ; This is the chunk we want - set the buffer header positions
    clc
    lda _cachedMemBufHdr + MEMBUF::posGlobal
    adc position
    sta _cachedMemBufHdr + MEMBUF::posGlobal
    lda _cachedMemBufHdr + MEMBUF::posGlobal + 1
    adc #0 ; position + 1
    sta _cachedMemBufHdr + MEMBUF::posGlobal + 1
    ; set the chunk position
    lda position
    sta _cachedMemBufHdr + MEMBUF::posChunk
    lda #0 ; position + 1
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
