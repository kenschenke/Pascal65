;
; writetomembuf.s
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; writeToMemBuf routine

.include "membufasm.inc"
.include "zeropage.inc"
.include "4510macros.inc"

.export writeToMemBuf

.import initMemBufChunk, membufIsZero, ltUint16, isQZero

.bss

callerPtr: .res 4
membufPtr: .res 4
dataSize: .res 2
toCopy: .res 1

.code

; Writes bytes to the membuf at its position, overwriting what is there and
; adding chunks as needed. The position moves past the bytes, and used grows
; to the position if it is past it.
; Membuf header is in ptr1
; Caller's buffer is in ptr2
; Length to write passed in A/X
.proc writeToMemBuf
    ; Store length
    sta dataSize
    stx dataSize+1
    ; Store membufPtr
    ldq ptr1
    stq membufPtr
    ; Store callerPtr
    ldq ptr2
    stq callerPtr
    ; A membuf with no chunks gets its first one, which initMemBufChunk
    ; makes the current chunk. A membuf with chunks always has a current
    ; chunk (see setMemBufPos).
    ldz #MEMBUF::firstChunk
    jsr membufIsZero
    bne L1              ; Branch if firstChunk is non-null
    ldq membufPtr
    jsr initMemBufChunk ; Allocate the first chunk
    ldq membufPtr
    stq ptr1
L1: ; Loop until length is zero
    lda dataSize
    ora dataSize+1
    bne L11
    jmp DN
L11:
    ; Calculate # of bytes to copy and put in toCopy
    ; if (length > MEMBUF_CHUNK_LEN - hdr.posChunk)
    ;    toCopy = MEMBUF_CHUNK_LEN - hdr.posChunk
    ; else
    ;    toCopy = length
    lda #MEMBUF_CHUNK_LEN
    ldz #MEMBUF::posChunk
    sec
    nop
    sbc (ptr1),z
    sta toCopy
    lda dataSize+1
    bne L2                  ; high byte of dataSize is non-zero. definitely bigger.
    lda toCopy              ; if length > toCopy
    cmp dataSize
    bcc L2
    ; length <= MEMBUF_CHUNK_LEN - posChunk
    lda dataSize
    sta toCopy
L2: ; ptr2 is the caller's data buffer
    ldq callerPtr
    stq ptr2
    lda toCopy
    bne :+
    jmp NX                  ; The current chunk is full
    ; ptr3 is the membuf data buffer: currentChunk + data + posChunk
:   ldz #MEMBUF::currentChunk
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr3
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
    ; Copy the bytes
    ldz #0
:   nop
    lda (ptr2),z
    nop
    sta (ptr3),z
    inz
    cpz toCopy
    bne :-
    ; Move posChunk forward by toCopy
    ldz #MEMBUF::posChunk
    nop
    lda (ptr1),z
    clc
    adc toCopy
    nop
    sta (ptr1),z
    ; Move posGlobal forward by toCopy
    ldz #MEMBUF::posGlobal
    nop
    lda (ptr1),z
    clc
    adc toCopy
    nop
    sta (ptr1),z
    inz
    nop
    lda (ptr1),z
    adc #0
    nop
    sta (ptr1),z
    ; Decrease length by toCopy
    lda dataSize
    sec
    sbc toCopy
    sta dataSize
    lda dataSize+1
    sbc #0
    sta dataSize+1
    ; If length is zero, we're done
    lda dataSize
    ora dataSize+1
    beq DN
NX: ; Move callerPtr past the bytes copied. The rest go in the next chunk,
    ; whether it is new or already there.
    lda toCopy
    sta intOp32
    lda #0
    sta intOp32+1
    sta intOp32+2
    sta intOp32+3
    ldq callerPtr
    clc
    adcq intOp32
    stq callerPtr
    ; Check if the next chunk is already allocated
    ldz #MEMBUF::currentChunk
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr3
    ldz #MEMBUF_CHUNK::nextChunk
    neg
    neg
    nop
    lda (ptr3),z
    jsr isQZero
    bne L3
    ; nextChunk is null - allocate a new chunk. initMemBufChunk links it
    ; after the current chunk and makes it the current chunk.
    ldq membufPtr
    jsr initMemBufChunk
    ldq membufPtr
    stq ptr1
    bra L4
L3: stq ptr4
    ldz #MEMBUF::currentChunk+3
    ldx #3
:   lda ptr4,x
    nop
    sta (ptr1),z
    dez
    dex
    bpl :-
L4: ; Set posChunk in header to zero
    ldz #MEMBUF::posChunk
    lda #0
    nop
    sta (ptr1),z
    jmp L1
DN: ; If used < posGlobal then set used to posGlobal
    ldz #MEMBUF::used
    nop
    lda (ptr1),z
    sta intOp1
    inz
    nop
    lda (ptr1),z
    sta intOp1+1
    ldz #MEMBUF::posGlobal
    nop
    lda (ptr1),z
    sta intOp2
    inz
    nop
    lda (ptr1),z
    sta intOp2+1
    jsr ltUint16
    beq L5
    ; Copy posGlobal to used
    ldz #MEMBUF::posGlobal
    neg
    neg
    nop
    lda (ptr1),z
    ldz #MEMBUF::used
    nop
    sta (ptr1),z
    txa
    inz
    nop
    sta (ptr1),z
L5: rts
.endproc
