;;;
 ; getChunkCopy.s
 ; Ken Schenke (kenschenke@gmail.com)
 ; 
 ; _getChunkCopy
 ; 
 ; Copyright (c) 2024
 ; Use of this source code is governed by an MIT-style
 ; license that can be found in the LICENSE file or at
 ; https://opensource.org/licenses/MIT
;;;

.include "chunks.inc"

.export _getChunkCopy
.import popax, _getChunk
.importzp ptr1, ptr2

; char getChunkCopy(CHUNKNUM chunkNum, void *buffer)
.proc _getChunkCopy

    ; caller's buffer
    ; save the caller's buffer on the stack
    pha
    txa
    pha

    ; blockNum and chunkNum
    jsr popax
    jsr _getChunk
    sta ptr1                ; source in ptr1
    stx ptr1 + 1

    ; Pull caller's buffer back off stack
    pla
    sta ptr2 + 1            ; dest in ptr2
    pla
    sta ptr2

    ; did _getChunk succeed?
    lda ptr1
    ora ptr1 + 1
    beq Failure

    ; Copy ptr1 to ptr2
    ldy #CHUNK_LEN - 1
L1:
    lda (ptr1),y
    sta (ptr2),y
    dey
    bpl L1
    jmp Done

Failure:
    lda #0
    ldx #0
    rts

Done:
    lda #1
    ldx #0
    rts

.endproc
