#include "icodetest.h"

#include <string.h>

void testIcodeToken(void) {
    ICODE *Icode;
    TOKEN *token;
    unsigned myPos = 0;

    DECLARE_TEST("testIcodeToken");

    Icode = makeIcode();
    assertNotNull(Icode);
    assertEqualInt(0, getCurrentIcodeLocation(Icode));

    putTokenToIcode(Icode, tcColonEqual);
    ++myPos;
    assertEqualInt(myPos, getCurrentIcodeLocation(Icode));

    currentLineNumber = 1;
    insertLineMarker(Icode);
    myPos += 3;
    assertEqualInt(myPos, getCurrentIcodeLocation(Icode));

    putTokenToIcode(Icode, tcDotDot);
    ++myPos;
    assertEqualInt(myPos, getCurrentIcodeLocation(Icode));

    currentLineNumber = 2;
    insertLineMarker(Icode);
    myPos += 3;
    assertEqualInt(myPos, getCurrentIcodeLocation(Icode));

    myPos = 0;
    resetIcodePosition(Icode);
    assertEqualInt(myPos, getCurrentIcodeLocation(Icode));

    currentLineNumber = 100;
    token = getNextTokenFromIcode(Icode);
    assertEqualByte(tcColonEqual, token->code);
    assertEqualInt(0, strcmp(":=", token->string));
    myPos += 4;
    assertEqualInt(myPos, getCurrentIcodeLocation(Icode));
    assertEqualInt(1, currentLineNumber);

    currentLineNumber = 100;
    token = getNextTokenFromIcode(Icode);
    assertEqualByte(tcDotDot, token->code);
    assertEqualInt(0, strcmp("..", token->string));
    myPos += 4;
    assertEqualInt(myPos, getCurrentIcodeLocation(Icode));
    assertEqualInt(2, currentLineNumber);

    freeIcode(Icode);
}
