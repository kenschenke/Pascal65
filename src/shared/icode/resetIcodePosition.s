;;;
 ; resetIcodePosition.s
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

.export _resetIcodePosition

.import _cachedIcodeHdr, loadHeaderCache

; void resetIcodePosition(CHUNKNUM chunkNum)
.proc _resetIcodePosition
    ; chunknum is already in .A and .X
    jsr loadHeaderCache

    lda #0
    sta _cachedIcodeHdr + ICODE::currentChunkNum
    sta _cachedIcodeHdr + ICODE::posGlobal
    sta _cachedIcodeHdr + ICODE::posChunk

    rts
.endproc
