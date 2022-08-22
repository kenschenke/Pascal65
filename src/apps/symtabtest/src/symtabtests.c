#include "symtabtest.h"
#include <common.h>

static void allocateFirstSymtab(void);
static void allocateSecondSymtab(void);

static CHUNKNUM firstSymtab;
static CHUNKNUM secondSymtab;

void testSymbolTables(void) {
    firstSymtab = 0;
    secondSymtab = 0;

    allocateFirstSymtab();
    allocateSecondSymtab();
}

static void allocateFirstSymtab(void) {
    SYMTAB symtab;

    DECLARE_TEST("allocateFirstSymtab");

    assertZero(firstSymtabChunk);
    assertNonZero(makeSymtab(&symtab));
    firstSymtab = symtab.symtabChunkNum;
    assertEqualInt(0, symtab.xSymtab);
    assertEqualChunkNum(firstSymtabChunk, symtab.symtabChunkNum);
}

static void allocateSecondSymtab(void) {
    SYMTAB symtab;

    DECLARE_TEST("allocateSecondSymtab");

    assertNonZero(makeSymtab(&symtab));
    secondSymtab = symtab.symtabChunkNum;
    assertEqualInt(1, symtab.xSymtab);
    assertEqualChunkNum(symtab.nextSymtabChunk, firstSymtab);
    assertEqualChunkNum(firstSymtabChunk, symtab.symtabChunkNum);
}