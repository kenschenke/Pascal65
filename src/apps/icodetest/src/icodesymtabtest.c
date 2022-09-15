#include "icodetest.h"

#include <string.h>

void testIcodeSymtabNode(void) {
    CHUNKNUM Icode;
    unsigned myPos = 0;
    CHUNKNUM symtab;
    CHUNKNUM chunkNum;
    SYMTABNODE symtabNode;
    ICODE hdrChunk;
    TOKEN token;

    DECLARE_TEST("testIcodeSymtabNode");

    makeIcode(&Icode);
    assertNonZero(Icode);
    assertEqualInt(0, getCurrentIcodeLocation(Icode));

    // Write an identifier token
    putTokenToIcode(Icode, tcIdentifier);
    ++myPos;
    assertEqualInt(myPos, getCurrentIcodeLocation(Icode));

    // Insert a line marker
    currentLineNumber = 1;
    insertLineMarker(Icode);
    myPos += 3;
    assertEqualInt(myPos, getCurrentIcodeLocation(Icode));

    // Add a symbol table node
    assertNonZero(makeSymtab(&symtab));
    assertNonZero(enterSymtab(symtab, &symtabNode, "mynode", dcUndefined));
    chunkNum = symtabNode.nodeChunkNum;
    putSymtabNodeToIcode(Icode, &symtabNode);
    myPos += sizeof(CHUNKNUM);
    assertEqualInt(myPos, getCurrentIcodeLocation(Icode));

    // Reset the position and read the node back

    resetIcodePosition(Icode);
    assertEqualInt(0, getCurrentIcodeLocation(Icode));
    currentLineNumber = 100;

    // Read the symbol table node back in
    memset(&symtabNode, 0, sizeof(SYMTABNODE));
    getNextTokenFromIcode(Icode, &token, &symtabNode);
    assertEqualInt(1, currentLineNumber);
    assertEqualChunkNum(chunkNum, symtabNode.nodeChunkNum);

    freeIcode(Icode);
}

