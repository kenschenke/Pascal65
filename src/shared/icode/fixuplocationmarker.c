#include <icode.h>
#include <membuf.h>

void fixupLocationMarker(CHUNKNUM headerChunkNum, MEMBUF_LOCN *pMemBufLocn) {
    MEMBUF_LOCN currLocn;

    getMemBufLocn(headerChunkNum, &currLocn);
    setMemBufLocn(headerChunkNum, pMemBufLocn);
    writeToMemBuf(headerChunkNum, &currLocn, sizeof(MEMBUF_LOCN));
    setMemBufLocn(headerChunkNum, &currLocn);
}
