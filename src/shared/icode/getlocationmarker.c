#include <membuf.h>
#include <icode.h>
#include <string.h>

void getLocationMarker(CHUNKNUM chunkNum, MEMBUF_LOCN *pMemBufLocn) {
    readFromMemBuf(chunkNum, pMemBufLocn, sizeof(MEMBUF_LOCN));
}
