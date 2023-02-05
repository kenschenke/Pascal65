#include <icode.h>
#include <membuf.h>
#include <string.h>

void putCaseItem(CHUNKNUM headerChunkNum, int value, MEMBUF_LOCN *pMemBufLocn) {
    writeToMemBuf(headerChunkNum, &value, sizeof(int));
    if (pMemBufLocn) {
        writeToMemBuf(headerChunkNum, pMemBufLocn, sizeof(MEMBUF_LOCN));
    } else {
        MEMBUF_LOCN dummy;

        memset(&dummy, 0, sizeof(MEMBUF_LOCN));
        writeToMemBuf(headerChunkNum, &dummy, sizeof(MEMBUF_LOCN));
    }
}
