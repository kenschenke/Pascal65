#include "icodetest.h"

#include <string.h>

void testIcodeSymtabNode(void) {
    CHUNKNUM membuf;
    unsigned myPos = 0;
    CHUNKNUM symtab;
    CHUNKNUM chunkNum;
    SYMBNODE symtabNode;
    TOKEN token;

    DECLARE_TEST("testIcodeSymtabNode");

    allocMemBuf(&membuf);
    assertNonZeroChunkNum(membuf);
    assertEqualInt(0, getMemBufPos(membuf));

    // Write an identifier token
    putTokenToIcode(membuf, tcIdentifier);
    ++myPos;
    assertEqualInt(myPos, getMemBufPos(membuf));

    // Insert a line marker
    currentLineNumber = 1;
    insertLineMarker(membuf);
    myPos += 3;
    assertEqualInt(myPos, getMemBufPos(membuf));

    // Add a symbol table node
    assertNonZero(makeSymtab(&symtab));
    assertNonZero(enterSymtab(symtab, &symtabNode, "mynode", dcUndefined));
    chunkNum = symtabNode.node.nodeChunkNum;
    putSymtabNodeToIcode(membuf, &symtabNode);
    myPos += sizeof(CHUNKNUM);
    assertEqualInt(myPos, getMemBufPos(membuf));

    // Reset the position and read the node back

    resetMemBufPosition(membuf);
    assertEqualInt(0, getMemBufPos(membuf));
    currentLineNumber = 100;

    // Read the symbol table node back in
    memset(&symtabNode, 0, sizeof(SYMBNODE));
    getNextTokenFromIcode(membuf, &token, &symtabNode);
    assertEqualInt(1, currentLineNumber);
    assertEqualChunkNum(chunkNum, symtabNode.node.nodeChunkNum);

    freeMemBuf(membuf);
}

