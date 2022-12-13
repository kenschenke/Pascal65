;;;
 ; resetIcodePosition.s
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

.export _resetMemBufPosition

.import _cachedMemBufHdr, loadMemBufHeaderCache

; void resetMemBufPosition(CHUNKNUM chunkNum)
.proc _resetMemBufPosition
    ; chunknum is already in .A and .X
    jsr loadMemBufHeaderCache

    lda #0
    sta _cachedMemBufHdr + MEMBUF::currentChunkNum
    sta _cachedMemBufHdr + MEMBUF::currentChunkNum + 1
    sta _cachedMemBufHdr + MEMBUF::posGlobal
    sta _cachedMemBufHdr + MEMBUF::posGlobal + 1
    sta _cachedMemBufHdr + MEMBUF::posChunk
    sta _cachedMemBufHdr + MEMBUF::posChunk + 1

    rts
.endproc
