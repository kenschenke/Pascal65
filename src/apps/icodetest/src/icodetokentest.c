#include "icodetest.h"

#include <string.h>

void testIcodeToken(void) {
    CHUNKNUM membuf;
    TOKEN token;
    unsigned myPos = 0;

    DECLARE_TEST("testIcodeToken");

    allocMemBuf(&membuf);
    assertNonZeroChunkNum(membuf);
    assertEqualInt(0, getMemBufPos(membuf));

    putTokenToIcode(membuf, tcColonEqual);
    ++myPos;
    assertEqualInt(myPos, getMemBufPos(membuf));

    currentLineNumber = 1;
    insertLineMarker(membuf);
    myPos += 3;
    assertEqualInt(myPos, getMemBufPos(membuf));

    putTokenToIcode(membuf, tcDotDot);
    ++myPos;
    assertEqualInt(myPos, getMemBufPos(membuf));

    currentLineNumber = 2;
    insertLineMarker(membuf);
    myPos += 3;
    assertEqualInt(myPos, getMemBufPos(membuf));

    myPos = 0;
    resetMemBufPosition(membuf);
    assertEqualInt(myPos, getMemBufPos(membuf));

    currentLineNumber = 100;
    getNextTokenFromIcode(membuf, &token, NULL);
    assertEqualByte(tcColonEqual, token.code);
    assertEqualInt(0, strcmp(":=", token.string));
    myPos += 4;
    assertEqualInt(myPos, getMemBufPos(membuf));
    assertEqualInt(1, currentLineNumber);

    currentLineNumber = 100;
    getNextTokenFromIcode(membuf, &token, NULL);
    assertEqualByte(tcDotDot, token.code);
    assertEqualInt(0, strcmp("..", token.string));
    myPos += 4;
    assertEqualInt(myPos, getMemBufPos(membuf));
    assertEqualInt(2, currentLineNumber);

    freeMemBuf(membuf);
}
