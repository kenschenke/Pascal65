#include "icodetest.h"
#include <symtab.h>

void testIcodePosition(void) {
    ICODE *Icode;
    unsigned myPos = 0;
    SYMTAB symtab;
    SYMTABNODE symtabNode;

    DECLARE_TEST("testIcodePosition");

    Icode = makeIcode();
    assertNotNull(Icode);
    assertEqualInt(0, getCurrentIcodeLocation(Icode));

    // Add a symbol table node
    assertNonZero(makeSymtab(&symtab));
    assertNonZero(enterSymtab(&symtab, &symtabNode, "mynode"));
    assertNonZero(setSymtabInt(&symtabNode, 5));
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
