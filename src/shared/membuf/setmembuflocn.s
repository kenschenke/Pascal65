.include "membuf.inc"

.import popax, flushMemBufCache, loadMemBufHeaderCache, _cachedMemBufHdr
.importzp ptr1

.export _setMemBufLocn

.proc _setMemBufLocn
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
    lda (ptr1),y
    sta _cachedMemBufHdr + MEMBUF::currentChunkNum
    iny
    lda (ptr1),y
    sta _cachedMemBufHdr + MEMBUF::currentChunkNum + 1

    ldy #MEMBUF_LOCN::posGlobal
    lda (ptr1),y
    sta _cachedMemBufHdr + MEMBUF::posGlobal
    iny
    lda (ptr1),y
    sta _cachedMemBufHdr + MEMBUF::posGlobal + 1

    ldy #MEMBUF_LOCN::posChunk
    lda (ptr1),y
    sta _cachedMemBufHdr + MEMBUF::posChunk
    iny
    lda (ptr1),y
    sta _cachedMemBufHdr + MEMBUF::posChunk + 1

    rts
.endproc
