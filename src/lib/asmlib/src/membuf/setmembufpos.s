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

.export setMemBufPos

.import ltUint16, subInt16

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
    ; Copy the firstChunk pointer to ptr2
    ldz #MEMBUF::firstChunk+3
    ldx #3
:   nop
    lda (ptr1),z
    sta ptr2,x
    dez
    dex
    bpl :-
    ; Reset the global position
    ldz #MEMBUF::posGlobal
    lda #0
    nop
    sta (ptr1),z
    inz
    nop
    sta (ptr1),z
    ; Loop through the chunks until we find the chunk for the requested position
L1: ; Is intOp1 < intOp2 (remaining < chunk length)?
    jsr ltUint16
    cmp #0
    bne LT                  ; Branch if intOp1 < intOp2
    ; Subtract chunk length from remaining seek position
    jsr subInt16            ; intOp1 now containins remaining bytes to seek
    ; Copy next chunk pointer to ptr3
    ldz #MEMBUF_CHUNK::nextChunk+3
    ldx #3
:   nop
    lda (ptr2),z
    sta ptr3,x
    dez
    dex
    bpl :-
    ; Now copy ptr3 to ptr2
    ldx #3
:   lda ptr3,x
    sta ptr2,x
    dex
    bpl :-
    bne L1
    ; Done
    ; Store the remaining seek position in posChunk
LT: ldz #MEMBUF::posChunk
    lda intOp1
    nop
    sta (ptr1),z
    ; Store the current chunk ptr (ptr2) into the membuf currentChunk ptr
    ldz #MEMBUF::currentChunk
    lda ptr2
    nop
    sta (ptr1),z
    lda ptr2+1
    inz
    nop
    sta (ptr1),z
    ; Copy tmp1/tmp2 to the posGloal in the membuf header
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
