;;;
 ; loadDataCache.s
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

.export loadDataCache

.import _cachedIcodeData, _cachedIcodeDataChunkNum
.import _retrieveChunk, _storeChunk
.import pushax

.bss

chunkNum: .res 2

.code

; void loadDataCache(CHUNKNUM chunkNum)
.proc loadDataCache
    ; Store the chunkNum parameter
    sta chunkNum
    stx chunkNum + 1
    ; Compare _cachedIcodeDataChunkNum to chunkNum
    ; If they're the same value, nothing to do
    lda _cachedIcodeDataChunkNum
    cmp chunkNum
    bne @CheckChunkNumNonZero
    lda _cachedIcodeDataChunkNum + 1
    cmp chunkNum + 1
    beq @Done                   ; chunknum didn't change - nothing to do

@CheckChunkNumNonZero:
    ; See if _cachedIcodeDataChunkNum is non-zero
    ; If it is, store the chunk
    lda _cachedIcodeDataChunkNum
    ora _cachedIcodeDataChunkNum + 1
    beq @RetrieveChunk          ; it's zero - skip to retrieving

@StoreChunk:
    ; first parameter to storeChunk
    lda _cachedIcodeDataChunkNum
    ldx _cachedIcodeDataChunkNum + 1
    jsr pushax
    ; second parameter to storeChunk
    lda #<_cachedIcodeData
    ldx #>_cachedIcodeData
    jsr _storeChunk

@RetrieveChunk:
    ; first parameter to retrieveChunk
    lda chunkNum
    sta _cachedIcodeDataChunkNum
    ldx chunkNum + 1
    stx _cachedIcodeDataChunkNum + 1
    jsr pushax
    ; second parameter to retrieveChunk
    lda #<_cachedIcodeData
    ldx #>_cachedIcodeData
    jsr _retrieveChunk

@Done:
    rts

.endproc
