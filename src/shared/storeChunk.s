;;;
 ; storeChunk.s
 ; Ken Schenke (kenschenke@gmail.com)
 ; 
 ; _storeChunk
 ; 
 ; Copyright (c) 2022
 ; Use of this source code is governed by an MIT-style
 ; license that can be found in the LICENSE file or at
 ; https://opensource.org/licenses/MIT
;;;

.include "blocks.inc"
.include "chunks.inc"

.export _storeChunk
.import popax, _currentBlock, _isBlockAllocated, _storeBlock, _blockData, _retrieveBlock
.import __chunkGetBlock
.importzp ptr1, ptr2, tmp1

blockNum:
    .byte 0
chunkNum:
    .byte 0
buffer:
    .byte 0, 0

; char storeChunk(CHUNKNUM chunkNum, unsigned char *bytes)
.proc _storeChunk

    ; caller's buffer
    sta buffer
    stx buffer+1

    ; chunkNum
    jsr popax
    sta chunkNum
    stx blockNum

    ; is chunkNum < 1 or > CHUNKS_PER_BLOCK
    cmp #1
    bmi @F1
    cmp #CHUNKS_PER_BLOCK + 1
    bpl @F1

    ; is blockNum < 1 or > TOTAL_BLOCKS 
    cpx #1
    bmi @F1
    cpx #TOTAL_BLOCKS + 1
    bpl @F1

    ; is blockNum allocated?
    lda blockNum
    jsr _isBlockAllocated
    cmp #0
    bne CheckBlock

@F1:
    jmp Failure

CheckBlock:
    ; Do we have a current block?
    lda _currentBlock
    beq GetBlock            ; no

    ; Is the chunk in a different block?
    cmp blockNum
    beq StoreChunk          ; no

    ; Store the current block
    jsr _storeBlock
    cmp #0
    beq Failure
    lda #0
    sta _currentBlock

GetBlock:
    ; Retrieve the block we need
    lda blockNum
    jsr __chunkGetBlock
    bne StoreChunk
    jmp Failure             ; retrieveBlock returned NULL

StoreChunk:
    ; Start off with the pointer to the block data
    lda _blockData
    sta ptr1
    lda _blockData+1
    sta ptr1+1
    ; Move past the chunk allocation table at the beginning of the block
    lda #CHUNKS_PER_BLOCK
    sta tmp1
    jsr AddTmp1
    ; Now move past the other chunks in this block
    lda #CHUNK_LEN
    sta tmp1
    ldx chunkNum
@Loop:
    dex
    beq @Cpy
    jsr AddTmp1
    jmp @Loop
@Cpy:
    ldx #CHUNK_LEN
    ldy #0
    lda buffer
    sta ptr2
    lda buffer+1
    sta ptr2+1
@CpyLoop:
    lda (ptr2),y
    sta (ptr1),y
    iny
    dex
    beq Done
    jmp @CpyLoop

AddTmp1:
    clc
    lda ptr1
    adc tmp1
    sta ptr1
    lda ptr1+1
    adc #0
    sta ptr1+1
    rts

Failure:
    lda #0
    ldx #0
    rts

Done:
    lda #1
    ldx #0
    rts

.endproc
