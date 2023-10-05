;;;
 ; initChunkStorage.s
 ; Ken Schenke (kenschenke@gmail.com)
 ; 
 ; _initChunkStorage
 ; 
 ; Copyright (c) 2022
 ; Use of this source code is governed by an MIT-style
 ; license that can be found in the LICENSE file or at
 ; https://opensource.org/licenses/MIT
;;;

.include "blocks.inc"
.include "chunks.inc"

.import _currentBlock, _blockData, _FullBlocks, _availChunks, _getTotalBlocks
.importzp ptr1

.export _initChunkStorage

.bss

numBlocks: .res 2

.code

; void __fastcall__ initChunkStorage(void);
.proc _initChunkStorage

    ; Initialize currentBlock and blockData to 0

    lda #0
    sta _currentBlock
    sta _currentBlock + 1
    sta _blockData
    sta _blockData + 1

    ; Zero out the FullBlocks array

    lda #<MAX_BLOCKS
    sta numBlocks
    lda #>MAX_BLOCKS
    sta numBlocks + 1

    ; divide numBlocks by 8

    ldy #3
@L1:
    lsr numBlocks + 1
    ror numBlocks
    dey
    bne @L1

    ; Subtract one from numBlocks (for looping)
    jsr Sub1

    ; Loop through _FullBlocks

    lda #<_FullBlocks
    sta ptr1
    lda #>_FullBlocks
    sta ptr1 + 1

    ldy #0
@L2:
    lda #0
    sta (ptr1),y
    jsr Sub1
    lda numBlocks
    ora numBlocks + 1
    bne @L2

    ; Calculate avail chunks

    jsr _getTotalBlocks
    sta numBlocks
    stx numBlocks + 1
    lda #0
    sta _availChunks
    sta _availChunks + 1
@L3:
    clc
    lda _availChunks
    adc #CHUNKS_PER_BLOCK
    sta _availChunks
    lda _availChunks + 1
    adc #0
    sta _availChunks + 1
    jsr Sub1
    lda numBlocks
    ora numBlocks + 1
    bne @L3

    rts

.endproc

.proc Sub1
    sec
    lda numBlocks
    sbc #1
    sta numBlocks
    lda numBlocks + 1
    sbc #0
    sta numBlocks + 1
    rts
.endproc