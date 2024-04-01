;;;
 ; ismembufatend.s
 ; Ken Schenke (kenschenke@gmail.com)
 ; 
 ; __chunkGetBlock
 ; 
 ; Copyright (c) 2024
 ; Use of this source code is governed by an MIT-style
 ; license that can be found in the LICENSE file or at
 ; https://opensource.org/licenses/MIT
;;;

.include "membuf.inc"

.import loadMemBufHeaderCache, _cachedMemBufHdr

.export _isMemBufAtEnd

; char isMemBufAtEnd(CHUNKNUM header)
.proc _isMemBufAtEnd
    ; Call loadMemBufHeaderCache
    ; chunknum already in .A and .X
    jsr loadMemBufHeaderCache

    ; Compare the high bytes first
    lda _cachedMemBufHdr + MEMBUF::posGlobal + 1
    cmp _cachedMemBufHdr + MEMBUF::used + 1
    bcc L1
    bne L2

    ; Compare the low bytes
    lda _cachedMemBufHdr + MEMBUF::posGlobal
    cmp _cachedMemBufHdr + MEMBUF::used
    bcs L2

L1:
    lda #0
    ldx #0
    rts

L2:
    lda #1
    ldx #0
    rts
.endproc
