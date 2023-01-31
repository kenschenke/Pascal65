#include <membuf.h>
#include <chunks.h>

void duplicateMemBuf(CHUNKNUM sourceHeader, CHUNKNUM *destHeader) {
    CHUNKNUM sourceChunk, destChunk;
    unsigned char chunk[CHUNK_LEN];
    MEMBUF *pMembuf = (MEMBUF *) chunk;
    MEMBUF_CHUNK *pMembufChunk = (MEMBUF_CHUNK *) chunk;

    // Allocate a chunk for the new header
    allocChunk(destHeader);

    // Retrieve the current header
    retrieveChunk(sourceHeader, chunk);
    sourceChunk = pMembuf->firstChunkNum;

    // Allocate the first data chunk
    allocChunk(&pMembuf->firstChunkNum);
    destChunk = pMembuf->firstChunkNum;

    // Store the new header
    storeChunk(*destHeader, chunk);

    while (sourceChunk) {
        retrieveChunk(sourceChunk, chunk);
        sourceChunk = pMembufChunk->nextChunk;
        if (sourceChunk) {
            allocChunk(&pMembufChunk->nextChunk);
        }
        storeChunk(destChunk, chunk);
        destChunk = pMembufChunk->nextChunk;
    }
}