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
.import _cachedMemBufHdr, _reserveMemBuf, flushMemBufCache
.import popax, pushax

.bss

remaining: .res 2
chunk: .res CHUNK_LEN

.code

; This routine uses the index of chunks to jump ahead
; by BYTES_PER_INDEX
.proc jumpUsingIndex
    ; Load the first index chunk
    lda _cachedMemBufHdr + MEMBUF::firstIndexChunk
    ldx _cachedMemBufHdr + MEMBUF::firstIndexChunk + 1
    jsr pushax
    lda #<chunk
    ldx #>chunk
    jsr _retrieveChunk

    ; Check if remaining is less than CHUNKS_PER_INDEX
L1:
    lda remaining + 1
    bne L2          ; not less than CHUNKS_PER_INDEX
    lda remaining
    cmp #BYTES_PER_INDEX
    bcc L3          ; branch if BYTES_PER_INDEX > remaining
L2:
    ; Decrement remaining by BYTES_PER_INDEX
    lda remaining
    sec
    sbc #BYTES_PER_INDEX
    sta remaining
    lda remaining + 1
    sbc #0
    sta remaining + 1
    ; Increment global position by BYTES_PER_INDEX
    lda _cachedMemBufHdr + MEMBUF::posGlobal
    clc
    adc #BYTES_PER_INDEX
    sta _cachedMemBufHdr + MEMBUF::posGlobal
    lda _cachedMemBufHdr + MEMBUF::posGlobal + 1
    adc #0
    sta _cachedMemBufHdr + MEMBUF::posGlobal + 1
    ; Move to the next index chunk
    lda chunk
    ldx chunk + 1
    jsr pushax
    lda #<chunk
    ldx #>chunk
    jsr _retrieveChunk
    jmp L1
L3:
    rts
.endproc

; This routine uses the index in the current _cachedMemBufData
; to load the chunk the caller is looking for.
.proc advanceToChunk
    ldx #2          ; index in _cachedMemBufData
L1:
    ; Check if remaining is less than MEMBUF_CHUNK_LEN
    lda remaining
    cmp #MEMBUF_CHUNK_LEN
    bcc L2          ; branch if MEMBUF_CHUNK_LEN > remaining
    ; Subtract MEMBUF_CHUNK_LEN from remaining
    lda remaining
    sec
    sbc #MEMBUF_CHUNK_LEN
    sta remaining
    ; Add MEMBUF_CHUNK_LEN to global position
    lda _cachedMemBufHdr + MEMBUF::posGlobal
    clc
    adc #MEMBUF_CHUNK_LEN
    sta _cachedMemBufHdr + MEMBUF::posGlobal
    lda _cachedMemBufHdr + MEMBUF::posGlobal + 1
    adc #0
    sta _cachedMemBufHdr + MEMBUF::posGlobal + 1
    ; Move to the next chunk in the index
    inx             ; increment index in chunk
    inx             ; by two
    jmp L1
L2:
    lda chunk,x
    sta _cachedMemBufHdr + MEMBUF::currentChunkNum
    inx
    tay
    lda chunk,x
    sta _cachedMemBufHdr + MEMBUF::currentChunkNum + 1
    tax
    tya
    jsr pushax
    lda #<chunk
    ldx #>chunk
    jsr _retrieveChunk
    ; Add remaining to the global position
    lda _cachedMemBufHdr + MEMBUF::posGlobal
    clc
    adc remaining
    sta _cachedMemBufHdr + MEMBUF::posGlobal
    lda _cachedMemBufHdr + MEMBUF::posGlobal + 1
    adc #0
    sta _cachedMemBufHdr + MEMBUF::posGlobal + 1
    ; Set the chunk position to remaining
    lda remaining
    sta _cachedMemBufHdr + MEMBUF::posChunk
    rts
.endproc

; void setMemBufPos(CHUNKNUM hdrChunkNum, unsigned position)
.proc _setMemBufPos
    ; Store the second parameter
    sta remaining
    stx remaining + 1
    ; Store the first parameter

    jsr flushMemBufCache

    jsr popax
    jsr loadMemBufHeaderCache

    ; Reset the buffer position
    lda #0
    sta _cachedMemBufHdr + MEMBUF::posGlobal
    sta _cachedMemBufHdr + MEMBUF::posGlobal + 1
    sta _cachedMemBufHdr + MEMBUF::posChunk
    sta _cachedMemBufHdr + MEMBUF::posChunk + 1

    lda remaining
    ora remaining + 1
    bne :+

    ; Load the first chunk
    lda _cachedMemBufHdr + MEMBUF::firstChunkNum
    sta _cachedMemBufHdr + MEMBUF::currentChunkNum
    ldx _cachedMemBufHdr + MEMBUF::firstChunkNum + 1
    stx _cachedMemBufHdr + MEMBUF::currentChunkNum + 1
    jmp loadMemBufDataCache

    ; Jump ahead using the index
:   jsr jumpUsingIndex

    ; Advance to the chunk
    jmp advanceToChunk
.endproc
