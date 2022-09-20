;;;
 ; freeIcode.s
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

.export _freeIcode

.import _flushIcodeCache, _freeChunk
.import loadHeaderCache, _retrieveChunk
.import _cachedIcodeHdr, _cachedIcodeData
.import _cachedIcodeHdrChunkNum, _cachedIcodeDataChunkNum
.import pushax

.bss

chunkNum: .res 2
hdrChunkNum: .res 2

.code

; void freeIcode(CHUNKNUM chunkNum)
.proc _freeIcode
    ; Store the parameter
    sta chunkNum
    sta hdrChunkNum
    stx chunkNum + 1
    stx hdrChunkNum + 1

    jsr _flushIcodeCache

    ; Call loadHeaderCache
    lda chunkNum
    ldx chunkNum + 1
    jsr loadHeaderCache

    ; Store the first chunkNum
    lda _cachedIcodeHdr + ICODE::firstChunkNum
    sta chunkNum
    lda _cachedIcodeHdr + ICODE::firstChunkNum + 1
    sta chunkNum + 1

@Loop:
    ; While chunkNum != 0
    lda chunkNum
    ora chunkNum + 1
    beq @Done

    ; Retrieve the data chunk
    ; first parameter for retrieveChunk
    lda chunkNum
    ldx chunkNum + 1
    jsr pushax
    ; second parameter for retrieveChunk
    lda #<_cachedIcodeData
    ldx #>_cachedIcodeData
    jsr _retrieveChunk
    cmp #0
    beq @Done

    ; Free the chunk
    lda chunkNum
    ldx chunkNum + 1
    jsr _freeChunk

    ; Next chunkNum
    lda _cachedIcodeData + ICODE_CHUNK::nextChunk
    sta chunkNum
    lda _cachedIcodeData + ICODE_CHUNK::nextChunk + 1
    sta chunkNum + 1

    jmp @Loop

@Done:
    ; Free the header chunk
    lda hdrChunkNum
    ldx hdrChunkNum + 1
    jsr _freeChunk

    ; Clear the cached chunk numbers
    lda #0
    sta _cachedIcodeHdrChunkNum
    sta _cachedIcodeHdrChunkNum + 1
    sta _cachedIcodeDataChunkNum
    sta _cachedIcodeDataChunkNum + 1

    rts

.endproc
