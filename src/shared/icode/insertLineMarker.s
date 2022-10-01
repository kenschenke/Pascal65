;;;
 ; insertLineMarker.s
 ; Ken Schenke (kenschenke@gmail.com)
 ; 
 ; Intermediate Code Storage and Retrieval
 ; 
 ; Copyright (c) 2022
 ; Use of this source code is governed by an MIT-style
 ; license that can be found in the LICENSE file or at
 ; https://opensource.org/licenses/MIT
;;;

.include "icode.inc"
.include "error.inc"

.export _insertLineMarker

.import _checkIcodeBounds, _gotoIcodePosition, loadDataCache, loadHeaderCache
.import putDataToIcode
.import _cachedIcodeData, _cachedIcodeHdr, _currentLineNumber, _mcLineMarker
.import _errorCount
.import pushax
.importzp ptr1

.bss

lastCode: .res 1
hdrChunkNum: .res 2
pos: .res 2

.code

; void insertLineMarker(CHUNKNUM hdrChunkNum)
.proc _insertLineMarker
    ; Save the parameter
    sta hdrChunkNum
    stx hdrChunkNum + 1

    ; If errorCount is non-zero, bail
    lda _errorCount
    ora _errorCount + 1
    bne @JmpDone

    ; Load the header from cache
    lda hdrChunkNum
    ldx hdrChunkNum + 1
    jsr loadHeaderCache

    ; Remember the last appended token

    ; Are we at the beginning of the chunk already?
    lda _cachedIcodeHdr + ICODE::posChunk
    bne @BackUpPos
    ; Yes.  Are we also at the start of the icode?
    lda _cachedIcodeHdr + ICODE::posGlobal
    ora _cachedIcodeHdr + ICODE::posGlobal + 1
    beq @JmpDone  ; yes - can't back up any more

    ; We are at the start of the chunk already.
    ; We will need to load the previous chunk.
    lda _cachedIcodeHdr + ICODE::posGlobal
    sta pos
    lda _cachedIcodeHdr + ICODE::posGlobal + 1
    sta pos + 1
    ; Subtract 1 from the pos
    sec
    lda pos
    sbc #1
    sta pos
    lda pos + 1
    sbc #0
    sta pos
    ; Call gotoIcodePosition
    lda pos
    ldx pos + 1
    jsr pushax
    lda hdrChunkNum
    ldx hdrChunkNum + 1
    jsr _gotoIcodePosition
    jmp @GetLastToken

@JmpDone:
    jmp @Done

@BackUpPos:
    dec _cachedIcodeHdr + ICODE::posChunk
    sec
    lda _cachedIcodeHdr + ICODE::posGlobal
    sbc #1
    sta _cachedIcodeHdr + ICODE::posGlobal
    lda _cachedIcodeHdr + ICODE::posGlobal + 1
    sbc #0
    sta _cachedIcodeHdr + ICODE::posGlobal + 1

@GetLastToken:
    ; Load the data cache for the current chunk
    lda _cachedIcodeHdr + ICODE::currentChunkNum
    ldx _cachedIcodeHdr + ICODE::currentChunkNum + 1
    jsr loadDataCache
    ; Calculate the address of the token code we need to read
    lda #<_cachedIcodeData
    sta ptr1
    lda #>_cachedIcodeData
    sta ptr1 + 1
    ; Add 2 to get to the data portion of the chunk
    clc
    lda ptr1
    adc #2
    sta ptr1
    lda ptr1 + 1
    adc #0
    sta ptr1 + 1
    ; Add the chunk offset
    clc
    lda ptr1
    adc _cachedIcodeHdr + ICODE::posChunk
    sta ptr1
    lda ptr1 + 1
    adc #0
    sta ptr1 + 1
    ; Get the last code
    ldy #0
    lda (ptr1),y
    sta lastCode

    ; Check icode bounds
    lda hdrChunkNum
    ldx hdrChunkNum + 1
    jsr pushax
    lda #3
    ldx #0
    jsr _checkIcodeBounds

    ; Insert the line marker token
    lda _mcLineMarker
    sta pos
    lda hdrChunkNum
    ldx hdrChunkNum + 1
    jsr pushax
    lda #<pos
    ldx #>pos
    jsr pushax
    lda #1
    ldx #0
    jsr putDataToIcode

    ; Insert the current line number
    lda hdrChunkNum
    ldx hdrChunkNum + 1
    jsr pushax
    lda #<_currentLineNumber
    ldx #>_currentLineNumber
    jsr pushax
    lda #2
    ldx #0
    jsr putDataToIcode

    ; Re-append the last token code
    lda hdrChunkNum
    ldx hdrChunkNum + 1
    jsr pushax
    lda #<lastCode
    ldx #>lastCode
    jsr pushax
    lda #1
    ldx #0
    jsr putDataToIcode

@Done:
    rts

.endproc
