#include <icode.h>
#include <membuf.h>
#include <string.h>

void getCaseItem(CHUNKNUM headerChunkNum, int *value, MEMBUF_LOCN *pMemBufLocn) {
    readFromMemBuf(headerChunkNum, value, sizeof(int));
    readFromMemBuf(headerChunkNum, pMemBufLocn, sizeof(MEMBUF_LOCN));
}
