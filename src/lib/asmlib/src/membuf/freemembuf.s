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

.import heapFree, isQZero

.bss

hdrPtr: .res 4
nextChunkPtr: .res 4

.code

; Free a membuf, including the header and all chunks
; Pointer to the header passed in Q
.proc freeMemBuf
    ; Store the header pointer first
    stq hdrPtr
    stq ptr1

    ; Loop through the chunks
    ldz #MEMBUF::firstChunk
    neg
    neg
    nop
    lda (ptr1),z
L1: ; Check if next chunk is null
    jsr isQZero
    beq FH                      ; branch if null
    stq ptr1
    ; Copy the next chunk pointer to nextChunkPtr
    ldz #MEMBUF_CHUNK::nextChunk
    neg
    neg
    nop
    lda (ptr1),z
    stq nextChunkPtr
    ; Free the current chunk
    ldq ptr1
    jsr heapFree
    ldq nextChunkPtr
    bra L1
FH: ; Free the header
    ldq hdrPtr
    jsr heapFree
    rts
.endproc
