;;;
 ; getCurrentIcodeLocation.s
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

.export _getCurrentIcodeLocation

.import loadHeaderCache, _cachedIcodeHdr

; unsigned getCurrentIcodeLocation(CHUNKNUM chunkNum)
.proc _getCurrentIcodeLocation
    ; Retrieve the cached header block
    ; .A and .X already contain the chunkNum
    jsr loadHeaderCache

    ; Return the global position in .A and .X
    lda _cachedIcodeHdr + ICODE::posGlobal
    ldx _cachedIcodeHdr + ICODE::posGlobal + 1
    rts
.endproc
