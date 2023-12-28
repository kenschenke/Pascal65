;;;
 ; membuf.inc
 ; Ken Schenke (kenschenke@gmail.com)
 ; 
 ; Memory Buffer Storage and Retrieval
 ; 
 ; Copyright (c) 2022
 ; Use of this source code is governed by an MIT-style
 ; license that can be found in the LICENSE file or at
 ; https://opensource.org/licenses/MIT
;;;

.include "chunks.inc"

MEMBUF_CHUNK_LEN = CHUNK_LEN - 2
CHUNKS_PER_INDEX = 10
BYTES_PER_INDEX = 21 * CHUNKS_PER_INDEX
; CAUTION - setMemBufPos depends on BYTES_PER_INDEX being
; less than 256.

.struct MEMBUF
    firstChunkNum   .word
    currentChunkNum .word
    posGlobal       .word
    posChunk        .word
    capacity        .word       ; storage capacity of allocated chunks
    used            .word       ; total bytes stored in buffer
    firstIndexChunk .word       ; first index chunk
    .res 9         ; unused space
.endstruct

; To speed up seeking within a memory buffer, an index of the chunks
; is stored.  firstIndexChunk in the header links to the first group.
; Each group contains the chunkNum of chunks within the buffer.
; CHUNKS_PER_INDEX defines the number 

.if .sizeof(MEMBUF) <> CHUNK_LEN
    .error "MEMBUF must be CHUNK_LEN bytes in size"
.endif

.struct MEMBUF_CHUNK
    nextChunk       .word
    data            .byte
    .res 20         ; remained of data block
.endstruct

.if .sizeof(MEMBUF_CHUNK) <> CHUNK_LEN
    .error "MEMBUF_CHUNK must be CHUNK_LEN bytes in size"
.endif

.struct MEMBUF_LOCN
    chunkNum        .word
    posGlobal       .word
    posChunk        .word
.endstruct
