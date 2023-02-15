;;;
 ; extractSymtabNode.s
 ; Ken Schenke (kenschenke@gmail.com)
 ; 
 ; Intermediate Code Storage and Retrieval
 ; 
 ; Copyright (c) 2022
 ; Use of this source code is governed by an MIT-style
 ; license that can be found in the LICENSE file or at
 ; https://opensource.org/licenses/MIT
;;;

.include "symtab.inc"

.export extractSymtabNode

.import _readFromMemBuf
.import pushax

; char extractSymtabNode(CHUNKNUM hdrChunkNum, CHUNKNUM *pChunkNum)
.proc extractSymtabNode
    ; hdrChunkNum is already on the parameter stack
    ; pChunkNum needs to be pushed on the parameter stack
    jsr pushax
    lda #2
    ldx #0
    jmp _readFromMemBuf
.endproc
