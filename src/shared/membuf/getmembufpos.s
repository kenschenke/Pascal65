;;;
 ; getmembufpos.s
 ; Ken Schenke (kenschenke@gmail.com)
 ; 
 ; Copyright (c) 2024
 ; Use of this source code is governed by an MIT-style
 ; license that can be found in the LICENSE file or at
 ; https://opensource.org/licenses/MIT
;;;

.include "membuf.inc"

.import loadMemBufHeaderCache, _cachedMemBufHdr

.export _getMemBufPos

; unsigned getMemBufPos(CHUNKNUM header)
.proc _getMemBufPos
    ; Call loadMemBufHeaderCache
    ; chunknum already in .A and .X
    jsr loadMemBufHeaderCache

    ; Return the current position
    lda _cachedMemBufHdr + MEMBUF::posGlobal
    ldx _cachedMemBufHdr + MEMBUF::posGlobal + 1
    rts
.endproc
