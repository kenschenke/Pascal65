#include "symtabtest.h"
#include <common.h>
#include <string.h>

static CHUNKNUM symtabChunkNum;

static void addNodes(void);
static void retrieveNodes(void);

void testSymbolTableNodes(void) {
    SYMTAB symtab;

    DECLARE_TEST("testSymbolTableNodes");

    assertNonZero(makeSymtab(&symtab));
    symtabChunkNum = symtab.symtabChunkNum;

    addNodes();
    retrieveNodes();
}

static void addNodes(void) {
#if 0
    int cnt = 0;
    char chunk[CHUNK_LEN];
    SYMTAB symtab;
    SYMTABNODE node;

    DECLARE_TEST("addNodes");

    assertNonZero(retrieveChunk(symtabChunkNum, (unsigned char *)&symtab));

    assertNonZero(enterSymtab(&symtab, &node, "feast"));
    assertNonZero(retrieveChunk(node.nameChunkNum, (unsigned char *)chunk));
    assertEqualInt(0, strcmp(chunk, "feast"));
    assertEqualInt(++cnt, symtab.cntNodes);

    assertNonZero(enterSymtab(&symtab, &node, "mixup"));
    assertNonZero(retrieveChunk(node.nameChunkNum, (unsigned char *)chunk));
    assertEqualInt(0, strcmp(chunk, "mixup"));
    assertEqualInt(++cnt, symtab.cntNodes);

    assertNonZero(enterSymtab(&symtab, &node, "serve"));
    assertNonZero(retrieveChunk(node.nameChunkNum, (unsigned char *)chunk));
    assertEqualInt(0, strcmp(chunk, "serve"));
    assertEqualInt(++cnt, symtab.cntNodes);

    assertNonZero(enterSymtab(&symtab, &node, "panda"));
    assertNonZero(retrieveChunk(node.nameChunkNum, (unsigned char *)chunk));
    assertEqualInt(0, strcmp(chunk, "panda"));
    assertEqualInt(++cnt, symtab.cntNodes);

    assertNonZero(enterSymtab(&symtab, &node, "thorn"));
    assertNonZero(retrieveChunk(node.nameChunkNum, (unsigned char *)chunk));
    assertEqualInt(0, strcmp(chunk, "thorn"));
    assertEqualInt(++cnt, symtab.cntNodes);

    assertNonZero(enterSymtab(&symtab, &node, "jerky"));
    assertNonZero(retrieveChunk(node.nameChunkNum, (unsigned char *)chunk));
    assertEqualInt(0, strcmp(chunk, "jerky"));
    assertEqualInt(++cnt, symtab.cntNodes);

    assertNonZero(enterSymtab(&symtab, &node, "crate"));
    assertNonZero(retrieveChunk(node.nameChunkNum, (unsigned char *)chunk));
    assertEqualInt(0, strcmp(chunk, "crate"));
    assertEqualInt(++cnt, symtab.cntNodes);
#endif
}

static void retrieveNodes(void) {
#if 0
    SYMTAB symtab;
    SYMTABNODE node;

    DECLARE_TEST("retrieveNodes");

    assertNonZero(retrieveChunk(symtabChunkNum, (unsigned char *)&symtab));

    assertNonZero(searchSymtab(&symtab, &node, "feast"));
    assertEqualInt(0, node.xNode);

    assertNonZero(searchSymtab(&symtab, &node, "mixup"));
    assertEqualInt(1, node.xNode);

    assertNonZero(searchSymtab(&symtab, &node, "serve"));
    assertEqualInt(2, node.xNode);

    assertNonZero(searchSymtab(&symtab, &node, "panda"));
    assertEqualInt(3, node.xNode);

    assertNonZero(searchSymtab(&symtab, &node, "thorn"));
    assertEqualInt(4, node.xNode);

    assertNonZero(searchSymtab(&symtab, &node, "jerky"));
    assertEqualInt(5, node.xNode);

    assertNonZero(searchSymtab(&symtab, &node, "crate"));
    assertEqualInt(6, node.xNode);
#endif
}

