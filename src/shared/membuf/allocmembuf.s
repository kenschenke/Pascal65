;;;
 ; allocMemBuf.s
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

.export _allocMemBuf

.import _allocChunk, _cachedMemBufHdr, flushMemBufCache, _storeChunk
.import pushax
.importzp ptr1

.bss

chunkNum: .res 2

.code

; void allocMemBuf(CHUNKNUM *newChunkNum)
.proc _allocMemBuf
    ; Store the chunkNum pointer
    sta chunkNum
    stx chunkNum + 1

    ; Flush the header cache so we can reuse it
    jsr flushMemBufCache

    ; Clear the header values
    lda #<_cachedMemBufHdr
    sta ptr1
    lda #>_cachedMemBufHdr
    sta ptr1 + 1
    lda #0
    ldy #.sizeof(MEMBUF) - 1
@Loop:
    sta (ptr1),y
    dey
    bpl @Loop
    
    ; Allocate a new chunk for the header
    lda chunkNum
    ldx chunkNum + 1
    jsr _allocChunk

    ; Call _storeChunk(chunkNum, MEMBUF *)
    lda chunkNum
    sta ptr1
    lda chunkNum + 1
    sta ptr1 + 1
    ldy #1
    lda (ptr1),y
    tax
    dey
    lda (ptr1),y
    jsr pushax

    lda #<_cachedMemBufHdr
    ldx #>_cachedMemBufHdr

    jmp _storeChunk

.endproc
