#include <icode.h>
#include <membuf.h>
#include <string.h>

void putLocationMarker(CHUNKNUM headerChunkNum, MEMBUF_LOCN *pMemBufLocn) {
    char code = mcLocationMarker;
    MEMBUF_LOCN buf;

    writeToMemBuf(headerChunkNum, &code, 1);

    getMemBufLocn(headerChunkNum, pMemBufLocn);
    memset(&buf, 0, sizeof(MEMBUF_LOCN));
    writeToMemBuf(headerChunkNum, &buf, sizeof(MEMBUF_LOCN));
}
