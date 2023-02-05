.include "membuf.inc"

.import popax, loadMemBufHeaderCache, _cachedMemBufHdr
.importzp ptr1

.export _getMemBufLocn

.code

.proc _getMemBufLocn
    pha
    txa
    pha
    jsr popax
    jsr loadMemBufHeaderCache

    pla
    sta ptr1 + 1
    pla
    sta ptr1

    ldy #MEMBUF_LOCN::chunkNum
    lda _cachedMemBufHdr + MEMBUF::currentChunkNum
    sta (ptr1),y
    lda _cachedMemBufHdr + MEMBUF::currentChunkNum + 1
    iny
    sta (ptr1),y

    ldy #MEMBUF_LOCN::posGlobal
    lda _cachedMemBufHdr + MEMBUF::posGlobal
    sta (ptr1),y
    lda _cachedMemBufHdr + MEMBUF::posGlobal + 1
    iny
    sta (ptr1),y

    ldy #MEMBUF_LOCN::posChunk
    lda _cachedMemBufHdr + MEMBUF::posChunk
    sta (ptr1),y
    lda _cachedMemBufHdr + MEMBUF::posChunk + 1
    iny
    sta (ptr1),y

    rts
.endproc
