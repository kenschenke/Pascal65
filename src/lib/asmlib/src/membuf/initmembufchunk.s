;
; initmembufchunk.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; initMemBufChunk routine

.include "membufasm.inc"
.include "zeropage.inc"
.include "4510macros.inc"

.export initMemBufChunk

.import membufIsZero, heapAlloc

.bss

membufPtr: .res 4

.code

; This routine adds a new chunk to the membuf passed in Q.
; It does the following:
;    Allocate heap memory for the new chunk and set new chunk's nextChunk to null
;    If firstChunk is null, sets the new chunk as the first chunk
;    If currentChunk is non-null, sets the new chunk as the current chunk's nextChunk
;    Set currentChunk in the header to the new chunk
;    Update capacity in the membuf header
; Header passed in Q
.proc initMemBufChunk
    stq membufPtr
    ; Allocate memory for the chunk
    lda #.sizeof(MEMBUF_CHUNK)
    ldx #0
    jsr heapAlloc
    stq ptr2                ; Store the new chunk in ptr2
    ; Set new chunk's nextChunk to null
    lda #0
    ldz #MEMBUF_CHUNK::nextChunk+3
    ldx #3
:   nop
    sta (ptr2),z
    dez
    dex
    bpl :-
    ; Copy membufPtr back to ptr1
    ldq membufPtr
    stq ptr1
    ; Check if the membuf's firstChunk is null
    ldz #MEMBUF::firstChunk
    jsr membufIsZero
    bne L1          ; Branch if firstChunk is non-null
    ; Copy the new chunk's ptr to firstChunk
    ldz #MEMBUF::firstChunk+3
    ldx #3
:   lda ptr2,x
    nop
    sta (ptr1),z
    dez
    dex
    bpl :-
L1: ; Check if membuf's currentChunk is null
    ldz #MEMBUF::currentChunk
    jsr membufIsZero
    beq L2          ; Branch if currentChunk is null
    ; Since currentChunk is non-null, update that chunk's nextChunk pointer
    ; to point to the new chunk.
    ldz #MEMBUF::currentChunk
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr3        ; Store pointer to currentChunk in ptr3
    ldz #MEMBUF_CHUNK::nextChunk+3
    ldx #3
:   lda ptr2,x
    nop
    sta (ptr3),z
    dez
    dex
    bpl :-
L2: ; Set currentChunk in the header to point to the new chunk
    ldz #MEMBUF::currentChunk+3
    ldx #3
:   lda ptr2,x
    nop
    sta (ptr1),z
    dez
    dex
    bpl :-
    ; Add the new chunk to the membuf's capacity
    ldz #MEMBUF::capacity
    nop
    lda (ptr1),z
    clc
    adc #MEMBUF_CHUNK_LEN
    nop
    sta (ptr1),z
    inz
    nop
    lda (ptr1),z
    adc #0
    nop
    sta (ptr1),z
    rts
.endproc

