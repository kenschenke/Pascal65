;;;
 ; icode.inc
 ; Ken Schenke (kenschenke@gmail.com)
 ; 
 ; Intermediate Code Storage and Retrieval
 ; 
 ; Copyright (c) 2022
 ; Use of this source code is governed by an MIT-style
 ; license that can be found in the LICENSE file or at
 ; https://opensource.org/licenses/MIT
;;;

.include "chunks.inc"

ICODE_CHUNK_LEN = CHUNK_LEN - 2

.struct ICODE
    firstChunkNum   .word
    currentChunkNum .word
    posGlobal       .word
    posChunk        .word
    .res 15         ; unused space
.endstruct

.if .sizeof(ICODE) <> CHUNK_LEN
    .error "ICODE must be CHUNK_LEN bytes in size"
.endif

.struct ICODE_CHUNK
    nextChunk       .word
    data            .byte
    .res 20         ; remained of data block
.endstruct

.if .sizeof(ICODE_CHUNK) <> CHUNK_LEN
    .error "ICODE_CHUNK must be CHUNK_LEN bytes in size"
.endif
