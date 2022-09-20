;;;
 ; chunkGetBlock.s
 ; Ken Schenke (kenschenke@gmail.com)
 ; 
 ; __chunkGetBlock
 ; 
 ; Copyright (c) 2022
 ; Use of this source code is governed by an MIT-style
 ; license that can be found in the LICENSE file or at
 ; https://opensource.org/licenses/MIT
;;;

.export __chunkGetBlock

.import _currentBlock, _retrieveBlock, _blockData

; BlockNum pass in .A
; Non-zero returned in .A on success, zero on failure
__chunkGetBlock:
    sta _currentBlock
    jsr _retrieveBlock
    sta _blockData          ; store the block data pointer
    stx _blockData+1
    bne @Done               ; is the low byte 0?
    lda _blockData
    bne @Done               ; is the high byte 0 too?
    
    ; retrieveBlock returned NULL
    lda #0
    rts

@Done:
    lda #1
    rts
