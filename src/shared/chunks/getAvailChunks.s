;;;
 ; getAvailChunks.s
 ; Ken Schenke (kenschenke@gmail.com)
 ; 
 ; _getAvailChunks
 ; 
 ; Copyright (c) 2022
 ; Use of this source code is governed by an MIT-style
 ; license that can be found in the LICENSE file or at
 ; https://opensource.org/licenses/MIT
;;;

.include "chunks.inc"

.export _getAvailChunks
.import _availChunks

; int getAvailChunks(void)
.proc _getAvailChunks

    lda _availChunks
    ldx _availChunks + 1
    rts

.endproc
