;;;
 ; flushIcodeCache.s
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

.export _flushIcodeCache

.import _cachedIcodeHdr, _cachedIcodeHdrChunkNum
.import _cachedIcodeData, _cachedIcodeDataChunkNum
.import _storeChunk
.import pushax

; void flushIcodeCache()
.proc _flushIcodeCache
    ; Check if _cachedIcodeHdrChunkNum is non-zero
    lda _cachedIcodeHdrChunkNum
    ora _cachedIcodeHdrChunkNum + 1
    beq @CheckDataChunkNum      ; _cachedIcodeHdrChunkNum is zero
@StoreHdr:
    ; first parameter to _storeChunk
    lda _cachedIcodeHdrChunkNum
    ldx _cachedIcodeHdrChunkNum + 1
    jsr pushax
    ; second parameter to _storeChunk
    lda #<_cachedIcodeHdr
    ldx #>_cachedIcodeHdr
    jsr _storeChunk
    ; Set the header chunknum to zero
    lda #0
    sta _cachedIcodeHdrChunkNum
    sta _cachedIcodeHdrChunkNum + 1

@CheckDataChunkNum:
    ; Check if _cachedIcodeDataChunkNum is non-zero
    lda _cachedIcodeDataChunkNum
    ora _cachedIcodeDataChunkNum + 1
    beq @Done
@StoreData:
    ; first parameter to _storeChunk
    lda _cachedIcodeDataChunkNum
    ldx _cachedIcodeDataChunkNum + 1
    jsr pushax
    ; second parameter to _storeChunk
    lda #<_cachedIcodeData
    ldx #>_cachedIcodeData
    jsr _storeChunk
    ; Set the header chunknum to zero
    lda #0
    sta _cachedIcodeDataChunkNum
    sta _cachedIcodeDataChunkNum + 1

@Done:
    rts

.endproc
