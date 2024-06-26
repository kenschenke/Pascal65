;;;
 ; storeChunk.s
 ; Ken Schenke (kenschenke@gmail.com)
 ; 
 ; _storeChunk
 ; 
 ; Copyright (c) 2024
 ; Use of this source code is governed by an MIT-style
 ; license that can be found in the LICENSE file or at
 ; https://opensource.org/licenses/MIT
;;;

.include "blocks.inc"
.include "chunks.inc"

.export _storeChunk
.import popax, _currentBlock, _storeBlock, _blockData, _retrieveBlock
.import __chunkGetBlock, extractBlockAndChunkNum
.importzp ptr1, ptr2, tmp1

.bss

blockNum: .res 2
chunkNum: .res 1
buffer: .res 2

.code

; char storeChunk(CHUNKNUM chunkNum, unsigned char *bytes)
.proc _storeChunk

    ; caller's buffer
    sta buffer
    stx buffer + 1

    ; chunkNum
    jsr popax
    jsr extractBlockAndChunkNum
    sta blockNum
    stx blockNum + 1
    dey
    sty chunkNum

    ; Do we have a current block?
    lda _blockData
    ora _blockData + 1
    beq GetBlock            ; no

@StoreCurrentBlock:
    ; Store the current block
    lda _currentBlock
    ldx _currentBlock + 1
    jsr _storeBlock
    cmp #0
    beq Failure
    lda #0
    sta _currentBlock
    sta _currentBlock + 1

GetBlock:
    ; Retrieve the block we need
    lda blockNum
    ldx blockNum + 1
    jsr __chunkGetBlock
    cmp #0
    bne StoreChunk
    jmp Failure             ; retrieveBlock returned NULL

StoreChunk:
    ; Start off with the pointer to the block data
    lda _blockData
    sta ptr1
    lda _blockData + 1
    sta ptr1+1
    ; Move past the chunk allocation table at the beginning of the block
    lda #2
    sta tmp1
    jsr AddTmp1
    ; Now move past the other chunks in this block
    lda #CHUNK_LEN
    sta tmp1
    ldx chunkNum
@Loop:
    beq @Cpy
    jsr AddTmp1
    dex
    bne @Loop
@Cpy:
    ldx #CHUNK_LEN
    ldy #0
    lda buffer
    sta ptr2
    lda buffer + 1
    sta ptr2 + 1
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
