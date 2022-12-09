.import _writeToMemBuf, _setMemBufPos
.import popax, pushax

.export _copyToMemBuf

.bss

hdrChunkNum: .res 2
offset: .res 2
length: .res 2
buffer: .res 2

.code

; void copyToMemBuf(CHUNKNUM header, void *buffer, unsigned offset, unsigned length)
.proc _copyToMemBuf
    ; Store the fourth parameter
    sta length
    stx length + 1
    ; Store the third parameter
    jsr popax
    sta offset
    stx offset + 1
    ; Store the second parameter
    jsr popax
    sta buffer
    stx buffer + 1
    ; Store the first parameter
    jsr popax
    sta hdrChunkNum
    stx hdrChunkNum + 1

    ; Call setMemBufPos
    jsr pushax      ; hdrChunkNum is still in .A and .X
    lda offset
    ldx offset + 1
    jsr _setMemBufPos

    ; Call writeToMemBuf
    lda hdrChunkNum
    ldx hdrChunkNum + 1
    jsr pushax
    lda buffer
    ldx buffer + 1
    jsr pushax
    lda length
    ldx length
    jmp _writeToMemBuf
.endproc
