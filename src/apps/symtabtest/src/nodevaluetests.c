#include "symtabtest.h"
#include <common.h>
#include <string.h>

#define TEST_DATA_SINGLE "Lorem ipsum dolor"
#define TEST_DATA_SHORT "Lorem ipsum dolor sit amet"
#define TEST_DATA_LONG "Lorem ipsum dolor sit amet, consectetur cras amet."

static CHUNKNUM symtabChunkNum;

static void addIntNodes(void);
static void addStringNodes(void);

void testNodeValues(void) {
    SYMTAB symtab;

    DECLARE_TEST("testNodeValues");

    assertNonZero(makeSymtab(&symtab));
    symtabChunkNum = symtab.symtabChunkNum;

    addIntNodes();
    addStringNodes();
}

static void addIntNodes(void)
{
    int value;
    SYMTAB symtab;
    SYMTABNODE node;

    DECLARE_TEST("addIntNodes");

    assertNonZero(retrieveChunk(symtabChunkNum, (unsigned char *)&symtab));

    assertNonZero(enterSymtab(&symtab, &node, "value1"));
    assertEqualInt(0, node.xNode);
    assertNonZero(setSymtabInt(&node, 5));
    assertEqualByte((unsigned char)valInteger, node.valueType);
    memcpy(&value, node.value, sizeof(value));
    assertEqualInt(5, value);

    assertNonZero(enterSymtab(&symtab, &node, "value2"));
    assertEqualInt(1, node.xNode);
    assertNonZero(setSymtabInt(&node, 10));
    assertEqualByte((unsigned char)valInteger, node.valueType);
    memcpy(&value, node.value, sizeof(value));
    assertEqualInt(10, value);

    assertNonZero(enterSymtab(&symtab, &node, "value1"));
    assertEqualInt(0, node.xNode);
    assertNonZero(setSymtabInt(&node, 15));
    assertEqualByte((unsigned char)valInteger, node.valueType);
    memcpy(&value, node.value, sizeof(value));
    assertEqualInt(15, value);

    // Should still be 2 nodes - not 3.
    assertEqualInt(2, symtab.cntNodes);

    assertNonZero(searchSymtab(&symtab, &node, "value2"));
    assertEqualInt(1, node.xNode);
    memcpy(&value, node.value, sizeof(value));
    assertEqualInt(10, value);

    assertNonZero(searchSymtab(&symtab, &node, "value1"));
    assertEqualInt(0, node.xNode);
    memcpy(&value, node.value, sizeof(value));
    assertEqualInt(15, value);
}

void addStringNodes(void) {
    int len;
    const char *p;
    int chunksAlloc;
    SYMTAB symtab;
    SYMTABNODE node;
    CHUNKNUM chunkNum, secondChunk, thirdChunk;
    STRVALCHUNK strChunk;

    DECLARE_TEST("addStringNodes");

    assertNonZero(retrieveChunk(symtabChunkNum, (unsigned char *)&symtab));

    assertNonZero(enterSymtab(&symtab, &node, "string1"));
    assertNonZero(setSymtabString(&node, TEST_DATA_LONG));
    memcpy(&len, node.value, sizeof(len));
    assertEqualInt(strlen(TEST_DATA_LONG), len);

    memcpy(&chunkNum, node.value + 2, sizeof(chunkNum));
    assertNonZero(retrieveChunk(chunkNum, (unsigned char *)&strChunk));
    p = TEST_DATA_LONG;
    assertZero(strncmp(p, strChunk.value, sizeof(strChunk.value)));
    p += sizeof(strChunk.value);

    chunkNum = secondChunk = strChunk.nextChunkNum;
    assertNonZero(retrieveChunk(chunkNum, (unsigned char *)&strChunk));
    assertZero(strncmp(p, strChunk.value, sizeof(strChunk.value)));
    p += sizeof(strChunk.value);

    chunkNum = thirdChunk = strChunk.nextChunkNum;
    assertNonZero(retrieveChunk(chunkNum, (unsigned char *)&strChunk));
    assertZero(strncmp(p, strChunk.value, strlen(p)));

    // Change the string value to need one fewer chunks

    chunksAlloc = getAvailChunks();
    assertNonZero(setSymtabString(&node, TEST_DATA_SHORT));
    assertEqualInt(chunksAlloc + 1, getAvailChunks());
    assertZero(isChunkAllocated(thirdChunk));
    
    memcpy(&len, node.value, sizeof(int));
    assertEqualInt(strlen(TEST_DATA_SHORT), len);
    memcpy(&chunkNum, node.value + 2, sizeof(chunkNum));
    assertNonZero(retrieveChunk(chunkNum, (unsigned char *)&strChunk));
    p = TEST_DATA_SHORT;
    assertZero(strncmp(p, strChunk.value, sizeof(strChunk.value)));
    p += sizeof(strChunk.value);
    assertEqualChunkNum(secondChunk, strChunk.nextChunkNum);

    assertNonZero(retrieveChunk(strChunk.nextChunkNum, (unsigned char *)&strChunk));
    assertZero(strncmp(p, strChunk.value, strlen(p)));
    assertEqualChunkNum(0, strChunk.nextChunkNum);

    // Change the string value to need only one chunk

    assertNonZero(setSymtabString(&node, TEST_DATA_SINGLE));
    memcpy(&len, node.value, sizeof(int));
    assertEqualInt(strlen(TEST_DATA_SINGLE), len);
    assertEqualInt(chunksAlloc + 2, getAvailChunks());
    assertZero(isChunkAllocated(secondChunk));
    memcpy(&chunkNum, node.value + 2, sizeof(chunkNum));
    assertNonZero(retrieveChunk(chunkNum, (unsigned char *)&strChunk));
    p = TEST_DATA_SINGLE;
    assertZero(strncmp(p, strChunk.value, strlen(p)));
    assertEqualChunkNum(0, strChunk.nextChunkNum);

    // Set it back to a longer value

    assertNonZero(setSymtabString(&node, TEST_DATA_LONG));
    memcpy(&len, node.value, sizeof(int));
    assertEqualInt(strlen(TEST_DATA_LONG), len);
    assertEqualInt(chunksAlloc, getAvailChunks());
}
