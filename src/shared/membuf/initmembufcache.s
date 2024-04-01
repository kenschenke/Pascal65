;;;
 ; initMemBufCache.s
 ; Ken Schenke (kenschenke@gmail.com)
 ; 
 ; Memory Buffer Storage and Retrieval
 ; 
 ; Copyright (c) 2024
 ; Use of this source code is governed by an MIT-style
 ; license that can be found in the LICENSE file or at
 ; https://opensource.org/licenses/MIT
;;;

.include "membuf.inc"

.export _initMemBufCache

.import _cachedMemBufHdrChunkNum, _cachedMemBufDataChunkNum

; void initMemBufCache(void)
.proc _initMemBufCache
    lda #0
    sta _cachedMemBufHdrChunkNum
    sta _cachedMemBufHdrChunkNum + 1
    sta _cachedMemBufDataChunkNum
    sta _cachedMemBufDataChunkNum + 1
    rts
.endproc
