;;;
 ; gotoIcodePosition.s
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

.export _gotoIcodePosition

.import loadDataCache, loadHeaderCache, _retrieveChunk
.import _cachedIcodeData, _cachedIcodeHdr
.import popax

.bss

hdrChunkNum: .res 2
position: .res 2

.code

; void gotoIcodePosition(CHUNKNUM hdrChunkNum, unsigned position)
.proc _gotoIcodePosition
    ; Store the second parameter
    sta position
    stx position + 1
    ; Store the first parameter
    jsr popax
    sta hdrChunkNum
    stx hdrChunkNum + 1

    ; Call loadHeaderCache
    lda hdrChunkNum
    ldx hdrChunkNum + 1
    jsr loadHeaderCache

    ; Reset the icode position
    lda #0
    sta _cachedIcodeHdr + ICODE::posGlobal
    sta _cachedIcodeHdr + ICODE::posGlobal + 1
    sta _cachedIcodeHdr + ICODE::posChunk
    sta _cachedIcodeHdr + ICODE::posChunk + 1

    ; Copy the firstChunkNum to currentChunkNum
    lda _cachedIcodeHdr + ICODE::firstChunkNum
    sta _cachedIcodeHdr + ICODE::currentChunkNum
    lda _cachedIcodeHdr + ICODE::firstChunkNum + 1
    sta _cachedIcodeHdr + ICODE::currentChunkNum + 1

    ; Loop until we get to the position we want
@Loop:
    ; Retrieve the chunk
    lda _cachedIcodeHdr + ICODE::currentChunkNum
    ldx _cachedIcodeHdr + ICODE::currentChunkNum + 1
    jsr loadDataCache

    ; If position < ICODE_CHUNK_LEN, this is the chunk we want
    lda position
    cmp #ICODE_CHUNK_LEN
    bcs @NextChunk      ; greater than or equal
    lda position + 1
    bne @NextChunk

    ; This is the chunk we want - set the icode header positions
    clc
    lda _cachedIcodeHdr + ICODE::posGlobal
    adc position
    sta _cachedIcodeHdr + ICODE::posGlobal
    lda _cachedIcodeHdr + ICODE::posGlobal + 1
    adc position + 1
    sta _cachedIcodeHdr + ICODE::posGlobal + 1
    ; set the chunk position
    lda position
    sta _cachedIcodeHdr + ICODE::posChunk
    lda position + 1
    sta _cachedIcodeHdr + ICODE::posChunk + 1
    jmp @Done

@NextChunk:
    ; Increment the global position
    clc
    lda position
    adc #ICODE_CHUNK_LEN
    sta position
    lda position + 1
    adc #0
    sta position + 1

    ; Decrement position
    sec
    lda position
    sbc #ICODE_CHUNK_LEN
    sta position
    lda position + 1
    sbc #0
    sta position + 1

    ; Set the next chunkNum
    lda _cachedIcodeData + ICODE_CHUNK::nextChunk
    sta _cachedIcodeHdr + ICODE::currentChunkNum
    lda _cachedIcodeData + ICODE_CHUNK::nextChunk + 1
    sta _cachedIcodeHdr + ICODE::currentChunkNum + 1

    jmp @Loop

@Done:
    rts

.endproc
