;;;
 ; pullDataFromIcode.s
 ; Ken Schenke (kenschenke@gmail.com)
 ; 
 ; Intermediate Code Storage and Retrieval
 ; 
 ; Copyright (c) 2022
 ; Use of this source code is governed by an MIT-style
 ; license that can be found in the LICENSE file or at
 ; https://opensource.org/licenses/MIT
;;;

.include "icode.inc"
.include "symtab.inc"

.export pullDataFromIcode

.import loadDataCache, loadHeaderCache
.import _cachedIcodeData, _cachedIcodeHdr
.import popax
.importzp ptr1, ptr2

.bss

hdrChunkNum: .res 2
data: .res 2
length: .res 2
toCopy: .res 1

.code

; void pullDataFromIcode(CHUNKNUM chunkNum, unsigned char *data, unsigned length)
.proc pullDataFromIcode
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

    ; Call loadHeaderCache
    jsr loadHeaderCache

    ; If currentChunkNum is non-zero, load the data cache
    lda _cachedIcodeHdr + ICODE::currentChunkNum
    ora _cachedIcodeHdr + ICODE::currentChunkNum + 1
    bne @LoadDataCache

    ; currentChunkNum is zero.  If firstChunkNum is also zero, bail out.
    lda _cachedIcodeHdr + ICODE::firstChunkNum
    ora _cachedIcodeHdr + ICODE::firstChunkNum + 1
    beq @JmpDone

    ; Set currentChunkNum from firstChunkNum
    lda _cachedIcodeHdr + ICODE::firstChunkNum
    sta _cachedIcodeHdr + ICODE::currentChunkNum
    lda _cachedIcodeHdr + ICODE::firstChunkNum + 1
    sta _cachedIcodeHdr + ICODE::currentChunkNum + 1

@LoadDataCache:
    ; Load the data cache with the current chunk from the ICODE
    lda _cachedIcodeHdr + ICODE::currentChunkNum
    ldx _cachedIcodeHdr + ICODE::currentChunkNum + 1
    jsr loadDataCache
    jmp @BlockLoop

@JmpDone:
    jmp @Done

    ; Loop until length is zero
@BlockLoop:
    lda length
    ora length + 1
    beq @JmpDone

    ; Calculate # of bytes to copy and put in toCopy
    ; if (length > ICODE_CHUNK_LEN - hdr.posChunk)
    ;    toCopy = ICODE_CHUNK_LEN - hdr.posChunk
    ; else
    ;    toCopy = length
    lda #ICODE_CHUNK_LEN
    sec
    sbc _cachedIcodeHdr + ICODE::posChunk
    sta toCopy              ; Assume we're copying ICODE_CHUNK_LEN - posChunk
    lda length + 1
    bne @CopyData           ; HB of length is non-zero.  length is definitely bigger.
    lda toCopy              ; if length > toCopy
    cmp length
    bcc @CopyData           ; LB of length > ICODE_CHUNK_LEN - posChunk
    ; length <= ICODE_CHUNK_LEN - posChunk
    lda length
    sta toCopy

@CopyData:
    ; ptr1 is the caller's data buffer
    lda data
    sta ptr1
    lda data + 1
    sta ptr1 + 1
    ; ptr2 is the source data buffer
    lda #<_cachedIcodeData
    sta ptr2
    lda #>_cachedIcodeData
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
    adc _cachedIcodeHdr + ICODE::posChunk
    sta ptr2
    lda ptr2 + 1
    adc #0
    sta ptr2 + 1
    ldy toCopy
    beq @Done
    dey
@CopyLoop:
    lda (ptr2),y
    sta (ptr1),y
    dey
    bpl @CopyLoop

    ; Move hdr.posChunk forward by toCopy
    clc
    lda _cachedIcodeHdr + ICODE::posChunk
    adc toCopy
    sta _cachedIcodeHdr + ICODE::posChunk
    lda _cachedIcodeHdr + ICODE::posChunk + 1
    adc #0
    sta _cachedIcodeHdr + ICODE::posChunk + 1

    ; Move hdr.posGlobal forward by toCopy
    clc
    lda _cachedIcodeHdr + ICODE::posGlobal
    adc toCopy
    sta _cachedIcodeHdr + ICODE::posGlobal
    lda _cachedIcodeHdr + ICODE::posGlobal + 1
    adc #0
    sta _cachedIcodeHdr + ICODE::posGlobal + 1

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
    beq @Done

    ; If there's no nextChunk, we're done
    lda _cachedIcodeData + ICODE_CHUNK::nextChunk
    ora _cachedIcodeData + ICODE_CHUNK::nextChunk + 1
    beq @Done

    ; Set hdr.posChunk to 0
    lda #0
    sta _cachedIcodeHdr + ICODE::posChunk
    sta _cachedIcodeHdr + ICODE::posChunk + 1

    ; Set hdr.currentChunk to data's nextChunk
    lda _cachedIcodeData + ICODE_CHUNK::nextChunk
    sta _cachedIcodeHdr + ICODE::currentChunkNum
    lda _cachedIcodeData + ICODE_CHUNK::nextChunk + 1
    sta _cachedIcodeHdr + ICODE::currentChunkNum + 1

    jmp @LoadDataCache

@Done:
    rts

.endproc
