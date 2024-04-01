;;;
 ; retrieveChunk.s
 ; Ken Schenke (kenschenke@gmail.com)
 ; 
 ; _retrieveChunk
 ; 
 ; Copyright (c) 2024
 ; Use of this source code is governed by an MIT-style
 ; license that can be found in the LICENSE file or at
 ; https://opensource.org/licenses/MIT
;;;

.include "blocks.inc"
.include "chunks.inc"

.export _retrieveChunk
.import _getChunkCopy

.proc _retrieveChunk
    jmp _getChunkCopy
.endproc
