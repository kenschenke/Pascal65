;;;
 ; loadHeaderCache.s
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

.export loadHeaderCache

.import _cachedIcodeHdr, _cachedIcodeHdrChunkNum
.import _retrieveChunk, _storeChunk
.import pushax

.bss

chunkNum: .res 2

.code

; void loadHeaderCache(CHUNKNUM chunkNum)
.proc loadHeaderCache
    ; Store the chunkNum parameter
    sta chunkNum
    stx chunkNum + 1
    ; Compare _cachedIcodeHdrChunkNum to chunkNum
    ; If they're the same value, nothing to do
    lda _cachedIcodeHdrChunkNum
    cmp chunkNum
    bne @CheckChunkNumNonZero
    lda _cachedIcodeHdrChunkNum + 1
    cmp chunkNum + 1
    beq @Done                   ; chunknum didn't change - nothing to do

@CheckChunkNumNonZero:
    ; See if _cachedIcodeHdrChunkNum is non-zero
    ; If it is, store the chunk
    lda _cachedIcodeHdrChunkNum
    ora _cachedIcodeHdrChunkNum + 1
    beq @RetrieveChunk          ; it's zero - skip to retrieving

@StoreChunk:
    ; first parameter to storeChunk
    lda _cachedIcodeHdrChunkNum
    ldx _cachedIcodeHdrChunkNum + 1
    jsr pushax
    ; second parameter to storeChunk
    lda #<_cachedIcodeHdr
    ldx #>_cachedIcodeHdr
    jsr _storeChunk

@RetrieveChunk:
    ; first parameter to retrieveChunk
    lda chunkNum
    sta _cachedIcodeHdrChunkNum
    ldx chunkNum + 1
    stx _cachedIcodeHdrChunkNum + 1
    jsr pushax
    ; second parameter to retrieveChunk
    lda #<_cachedIcodeHdr
    ldx #>_cachedIcodeHdr
    jsr _retrieveChunk

@Done:
    rts

.endproc
