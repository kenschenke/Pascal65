#include "icodetest.h"
#include <symtab.h>
#include <string.h>

void testIcodeGotoPosition(void) {
    CHUNKNUM Icode;
    int i;
    char ident[10];
    unsigned myPos = 0, testPos;
    TOKEN token;
    CHUNKNUM testChunkNum;
    CHUNKNUM symtab;
    SYMTABNODE symtabNode;

    DECLARE_TEST("testIcodeGotoPosition");

    makeIcode(&Icode);
    assertNonZero(Icode);
    assertEqualInt(0, getCurrentIcodeLocation(Icode));
    assertNonZero(makeSymtab(&symtab));

    // Append 20 symbol table nodes
    for (i = 0; i < 20; ++i) {
        if (i == 4) {
            testPos = myPos;
        }

        putTokenToIcode(Icode, tcIdentifier);
        ++myPos;
        assertEqualInt(myPos, getCurrentIcodeLocation(Icode));

        sprintf(ident, "ident%02d", i+1);
        assertNonZero(enterSymtab(symtab, &symtabNode, ident, dcUndefined));
        putSymtabNodeToIcode(Icode, &symtabNode);
        myPos += sizeof(CHUNKNUM);
        assertEqualInt(myPos, getCurrentIcodeLocation(Icode));

        if (i == 4) {
            testChunkNum = symtabNode.nodeChunkNum;
        }
    }

    memset(&symtabNode, 0, sizeof(SYMTABNODE));
    gotoIcodePosition(Icode, testPos);
    assertEqualInt(testPos, getCurrentIcodeLocation(Icode));
    getNextTokenFromIcode(Icode, &token, &symtabNode);
    assertEqualInt(tcIdentifier, token.code);
    assertEqualChunkNum(testChunkNum, symtabNode.nodeChunkNum);
    assertEqualInt(0, strcmp("ident05", token.string));
    
}

void testIcodePosition(void) {
    CHUNKNUM Icode;
    unsigned myPos = 0;
    CHUNKNUM symtab;
    SYMTABNODE symtabNode;

    DECLARE_TEST("testIcodePosition");

    makeIcode(&Icode);
    assertNonZero(Icode);
    assertEqualInt(0, getCurrentIcodeLocation(Icode));

    // Add a symbol table node
    assertNonZero(makeSymtab(&symtab));
    assertNonZero(enterSymtab(symtab, &symtabNode, "mynode", dcUndefined));
    putSymtabNodeToIcode(Icode, &symtabNode);
    myPos += sizeof(CHUNKNUM);
    assertEqualInt(myPos, getCurrentIcodeLocation(Icode));

    // Insert a line marker
    currentLineNumber = 1;
    insertLineMarker(Icode);
    myPos += 3;
    assertEqualInt(myPos, getCurrentIcodeLocation(Icode));

    // Write a token code
    putTokenToIcode(Icode, tcColonEqual);
    ++myPos;
    assertEqualInt(myPos, getCurrentIcodeLocation(Icode));

    // Insert another line marker
    ++currentLineNumber;
    insertLineMarker(Icode);
    myPos += 3;
    assertEqualInt(myPos, getCurrentIcodeLocation(Icode));

    // Reset the position
    resetIcodePosition(Icode);
    assertEqualInt(0, getCurrentIcodeLocation(Icode));

    freeIcode(Icode);
}
