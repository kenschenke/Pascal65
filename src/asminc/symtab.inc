;;;
 ; symtab.inc
 ; Ken Schenke (kenschenke@gmail.com)
 ; 
 ; Symbol Table
 ; 
 ; Copyright (c) 2024
 ; Use of this source code is governed by an MIT-style
 ; license that can be found in the LICENSE file or at
 ; https://opensource.org/licenses/MIT
;;;

.include "chunks.inc"

.struct SYMTABNODE
    nodeChunkNum    .word
    leftChunkNum    .word
    rightChunkNum   .word
    nameChunkNum    .word
    nextNode        .word
    defnChunk       .word
    typeChunk       .word
    level           .word
    labelIndex      .word
    .res 5          ; unused space
.endstruct

.struct SYMBNODE
    node .res 23
    defn .res 23
    type .res 23
.endstruct

.if .sizeof(SYMTABNODE) <> CHUNK_LEN
    .error "SYMTABNODE must be CHUNK_LEN bytes in size"
.endif

.if .sizeof(SYMBNODE) <> CHUNK_LEN * 3
    .error "SYMBNODE must be CHUNK_LEN * 3 bytes in size"
.endif
