;;;
 ; initIcodeCache.s
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

.export _initIcodeCache

.import _cachedIcodeHdrChunkNum, _cachedIcodeDataChunkNum

; void initIcodeCache(void)
.proc _initIcodeCache
    lda #0
    sta _cachedIcodeHdrChunkNum
    sta _cachedIcodeHdrChunkNum + 1
    sta _cachedIcodeDataChunkNum
    sta _cachedIcodeDataChunkNum + 1
    rts
.endproc
