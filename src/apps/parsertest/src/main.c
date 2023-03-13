#include <stdio.h>
#include <buffer.h>
#include <scanner.h>
#include <common.h>
#include <cbm.h>
#include <device.h>
#include <parser.h>
#include <symtab.h>
#include <stdlib.h>
#include <string.h>
#include <tokenizer.h>

#ifdef __MEGA65__
#error Code to cache overlays is needed
#else
#include <em.h>
#endif

extern void _OVERLAY1_LOAD__[], _OVERLAY1_SIZE__[];
extern void _OVERLAY2_LOAD__[], _OVERLAY2_SIZE__[];
extern void _OVERLAY3_LOAD__[], _OVERLAY3_SIZE__[];
unsigned char loadfile(const char *name);

static void runControlTest(const char *test, int firstLine);

void arrayTest(CHUNKNUM);
void constTest(CHUNKNUM);
void enumTest(CHUNKNUM);
void recordTest(CHUNKNUM);
void routineTest(CHUNKNUM);
void scalarTest(CHUNKNUM);
void stdRtnTest(CHUNKNUM);
void subrangeTest(CHUNKNUM);
void varTest(CHUNKNUM);
void runIcodeTest(CHUNKNUM Icode, const char *testFile, int firstLine, const char *testName);

struct TestCase {
    const char *source;
    void (*testRunner)(CHUNKNUM);
    // TErrorCode code;
    // unsigned lineNumber;
};

static struct TestCase cases[] = {
    {"scalartest.pas", scalarTest},
    {"arraytest.pas", arrayTest},
    {"subrangetest.pas", subrangeTest},
    {"enumtest.pas", enumTest},
    {"consttest.pas", constTest},
    {"recordtest.pas", recordTest},
    {"routinetest.pas", routineTest},
    {"stdrtntest.pas", stdRtnTest},
    // {"missingprog.pas", errMissingPROGRAM, 3},
    // {"missingpid.pas", errMissingIdentifier, 3},
    // {"badprogvar.pas", errMissingIdentifier, 3},
    {NULL},
};

#if 0
static TErrorCode expectedCode;
static unsigned expectedLineNumber;
#endif
static unsigned overlay1size, overlay2size, overlay3size;
static unsigned overlay1blocks, overlay2blocks, overlay3blocks;

static BLOCKNUM parserCache, testCache, tokenizerCache;

static int sawCode;
static int testsRun;
static int testsFail;

void logError(const char *message, unsigned lineNumber, TErrorCode /*code*/)
{
#if 0
    if (code == expectedCode && lineNumber == expectedLineNumber) {
        sawCode = 1;
    }
#else
    printf("*** ERROR: %s -- line %d\n", message, lineNumber);
#endif
}

void logFatalError(const char *message)
{
    printf("*** Fatal translation error: %s\n", message);
}

void logRuntimeError(const char *message, unsigned /*lineNumber*/)
{
    printf("*** Runtime error: %s\n", message);
}

#if 1
char failCode;
#endif

unsigned char loadfile(const char *name)
{
    if (cbm_load(name, getcurrentdevice(), NULL) == 0) {
        return 0;
    }

    return 1;
}

static void loadOverlayFromCache(unsigned size, void *buffer, unsigned cache) {
    struct em_copy emc;

    emc.buf = buffer;
    emc.offs = 0;
    emc.page = cache;
    emc.count = size;
    em_copyfrom(&emc);
}

static void loadOverlayFromFile(char *name, unsigned size, void *buffer, unsigned cache) {
    struct em_copy emc;

    if (!loadfile(name)) {
        printf("Unable to load overlay from disk\n");
        exit(0);
    }

    // Copy the parser overlay to the cache
    emc.buf = buffer;
    emc.offs = 0;
    emc.page = cache;
    emc.count = size;
    em_copyto(&emc);
}

static void runControlTest(const char *test, int firstLine) {
    SYMBNODE programNode;
    CHUNKNUM tokenIcode, programId;
    char buf[25], buf2[30];

    sprintf(buf, "%stest.pas", test);

    initBlockStorage();

    loadOverlayFromCache(overlay1size, _OVERLAY1_LOAD__, tokenizerCache);
    initCommon();

    printf("\nTokenizing %s\n", buf);
    initTokenizer();
    tokenIcode = tokenize(buf);

    loadOverlayFromCache(overlay2size, _OVERLAY2_LOAD__, parserCache);
    initParser();
    printf("Parsing\n");
    programId = parse(tokenIcode);

    printf("Running tests\n");
    loadOverlayFromCache(overlay3size, _OVERLAY3_LOAD__, testCache);

    sprintf(buf, "%stest.txt", test);
    sprintf(buf2, "%sIcodeTests", test);

    loadSymbNode(programId, &programNode);
    runIcodeTest(programNode.defn.routine.Icode, buf, firstLine, buf2);
}

int main()
{
    CHUNKNUM tokenIcode, programId;
    int i = 0, j = 0;
    const char *controlTests[] = { "casechar", "caseenum", "caseint", "for", "if", "repeat", "while", NULL };

    overlay1size = (unsigned)_OVERLAY1_SIZE__;
    overlay2size = (unsigned)_OVERLAY2_SIZE__;
    overlay3size = (unsigned)_OVERLAY3_SIZE__;
    overlay1blocks = overlay1size/BLOCK_LEN + (overlay1size % BLOCK_LEN ? 1 : 0);
    overlay2blocks = overlay2size/BLOCK_LEN + (overlay2size % BLOCK_LEN ? 1 : 0);
    overlay3blocks = overlay3size/BLOCK_LEN + (overlay3size % BLOCK_LEN ? 1 : 0);

    testsRun = 0;
    testsFail = 0;

#if 0
    printf("avail = %d\n", _heapmemavail());
    return 0;
#endif

    initBlockStorage();

    // Allocate space in extended memory to cache the parser and parsertest overlays.
    // This is done so they don't have to be reloaded for each test.
    if (!allocBlockGroup(&tokenizerCache, overlay1blocks) ||
        !allocBlockGroup(&parserCache, overlay2blocks) ||
        !allocBlockGroup(&testCache, overlay3blocks)) {
        printf("Unable to allocate extended memory\n");
        return 0;
    }

    loadOverlayFromFile("parsertest.1", overlay1size, _OVERLAY1_LOAD__, tokenizerCache);
    loadOverlayFromFile("parsertest.2", overlay2size, _OVERLAY2_LOAD__, parserCache);
    loadOverlayFromFile("parsertest.3", overlay3size, _OVERLAY3_LOAD__, testCache);

    while (1) {
        if (!cases[i].source) {
            break;
        }

        initBlockStorage();

        // Load the parser overlay from extended memory cache
        loadOverlayFromCache(overlay1size, _OVERLAY1_LOAD__, tokenizerCache);
        initCommon();
        // programId = parse("translate.pas");

        sawCode = 0;
        // expectedCode = cases[i].code;
        // expectedLineNumber = cases[i].lineNumber;

        // parse(cases[i].source);

        printf("\nTokenizing %s\n", cases[i].source);
        initTokenizer();
        tokenIcode = tokenize(cases[i].source);

        printf("Parsing\n");
        loadOverlayFromCache(overlay2size, _OVERLAY2_LOAD__, parserCache);
        initParser();
        programId = parse(tokenIcode);
    
        // Load the testing overlay
        printf("Running tests\n");
        loadOverlayFromCache(overlay3size, _OVERLAY3_LOAD__, testCache);

        cases[i].testRunner(programId);

        ++i;
    }

    while (controlTests[j]) {
        runControlTest(controlTests[j], 7);

        ++j;
        ++i;
    }

    printf("\n%d test%s run\n", i, i == 1 ? "" : "s");
    printf("%d test%s failed\n", testsFail, testsFail == 1 ? "" : "s");

	return 0;
}
