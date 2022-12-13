;;;
 ; checkIcodeBounds.s
 ; Ken Schenke (kenschenke@gmail.com)
 ; 
 ; Intermediate Code Storage and Retrieval
 ; 
 ; Copyright (c) 2022
 ; Use of this source code is governed by an MIT-style
 ; license that can be found in the LICENSE file or at
 ; https://opensource.org/licenses/MIT
;;;

.include "membuf.inc"
.include "error.inc"

.export _checkIcodeBounds

.import loadMemBufHeaderCache, _cachedMemBufHdr, _codeSegmentSize
.import _Error, _abortTranslation
.import popax

.bss

size: .res 2

.code

; void checkIcodeBounds(CHUNKNUM hdrChunkNum, int size)
.proc _checkIcodeBounds
    ; Save the second parameter
    sta size
    stx size + 1
    ; Retrieve the first parameter
    jsr popax

    ; Load the header from cache
    jsr loadMemBufHeaderCache

    ; Add global position to size
    clc
    lda size
    adc _cachedMemBufHdr + MEMBUF::posGlobal
    sta size
    lda size + 1
    adc _cachedMemBufHdr + MEMBUF::posGlobal + 1
    sta size + 1

    ; Compare it to codeSegmentSize
    lda size + 1
    cmp _codeSegmentSize + 1
    bcc @Done
    lda size
    cmp _codeSegmentSize
    bcc @Done

    ; Segment overflow
    lda #errCodeSegmentOverflow
    jsr _Error
    lda #abortCodeSegmentOverflow
    jsr _abortTranslation

@Done:
    rts
.endproc
