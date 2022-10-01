;;;
 ; initIcodeChunk.s
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
.include "error.inc"

.export initIcodeChunk

.import _abortTranslation, _allocChunk, _Error, _flushIcodeCache
.import loadDataCache, loadHeaderCache, _retrieveChunk, _storeChunk
.import _cachedIcodeData, _cachedIcodeHdr
.import pushax
.importzp ptr1

.bss

chunkNum: .res 2
hdrChunkNum: .res 2

.code

; void initIcodeChunk(CHUNKNUM hdrChunkNum)
.proc initIcodeChunk
    ; Store the parameter
    sta hdrChunkNum
    stx hdrChunkNum + 1

    jsr _flushIcodeCache

    ; Call loadHeaderCache
    lda hdrChunkNum
    ldx hdrChunkNum + 1
    jsr loadHeaderCache

    ; Allocate a new chunk
    lda #<chunkNum
    ldx #>chunkNum
    jsr _allocChunk
    cmp #0
    bne @CheckFirstChunk
    ; Segment overflow (out of memory)
    lda #errCodeSegmentOverflow
    ldx #0
    jsr _Error
    lda #abortCodeSegmentOverflow
    ldx #0
    jsr _abortTranslation
    jmp @Done

@CheckFirstChunk:
    ; Is this the first chunk in the ICODE table?
    lda _cachedIcodeHdr + ICODE::firstChunkNum
    ora _cachedIcodeHdr + ICODE::firstChunkNum + 1
    bne @SetNextChunk
    ; First chunk in ICODE table
    lda chunkNum
    sta _cachedIcodeHdr + ICODE::firstChunkNum
    lda chunkNum + 1
    sta _cachedIcodeHdr + ICODE::firstChunkNum + 1
    jmp @SetupDataChunk

@SetNextChunk:
    ; Is cachedIcodeHdr currentChunkNum zero?
    lda _cachedIcodeHdr + 2 ; ICODE::currentChunkNum
    ora _cachedIcodeHdr + 3 ; ICODE::currentChunkNum + 1
    beq @SetupDataChunk ; It's zero - skip to setting up the new data chunk

    ; Set the previous chunk's nextChunk to point to this new node

    ; Retrieve the current chunk
    ; First parameter to retrieveChunk
    lda _cachedIcodeHdr + 2 ; ICODE::currentChunkNum
    ldx _cachedIcodeHdr + 3 ; ICODE::currentChunkNum + 1
    jsr pushax
    ; Second parameter
    lda #<_cachedIcodeData
    ldx #>_cachedIcodeData
    jsr _retrieveChunk
    cmp #0
    bne @SetChunkNum

    ; Failed to retrieve the chunk
    lda #errCodeSegmentOverflow
    ldx #0
    jsr _Error
    lda #abortCodeSegmentOverflow
    ldx #0
    jsr _abortTranslation
    jmp @Done

@SetChunkNum:
    ; Set the next chunk number
    lda chunkNum
    sta _cachedIcodeData + ICODE_CHUNK::nextChunk
    lda chunkNum + 1
    sta _cachedIcodeData + ICODE_CHUNK::nextChunk + 1

    ; Store the chunk
    ; First parameter
    lda _cachedIcodeHdr + ICODE::currentChunkNum
    ldx _cachedIcodeHdr + ICODE::currentChunkNum + 1
    jsr pushax
    ; Second parameter
    lda #<_cachedIcodeData
    ldx #>_cachedIcodeData
    jsr _storeChunk
    cmp #0
    bne @SetupDataChunk

    ; Failed to store the chunk
    lda #errCodeSegmentOverflow
    ldx #0
    jsr _Error
    lda #abortCodeSegmentOverflow
    ldx #0
    jsr _abortTranslation
    jmp @Done

@SetupDataChunk:
    ; Set the new data chunk to 0's
    ldy #.sizeof(ICODE_CHUNK)
    lda #<_cachedIcodeData
    sta ptr1
    lda #>_cachedIcodeData
    sta ptr1 + 1
    lda #0
@Loop:
    sta (ptr1),y
    dey
    bne @Loop

    ; Set the header's currentChunkNum to the new chunkNum
    lda chunkNum
    sta _cachedIcodeHdr + ICODE::currentChunkNum
    lda chunkNum + 1
    sta _cachedIcodeHdr + ICODE::currentChunkNum + 1
    lda #0
    sta _cachedIcodeHdr + ICODE::posChunk
    sta _cachedIcodeHdr + ICODE::posChunk + 1

    ; Load the data cache with the new data chunk
    lda chunkNum
    ldx chunkNum + 1
    jsr loadDataCache

@Done:
    rts

.endproc
