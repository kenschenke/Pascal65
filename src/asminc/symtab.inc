;;;
 ; symtab.inc
 ; Ken Schenke (kenschenke@gmail.com)
 ; 
 ; Symbol Table
 ; 
 ; Copyright (c) 2022
 ; Use of this source code is governed by an MIT-style
 ; license that can be found in the LICENSE file or at
 ; https://opensource.org/licenses/MIT
;;;

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

.if .sizeof(SYMTABNODE) <> CHUNK_LEN
    .error "SYMTABNODE must be CHUNK_LEN bytes in size"
.endif