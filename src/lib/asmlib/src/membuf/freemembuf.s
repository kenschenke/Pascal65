;
; freemembuf.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; freeMemBuf routine

.include "membufasm.inc"
.include "zeropage.inc"
.include "4510macros.inc"

.export freeMemBuf

.import heapFree

.bss

hdrPtr: .res 4
chunkPtr: .res 4
nextChunkPtr: .res 4

.code

; Free a membuf, including the header and all chunks
; Pointer to the header passed in Q
.proc freeMemBuf
    ; Store the header pointer first
    stq hdrPtr
    stq ptr1

    ; Loop through the chunks
    ldz #MEMBUF::firstChunk+3
    ldx #3
:   nop
    lda (ptr1),z                ; Copy the firstChunk ptr to chunkPtr
    sta chunkPtr,x
    dez
    dex
    bpl :-
L1: ; Check if chunkPtr is zero
    lda chunkPtr
    ora chunkPtr+1
    ora chunkPtr+2
    ora chunkPtr+3
    beq FH                      ; branch chunkPtr is zero
    ; Put the current chunk pointer in ptr1
    ldq chunkPtr
    stq ptr1
    ; Copy the next chunk pointer to nextChunkPtr
    ldz #MEMBUF_CHUNK::nextChunk+3
    ldx #3
:   nop
    lda (ptr1),z
    sta nextChunkPtr,x
    dez
    dex
    bpl :-
    ; Free the current chunk
    ldq chunkPtr
    jsr heapFree
    ; Copy nextChunkPtr to chunkPtr
    ldx #3
:   lda nextChunkPtr,x
    sta chunkPtr,x
    dex
    bpl :-
    bne L1
FH: ; Free the header
    ldq hdrPtr
    jmp heapFree
.endproc
