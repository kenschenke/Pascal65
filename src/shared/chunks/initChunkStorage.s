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

.import _currentBlock, _blockData

.export _initChunkStorage

; void __fastcall__ initChunkStorage(void);
.proc _initChunkStorage

    ; Initialize currentBlock and blockData to 0

    lda #0
    sta _currentBlock
    sta _blockData
    sta _blockData+1

    rts

.endproc
