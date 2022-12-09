;;;
 ; readFromMemBuf.s
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

.export _readFromMemBuf

.import loadMemBufDataCache, loadMemBufHeaderCache
.import _cachedMemBufData, _cachedMemBufHdr
.import popax
.importzp ptr1, ptr2

.bss

hdrChunkNum: .res 2
data: .res 2
length: .res 2
toCopy: .res 1

.code

; void readFromMemBuf(CHUNKNUM chunkNum, unsigned char *data, unsigned length)
.proc _readFromMemBuf
    ; Store the third parameter
    sta length
    stx length + 1
    ; Store the second parameter
    jsr popax
    sta data
    stx data + 1
    ; Store the first parameter
    jsr popax
    sta hdrChunkNum
    stx hdrChunkNum + 1

    ; Call loadMemBufHeaderCache
    jsr loadMemBufHeaderCache

    ; If currentChunkNum is non-zero, load the data cache
    lda _cachedMemBufHdr + MEMBUF::currentChunkNum
    ora _cachedMemBufHdr + MEMBUF::currentChunkNum + 1
    bne L1

    ; currentChunkNum is zero.  If firstChunkNum is also zero, bail out.
    lda _cachedMemBufHdr + MEMBUF::firstChunkNum
    ora _cachedMemBufHdr + MEMBUF::firstChunkNum + 1
    beq L2

    ; Set currentChunkNum from firstChunkNum
    lda _cachedMemBufHdr + MEMBUF::firstChunkNum
    sta _cachedMemBufHdr + MEMBUF::currentChunkNum
    lda _cachedMemBufHdr + MEMBUF::firstChunkNum + 1
    sta _cachedMemBufHdr + MEMBUF::currentChunkNum + 1

L1:
    ; Load the data cache with the current chunk from the buffer
    lda _cachedMemBufHdr + MEMBUF::currentChunkNum
    ldx _cachedMemBufHdr + MEMBUF::currentChunkNum + 1
    jsr loadMemBufDataCache
    jmp L3

L2:
    jmp Done

    ; Loop until length is zero
L3:
    lda length
    ora length + 1
    beq L2

    ; Calculate # of bytes to copy and put in toCopy
    ; if (length > MEMBUF_CHUNK_LEN - hdr.posChunk)
    ;    toCopy = MEMBUF_CHUNK_LEN - hdr.posChunk
    ; else
    ;    toCopy = length
    lda #MEMBUF_CHUNK_LEN
    sec
    sbc _cachedMemBufHdr + MEMBUF::posChunk
    sta toCopy              ; Assume we're copying MEMBUF_CHUNK_LEN - posChunk
    lda length + 1
    bne L4                  ; HB of length is non-zero.  length is definitely bigger.
    lda toCopy              ; if length > toCopy
    cmp length
    bcc L4                  ; LB of length > MEMBUF_CHUNK_LEN - posChunk
    ; length <= MEMBUF_CHUNK_LEN - posChunk
    lda length
    sta toCopy

L4:
    ; ptr1 is the caller's data buffer
    lda data
    sta ptr1
    lda data + 1
    sta ptr1 + 1
    ; ptr2 is the source data buffer
    lda #<_cachedMemBufData
    sta ptr2
    lda #>_cachedMemBufData
    sta ptr2 + 1
    ; Add struct offset of 2 to ptr2
    clc
    lda ptr2
    adc #2
    sta ptr2
    lda ptr2 + 1
    adc #0
    sta ptr2 + 1
    ; Add hdr.posChunk to ptr2
    clc
    lda ptr2
    adc _cachedMemBufHdr + MEMBUF::posChunk
    sta ptr2
    lda ptr2 + 1
    adc #0
    sta ptr2 + 1
    ldy toCopy
    ; If toCopy is zero, the next chunk is needed
    beq L6
    dey
L5:
    lda (ptr2),y
    sta (ptr1),y
    dey
    bpl L5

    ; Move hdr.posChunk forward by toCopy
    clc
    lda _cachedMemBufHdr + MEMBUF::posChunk
    adc toCopy
    sta _cachedMemBufHdr + MEMBUF::posChunk
    lda _cachedMemBufHdr + MEMBUF::posChunk + 1
    adc #0
    sta _cachedMemBufHdr + MEMBUF::posChunk + 1

    ; Move hdr.posGlobal forward by toCopy
    clc
    lda _cachedMemBufHdr + MEMBUF::posGlobal
    adc toCopy
    sta _cachedMemBufHdr + MEMBUF::posGlobal
    lda _cachedMemBufHdr + MEMBUF::posGlobal + 1
    adc #0
    sta _cachedMemBufHdr + MEMBUF::posGlobal + 1

    ; Move data forward by toCopy
    clc
    lda data
    adc toCopy
    sta data
    lda data + 1
    adc #0
    sta data + 1

    ; Decrease length by toCopy
    sec
    lda length
    sbc toCopy
    sta length
    lda length + 1
    sbc #0
    sta length + 1

    ; If length is zero, we're done
    lda length
    ora length + 1
    beq Done

L6:
    ; If there's no nextChunk, we're done
    lda _cachedMemBufData + MEMBUF_CHUNK::nextChunk
    ora _cachedMemBufData + MEMBUF_CHUNK::nextChunk + 1
    beq Done

    ; Set hdr.posChunk to 0
    lda #0
    sta _cachedMemBufHdr + MEMBUF::posChunk
    sta _cachedMemBufHdr + MEMBUF::posChunk + 1

    ; Set hdr.currentChunk to data's nextChunk
    lda _cachedMemBufData + MEMBUF_CHUNK::nextChunk
    sta _cachedMemBufHdr + MEMBUF::currentChunkNum
    lda _cachedMemBufData + MEMBUF_CHUNK::nextChunk + 1
    sta _cachedMemBufHdr + MEMBUF::currentChunkNum + 1

    jmp L1

Done:
    rts

.endproc
