;;;
 ; writeToMemBuf.s
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

.export _writeToMemBuf

.import initMemBufChunk, loadMemBufDataCache, loadMemBufHeaderCache
.import _cachedMemBufData, _cachedMemBufHdr
.import intOp1, intOp2, geUint16
.import popax
.importzp ptr1, ptr2

.bss

hdrChunkNum: .res 2
data: .res 2
length: .res 2
toCopy: .res 1

.code

; TODO
; 
; Update hdr.used if offset + length > hdr.used

; void writeToMemBuf(CHUNKNUM chunkNum, unsigned char *data, unsigned length)
.proc _writeToMemBuf
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
    ; .A and .X already have the header chunknum
    jsr loadMemBufHeaderCache

    ; Check if hdr.firstChunkNum is zero
    lda _cachedMemBufHdr + MEMBUF::firstChunkNum
    ora _cachedMemBufHdr + MEMBUF::firstChunkNum + 1
    bne L1

    ; hdr.firstChunkNum is zero.  Initialize a new chunk
    lda hdrChunkNum
    ldx hdrChunkNum + 1
    jsr initMemBufChunk
    jmp L4

L1:
    ; If currentChunkNum is non-zero, load the data cache
    lda _cachedMemBufHdr + MEMBUF::currentChunkNum
    ora _cachedMemBufHdr + MEMBUF::currentChunkNum + 1
    bne L2

    ; Set currentChunkNum from firstChunkNum
    lda _cachedMemBufHdr + MEMBUF::firstChunkNum
    sta _cachedMemBufHdr + MEMBUF::currentChunkNum
    lda _cachedMemBufHdr + MEMBUF::firstChunkNum + 1
    sta _cachedMemBufHdr + MEMBUF::currentChunkNum + 1

L2:
    ; Load the data cache with the current chunk from the MEMBUF
    lda _cachedMemBufHdr + MEMBUF::currentChunkNum
    ldx _cachedMemBufHdr + MEMBUF::currentChunkNum + 1
    jsr loadMemBufDataCache
    jmp L4

L3:
    jmp Done

    ; Loop until length is zero
L4:
    lda length
    ora length + 1
    beq L3

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
    bne L5                  ; HB of length is non-zero.  length is definitely bigger.
    lda toCopy              ; if length > toCopy
    cmp length
    bcc L5                  ; LB of length > MEMBUF_CHUNK_LEN - posChunk
    ; length <= MEMBUF_CHUNK_LEN - posChunk
    lda length
    sta toCopy

L5:
    ; ptr1 is the caller's data buffer
    lda data
    sta ptr1
    lda data + 1
    sta ptr1 + 1
    ; ptr2 is the destination data buffer
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
    beq L7
    dey
L6:
    lda (ptr1),y
    sta (ptr2),y
    dey
    bpl L6

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

L7:
    ; Check if the next chunk is already allocated
    lda _cachedMemBufData + MEMBUF_CHUNK::nextChunk
    ora _cachedMemBufData + MEMBUF_CHUNK::nextChunk + 1
    bne L8
    lda hdrChunkNum
    ldx hdrChunkNum + 1
    jsr initMemBufChunk
    jmp L4

L8:
    lda _cachedMemBufData + MEMBUF_CHUNK::nextChunk
    sta _cachedMemBufHdr + MEMBUF::currentChunkNum
    lda _cachedMemBufData + MEMBUF_CHUNK::nextChunk + 1
    sta _cachedMemBufHdr + MEMBUF::currentChunkNum + 1
    lda #0
    sta _cachedMemBufHdr + MEMBUF::posChunk
    sta _cachedMemBufHdr + MEMBUF::posChunk + 1
    jmp L2

Done:
    ; If posGlobal >= used, set used to posGlobal
    lda _cachedMemBufHdr + MEMBUF::posGlobal
    sta intOp1
    lda _cachedMemBufHdr + MEMBUF::posGlobal + 1
    sta intOp1 + 1
    lda _cachedMemBufHdr + MEMBUF::used
    sta intOp2
    lda _cachedMemBufHdr + MEMBUF::used + 1
    sta intOp2 + 1
    jsr geUint16
    beq L9
    lda _cachedMemBufHdr + MEMBUF::posGlobal
    sta _cachedMemBufHdr + MEMBUF::used
    lda _cachedMemBufHdr + MEMBUF::posGlobal + 1
    sta _cachedMemBufHdr + MEMBUF::used + 1

L9:
    rts

.endproc
