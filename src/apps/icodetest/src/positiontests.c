#include "icodetest.h"
#include <symtab.h>
#include <string.h>

void testIcodeGotoPosition(void) {
    CHUNKNUM membuf;
    int i;
    char ident[10];
    unsigned myPos = 0, testPos;
    TOKEN token;
    CHUNKNUM testChunkNum;
    CHUNKNUM symtab;
    SYMBNODE symtabNode;

    DECLARE_TEST("testIcodeGotoPosition");

    allocMemBuf(&membuf);
    assertNonZeroChunkNum(membuf);
    assertEqualInt(0, getMemBufPos(membuf));
    assertNonZero(makeSymtab(&symtab));

    // Append 20 symbol table nodes
    for (i = 0; i < 20; ++i) {
        if (i == 4) {
            testPos = myPos;
        }

        putTokenToIcode(membuf, tcIdentifier);
        ++myPos;
        assertEqualInt(myPos, getMemBufPos(membuf));

        sprintf(ident, "ident%02d", i+1);
        assertNonZero(enterSymtab(symtab, &symtabNode, ident, dcUndefined));
        putSymtabNodeToIcode(membuf, &symtabNode);
        myPos += sizeof(CHUNKNUM);
        assertEqualInt(myPos, getMemBufPos(membuf));

        if (i == 4) {
            testChunkNum = symtabNode.node.nodeChunkNum;
        }
    }

    memset(&symtabNode, 0, sizeof(SYMBNODE));
    setMemBufPos(membuf, testPos);
    assertEqualInt(testPos, getMemBufPos(membuf));
    getNextTokenFromIcode(membuf, &token, &symtabNode);
    assertEqualInt(tcIdentifier, token.code);
    assertEqualChunkNum(testChunkNum, symtabNode.node.nodeChunkNum);
    assertEqualInt(0, strcmp("ident05", token.string));
}

void testIcodePosition(void) {
    CHUNKNUM membuf;
    unsigned myPos = 0;
    CHUNKNUM symtab;
    SYMBNODE symtabNode;

    DECLARE_TEST("testIcodePosition");

    allocMemBuf(&membuf);
    assertNonZeroChunkNum(membuf);
    assertEqualInt(0, getMemBufPos(membuf));

    // Add a symbol table node
    assertNonZero(makeSymtab(&symtab));
    assertNonZero(enterSymtab(symtab, &symtabNode, "mynode", dcUndefined));
    putSymtabNodeToIcode(membuf, &symtabNode);
    myPos += sizeof(CHUNKNUM);
    assertEqualInt(myPos, getMemBufPos(membuf));

    // Insert a line marker
    currentLineNumber = 1;
    insertLineMarker(membuf);
    myPos += 3;
    assertEqualInt(myPos, getMemBufPos(membuf));

    // Write a token code
    putTokenToIcode(membuf, tcColonEqual);
    ++myPos;
    assertEqualInt(myPos, getMemBufPos(membuf));

    // Insert another line marker
    ++currentLineNumber;
    insertLineMarker(membuf);
    myPos += 3;
    assertEqualInt(myPos, getMemBufPos(membuf));

    // Reset the position
    resetMemBufPosition(membuf);
    assertEqualInt(0, getMemBufPos(membuf));

    freeMemBuf(membuf);
}
