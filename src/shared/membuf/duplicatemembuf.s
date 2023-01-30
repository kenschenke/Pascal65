.include "membuf.inc"

.import popax, pushax, _allocChunk, _retrieveChunk, _storeChunk
.importzp ptr1, tmp1, tmp2

.export _duplicateMemBuf

.bss

oldChunkNum: .res 2
newChunkNum: .res 2
chunk: .res CHUNK_LEN

.code

.proc _duplicateMemBuf
    sta newChunkNum
    stx newChunkNum + 1
    jsr popax
    sta oldChunkNum
    stx oldChunkNum + 1

    ; Clear tmp1/tmp2 : used to store new header chunknum
    lda #0
    sta tmp1
    sta tmp2

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; The only thing left is to store the header chunknum
    ; in newChunkNum
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ; Load the next chunk, starting with the header
L1:
    lda oldChunkNum         ; Check if oldChunkNum is zero
    ora oldChunkNum + 1 
    beq L3                 ; It's zero, return
    ; Load the chunk
    lda oldChunkNum
    ldx oldChunkNum + 1
    jsr pushax
    lda #<chunk
    ldx #>chunk
    jsr _retrieveChunk
    ; Save the next chunk number on the stack
    lda chunk
    pha
    lda chunk + 1
    pha
    ; Save the old chunk number on the stack
    lda oldChunkNum
    pha
    lda oldChunkNum + 1
    pha
    ; Allocate a new chunk
    lda #<oldChunkNum
    ldx #>oldChunkNum
    jsr _allocChunk
    ; If tmp1/tmp2 is zero, this is the header.  Save the chunknum
    lda tmp1
    ora tmp2
    bne L2
    ; Save the chunknum
    lda newChunkNum
    sta ptr1
    lda newChunkNum + 1
    sta ptr1 + 1
    ldy #0
    lda oldChunkNum
    sta tmp1
    sta (ptr1),y
    iny
    lda oldChunkNum + 1
    sta tmp2
    sta (ptr1),y
L2:
    ; Save the new chunk number in the first two bytes of the chunk
    lda oldChunkNum
    sta chunk
    lda oldChunkNum + 1
    sta chunk + 1
    ; Pull the old chunk number off the stack
    pla
    tax
    pla
    ; Store the chunk
    jsr pushax
    lda #<chunk
    ldx #>chunk
    jsr _storeChunk
    ; Pull the next chunk number off the stack
    pla
    sta oldChunkNum + 1
    pla
    sta oldChunkNum
    jmp L1

L3:
    rts
.endproc
