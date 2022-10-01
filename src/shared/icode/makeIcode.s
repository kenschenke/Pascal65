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

.import _allocChunk, _cachedIcodeHdr, _flushIcodeCache, _storeChunk
.import pushax
.importzp ptr1

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
    lda #<_cachedIcodeHdr
    sta ptr1
    lda #>_cachedIcodeHdr
    sta ptr1 + 1
    lda #0
    ldy #.sizeof(ICODE) - 1
@Loop:
    sta (ptr1),y
    dey
    bpl @Loop
    
    ; Allocate a new chunk for the header
    lda chunkNum
    ldx chunkNum + 1
    jsr _allocChunk

    ; Call _storeChunk(chunkNum, ICODE *)
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

    lda #<_cachedIcodeHdr
    ldx #>_cachedIcodeHdr

    jmp _storeChunk

.endproc
