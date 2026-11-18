;
; setmembufpos.s
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; setMemBufPos routine

.include "membufasm.inc"
.include "zeropage.inc"
.include "4510macros.inc"

.export setMemBufPos

.import isQZero, subInt16

; Sets the membuf's position: its current chunk, the position in that chunk
; and posGlobal.
;
; A position at the end of a chunk is in that chunk, with posChunk at
; MEMBUF_CHUNK_LEN, so a position at the end of the last chunk (capacity)
; still has a current chunk. The read and write routines move to the next
; chunk from there. A position past the last chunk is taken as capacity.
; A membuf with no chunks gets position 0 and no current chunk.
;
; Membuf pointer in ptr1
; New position in A/X
.proc setMemBufPos
    ; Store the seek position in intOp1 and tmp1/tmp2
    sta intOp1                      ; intOp1: remaining bytes to seek
    stx intOp1+1
    sta tmp1
    stx tmp2
    ; Store the size of each chunk in intOp2
    lda #MEMBUF_CHUNK_LEN
    sta intOp2
    lda #0
    sta intOp2+1
    ; Start at the first chunk, in ptr2
    ldz #MEMBUF::firstChunk
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr2
    jsr isQZero
    bne L1                  ; Branch if there is a first chunk
    ; No chunks: position 0, and currentChunk stays null
    sta intOp1
    sta tmp1
    sta tmp2
    bra LT
    ; Loop through the chunks until the remaining position is in this one
L1: lda intOp1+1
    bne NC                  ; Branch if remaining > MEMBUF_CHUNK_LEN
    lda #MEMBUF_CHUNK_LEN
    cmp intOp1
    bcs LT                  ; Branch if remaining <= MEMBUF_CHUNK_LEN
NC: ; Move to the next chunk
    ldz #MEMBUF_CHUNK::nextChunk
    neg
    neg
    nop
    lda (ptr2),z
    jsr isQZero
    beq CP                  ; Branch if this is the last chunk
    stq ptr2
    jsr subInt16            ; remaining -= MEMBUF_CHUNK_LEN
    bra L1
CP: ; Past the last chunk: the end of it, at capacity
    lda #MEMBUF_CHUNK_LEN
    sta intOp1
    ldz #MEMBUF::capacity
    nop
    lda (ptr1),z
    sta tmp1
    inz
    nop
    lda (ptr1),z
    sta tmp2
LT: ; Store the remaining seek position in posChunk
    ldz #MEMBUF::posChunk
    lda intOp1
    nop
    sta (ptr1),z
    ; Store the current chunk ptr (ptr2) into the membuf currentChunk ptr
    ldz #MEMBUF::currentChunk
    ldx #0
:   lda ptr2,x
    nop
    sta (ptr1),z
    inz
    inx
    cpx #4
    bne :-
    ; Copy tmp1/tmp2 to the posGlobal in the membuf header
    ldz #MEMBUF::posGlobal
    lda tmp1
    nop
    sta (ptr1),z
    lda tmp2
    inz
    nop
    sta (ptr1),z
    rts
.endproc
