#include <string.h>
#include <stdlib.h>
#include <ovrlcommon.h>
#include <cbm.h>
#include <device.h>
#include <conio.h>
#include <common.h>
#include <chunks.h>
#include <parser.h>
#include <semantic.h>
#include <codegen.h>
#include <em.h>
#include <int16.h>
#include <membuf.h>
#include <libcommon.h>
#include <int16.h>

static char intBuffer[16];

static char *testFiles[] = {
    "add",
    "ifthen",
    "loops",
    "stdroutines",
    "recarray",
    "scopetest",
    "vartest",
    "casetest",
    "procfunc",
    "subtract",
    NULL
};

extern void _OVERLAY1_LOAD__[], _OVERLAY1_SIZE__[];
extern void _OVERLAY2_LOAD__[], _OVERLAY2_SIZE__[];
extern void _OVERLAY3_LOAD__[], _OVERLAY3_SIZE__[];
extern void _OVERLAY4_LOAD__[], _OVERLAY4_SIZE__[];
extern void _OVERLAY5_LOAD__[], _OVERLAY5_SIZE__[];
unsigned char loadfile(const char *name);

#ifndef __MEGA65__
static unsigned overlay1size, overlay2size, overlay3size, overlay4size, overlay5size;
static unsigned overlay1blocks, overlay2blocks, overlay3blocks, overlay4blocks, overlay5blocks;

static BLOCKNUM objcodeCache, linkerCache, parserCache, semanticCache, tokenizerCache;

static void loadOverlayFromCache(unsigned size, void *buffer, unsigned cache) {
    struct em_copy emc;

    emc.buf = buffer;
    emc.offs = 0;
    emc.page = cache;
    emc.count = size;
    flushChunkBlock();
    em_copyfrom(&emc);
}

static void loadOverlayFromFile(char *name, unsigned size, void *buffer, unsigned cache) {
    struct em_copy emc;

    if (!loadfile(name)) {
        printlnz("Unable to load overlay from disk");
        exit(0);
    }

    // Copy the parser overlay to the cache
    emc.buf = buffer;
    emc.offs = 0;
    emc.page = cache;
    emc.count = size;
    flushChunkBlock();
    em_copyto(&emc);
}
#endif

void main()
{
    int i = 0, avail;

    setIntBuf(intBuffer);

#ifndef __MEGA65__
    overlay1size = (unsigned)_OVERLAY1_SIZE__;
    overlay2size = (unsigned)_OVERLAY2_SIZE__;
    overlay3size = (unsigned)_OVERLAY3_SIZE__;
    overlay4size = (unsigned)_OVERLAY4_SIZE__;
    overlay5size = (unsigned)_OVERLAY5_SIZE__;
    overlay1blocks = overlay1size/BLOCK_LEN + (overlay1size % BLOCK_LEN ? 1 : 0);
    overlay2blocks = overlay2size/BLOCK_LEN + (overlay2size % BLOCK_LEN ? 1 : 0);
    overlay3blocks = overlay3size/BLOCK_LEN + (overlay3size % BLOCK_LEN ? 1 : 0);
    overlay4blocks = overlay4size/BLOCK_LEN + (overlay4size % BLOCK_LEN ? 1 : 0);
    overlay5blocks = overlay5size/BLOCK_LEN + (overlay5size % BLOCK_LEN ? 1 : 0);
#endif

    initBlockStorage();
    avail = getAvailChunks();
    initCommon();

#ifndef __MEGA65__
    // Allocate space in extended memory to cache the parser and parsertest overlays.
    // This is done so they don't have to be reloaded for each test.
    if (!allocBlockGroup(&tokenizerCache, overlay1blocks) ||
        !allocBlockGroup(&parserCache, overlay2blocks) ||
        !allocBlockGroup(&semanticCache, overlay3blocks) ||
        !allocBlockGroup(&objcodeCache, overlay4blocks) ||
        !allocBlockGroup(&linkerCache, overlay5blocks)) {
        printlnz("Unable to allocate extended memory");
        return;
    }

    printlnz("Loading tokenizer overlay");
    loadOverlayFromFile("compilertest.1", overlay1size, _OVERLAY1_LOAD__, tokenizerCache);
    printlnz("Loading parser overlay");
    loadOverlayFromFile("compilertest.2", overlay2size, _OVERLAY2_LOAD__, parserCache);
    printlnz("Loading semantic overlay");
    loadOverlayFromFile("compilertest", overlay3size, _OVERLAY3_LOAD__, semanticCache);
    printlnz("Loading objcode overlay");
    loadOverlayFromFile("compilertest.4", overlay4size, _OVERLAY4_LOAD__, objcodeCache);
    printlnz("Loading linker overlay");
    loadOverlayFromFile("compilertest.5", overlay5size, _OVERLAY5_LOAD__, linkerCache);
#endif

#ifdef __C128__
    fast();
    videomode(VIDEOMODE_80x25);
#endif
    bgcolor(COLOR_BLUE);
    textcolor(COLOR_WHITE);

    while (testFiles[i]) {
        char filename[16 + 1];
        CHUNKNUM tokenId, astRoot;

        strcpy(filename, testFiles[i]);
        strcat(filename, ".pas");

#ifndef __MEGA65__
        loadOverlayFromCache(overlay1size, _OVERLAY1_LOAD__, tokenizerCache);
#else
    if (!loadfile("compilertest.1")) {
        printlnz("Unable to load overlay from disk");
        exit(0);
    }
#endif
        puts(filename);
        printz("   T");
        tokenId = tokenize(filename);
        printz(" ");
        printz(formatInt16(avail - getAvailChunks()));
        printz(" ");

#ifndef __MEGA65__
        loadOverlayFromCache(overlay2size, _OVERLAY2_LOAD__, parserCache);
#else
    if (!loadfile("compilertest.2")) {
        printlnz("Unable to load overlay from disk");
        exit(0);
    }
#endif
        printz("P");
        astRoot = parse(tokenId);
        freeMemBuf(tokenId);

#ifndef __MEGA65__
        loadOverlayFromCache(overlay3size, _OVERLAY3_LOAD__, semanticCache);
#else
    if (!loadfile("compilertest.3")) {
        printlnz("Unable to load overlay from disk");
        exit(0);
    }
#endif
        printz("S");
        initSemantic();
        init_scope_stack();
        decl_resolve(astRoot, 0);
        set_decl_offsets(astRoot, 0, 0);
        decl_typecheck(astRoot);

#ifndef __MEGA65__
        loadOverlayFromCache(overlay5size, _OVERLAY5_LOAD__, linkerCache);
#else
    if (!loadfile("compilertest.5")) {
        printlnz("Unable to load overlay from disk");
        exit(0);
    }
#endif
        printz("W");
        linkerPreWrite();
#ifndef __MEGA65__
        loadOverlayFromCache(overlay4size, _OVERLAY4_LOAD__, objcodeCache);
#else
    if (!loadfile("compilertest.4")) {
        printlnz("Unable to load overlay from disk");
        exit(0);
    }
#endif
        printz("W");
        objCodeWrite(astRoot);
#ifndef __MEGA65__
        loadOverlayFromCache(overlay5size, _OVERLAY5_LOAD__, linkerCache);
#else
    if (!loadfile("compilertest.5")) {
        printlnz("Unable to load overlay from disk");
        exit(0);
    }
#endif
        printz("W");
        linkerPostWrite(testFiles[i], testFiles[i+1]);

        printz("F");
        decl_free(astRoot);
        free_scope_stack();
        printz("  ");
        printlnz(formatInt16(avail - getAvailChunks()));
        if (getAvailChunks() > avail) {
            return;
        }

        ++i;
    }

    printlnz("All tests have been generated.");
    printz("Press Enter to reset then load ");
    printlnz(testFiles[0]);
    getchar();
    __asm__ ("jmp ($fffc)");
}

unsigned char loadfile(const char *name)
{
    if (cbm_load(name, getcurrentdevice(), NULL) == 0) {
        log("main", "Loading overlay file failed");
        return 0;
    }

    return 1;
}

void log(const char *module, const char *message)
{
    printz(module);
    printz(": ");
    printlnz(message);
}

void logError(const char *message, unsigned lineNumber, TErrorCode ec)
{
    printz("*** ERROR: ");
    printz(message);
    printz(" -- line ");
    printz(formatInt16(lineNumber));
    printz(" -- code ");
    printlnz(formatInt16(ec));
}

void logFatalError(const char *message)
{
    printz("*** Fatal translation error: ");
    printlnz(message);
}

void logRuntimeError(const char *message, unsigned /*lineNumber*/)
{
    printz("*** Runtime error: ");
    printlnz(message);
}
