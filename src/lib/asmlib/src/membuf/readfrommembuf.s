;
; readfrommembuf.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; readFromMemBuf routine

.include "membufasm.inc"
.include "zeropage.inc"
.include "4510macros.inc"

.export readFromMemBuf, membufIsZero

.import subInt16

; Reads bytes from the membuf.
; Membuf header is in ptr1
; Caller's buffer is in ptr2
; Length to read passed in A/X
.proc readFromMemBuf
    ; Store length in intOp1
    sta intOp1
    stx intOp1+1
    ; If firstChunkNum is zero, bail out
    ldz #MEMBUF::firstChunk
    jsr membufIsZero
    bne :+
    jmp DN
    ; If currentChunk is zero, set it to firstChunk
:   ldz #MEMBUF::currentChunk
    jsr membufIsZero
    bne L1
    ; Copy firstChunk to currentChunk
    ldz #MEMBUF::firstChunk
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr3
    ldz #MEMBUF::currentChunk+3
    ldx #3
:   lda ptr3,x
    nop
    sta (ptr1),z
    dez
    dex
    bpl :-
    ; Loop until intOp1 is zero
L1: ; Is intOp1 zero?
    lda intOp1
    ora intOp1+1
    bne :+                 ; Branch if intOp1 (remaining length) is zero
    jmp DN
    ; Calculate # of bytes to copy and put it in tmp1
    ; if (length > MEMBUF_CHUNK_LEN - hdr.posChunk)
    ;    toCopy = MEMBUF_CHUNK_LEN - hdr.posChunk
    ; else
    ;    toCopy = length
:   lda #MEMBUF_CHUNK_LEN
    ldz #MEMBUF::posChunk
    sec
    nop
    sbc (ptr1),z
    sta tmp1                ; Assume we're copying MEMBUF_CHUNK_LEN - posChunk
    lda intOp1+1            ; high byte of remaining length is non-zero. definitely bigger
    bne L2                  ; branch if high byte is non-zero
    lda tmp1
    cmp intOp1
    bcc L2                  ; low byte of length > MEMBUF_CHUNK_LEN - posChunk
    ; length <= MEMBUF_CHUNK_LEN - posChunk
    lda intOp1
    sta tmp1
L2: ; Copy tmp1 to intOp2
    lda tmp1
    sta intOp2
    lda #0
    sta intOp2+1
    ; Copy currentChunk to ptr3 and ptr4
    ldz #MEMBUF::currentChunk
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr3
    stq ptr4
    ; Add posChunk and data offset to ptr3
    ldz #MEMBUF::posChunk
    nop
    lda (ptr1),z
    clc
    adc #MEMBUF_CHUNK::data
    sta intOp32
    lda #0
    sta intOp32+1
    sta intOp32+2
    sta intOp32+3
    ldq ptr3
    clc
    adcq intOp32
    stq ptr3
    ; Copy bytes until tmp1 is zero
    ldz #0
    lda tmp1
    beq L4                  ; skip ahead of tmp1 is zero
L3: nop
    lda (ptr3),z
    nop
    sta (ptr2),z
    inz
    dec tmp1
    bne L3
    ; Move posChunk forward by toCopy
    ldz #MEMBUF::posChunk
    nop
    lda (ptr1),z
    clc
    adc intOp2
    nop
    sta (ptr1),z
    ; Move posGlobal forward by toCopy
    ldz #MEMBUF::posGlobal
    nop
    lda (ptr1),z
    clc
    adc intOp2
    nop
    sta (ptr1),z
    inz
    nop
    lda (ptr1),z
    adc #0
    nop
    sta (ptr1),z
    ; Add toCopy to ptr2
    lda #0
    tax
    tay
    taz
    lda intOp2
    clc
    adcq ptr2
    stq ptr2
    ; Subtract intOp2 from intOp1 (length - toCopy)
    jsr subInt16
    ; If length is zero we're done
L4: lda intOp1
    ora intOp1+1
    beq DN
    ; If there's no nextChunk, we're done
    ldz #MEMBUF_CHUNK::nextChunk
    ldx #3
    nop
    lda (ptr4),z
    inz
:   nop
    ora (ptr4),z
    inz
    dex
    bne :-
    ora #0
    beq DN
    ; Set posChunk to 0
    ldz #MEMBUF::posChunk
    lda #0
    nop
    sta (ptr1),z
    ; Set currentChunk in header to nextChunk
    ldz #MEMBUF_CHUNK::nextChunk
    neg
    neg
    nop
    lda (ptr4),z
    stq ptr4
    ldz #MEMBUF::currentChunk+3
    ldx #3
:   lda ptr4,x
    nop
    sta (ptr1),z        ; Store it in currentChunk
    dez
    dex
    bpl :-
    jmp L1
DN: rts
.endproc

; This routine tests if a pointer in the MEMBUF structure is all zeros.
; Z contains offset of pointer field
; On exit, zero flag is 0 if pointer was null
.proc membufIsZero
    ldx #0
    nop
    lda (ptr1),z
    bne DN          ; Branch if non-zero
:   inz
    nop
    ora (ptr1),z    ; Load next byte in pointer
    bne DN          ; Branch if non-zero
    inx
    cpx #3          ; Is X now 3?
    bne :-          ; Branch back up if X != 3
    lda #0          ; All bytes were zero, clear zero flag
DN: rts
.endproc
