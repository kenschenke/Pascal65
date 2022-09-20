;;;
 ; makeIcode.s
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

.export _makeIcode

.import _allocChunk, _cachedIcodeHdrChunkNum, _flushIcodeCache, _storeChunk
.import pushax

.bss

chunkNum: .res 2

.code

; void makeIcode(CHUNKNUM *newChunkNum)
.proc _makeIcode
    ; Store the chunkNum pointer
    sta chunkNum
    stx chunkNum + 1

    ; Flush the header cache so we can reuse it
    jsr _flushIcodeCache

    ; Clear the header values
    lda #0
    sta _cachedIcodeHdrChunkNum + ICODE::currentChunkNum
    sta _cachedIcodeHdrChunkNum + ICODE::currentChunkNum + 1
    sta _cachedIcodeHdrChunkNum + ICODE::firstChunkNum
    sta _cachedIcodeHdrChunkNum + ICODE::firstChunkNum + 1
    sta _cachedIcodeHdrChunkNum + ICODE::posGlobal
    sta _cachedIcodeHdrChunkNum + ICODE::posGlobal + 1
    sta _cachedIcodeHdrChunkNum + ICODE::posChunk
    sta _cachedIcodeHdrChunkNum + ICODE::posChunk + 1
    
    ; Allocate a new chunk for the header
    lda chunkNum
    ldx chunkNum + 1
    jsr _allocChunk

    ; Call _storeChunk(chunkNum, ICODE *)
    lda #<_cachedIcodeHdrChunkNum
    ldx #>_cachedIcodeHdrChunkNum
    jsr pushax

    lda chunkNum
    ldx chunkNum + 1

    jmp _storeChunk

.endproc
