#include "icodetest.h"

void testIcodeSymtabNode(void) {
    ICODE *Icode;
    unsigned myPos = 0;
    SYMTAB symtab;
    CHUNKNUM chunkNum;
    SYMTABNODE symtabNode;
    TOKEN *token;

    DECLARE_TEST("testIcodeSymtabNode");

    Icode = makeIcode();
    assertNotNull(Icode);
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
    assertNonZero(enterSymtab(&symtab, &symtabNode, "mynode"));
    chunkNum = symtabNode.nodeChunkNum;
    assertNonZero(setSymtabInt(&symtabNode, 5));
    putSymtabNodeToIcode(Icode, &symtabNode);
    myPos += sizeof(CHUNKNUM);
    assertEqualInt(myPos, getCurrentIcodeLocation(Icode));

    // Reset the position and read the node back

    resetIcodePosition(Icode);
    currentLineNumber = 100;

    // Read the symbol table node back in
    token = getNextTokenFromIcode(Icode);
    assertEqualInt(1, currentLineNumber);
    assertEqualChunkNum(chunkNum, Icode->symtabNode.nodeChunkNum);

    freeIcode(Icode);
}

