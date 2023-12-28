#include <stdio.h>
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
#include <int16.h>
#include <membuf.h>

#include <string.h>
#include <libcommon.h>

extern void _OVERLAY1_LOAD__[], _OVERLAY1_SIZE__[];
unsigned char loadfile(const char *name);

char intBuf[15];

static char errors;

void runPrg(void) {}

void main()
{
    CHUNKNUM tokenId, astRoot;

    setIntBuf(intBuf);

#if 0
    printz("avail ");
    printlnz(formatInt16(_heapmemavail()));
    return;
#endif

    initBlockStorage();
    initCommon();

#ifdef __C128__
    fast();
    videomode(VIDEOMODE_80x25);
#endif
    bgcolor(COLOR_BLUE);
    textcolor(COLOR_WHITE);
    printlnz("Loading tokenizer overlay");

    if (loadfile("compiler.1")) {
        tokenId = tokenize("hello.pas");
    }

    printlnz("Loading parser overlay");
    if (loadfile("compiler.2")) {
        astRoot = parse(tokenId);
        freeMemBuf(tokenId);
    }

    if (errors) {
        return;
    }

    printlnz("Loading semantic overlay");
    if (loadfile("compiler.3")) {
        initSemantic();
        init_scope_stack();
        decl_resolve(astRoot, 0);
        set_decl_offsets(astRoot, 0, 0);
        decl_typecheck(astRoot);
    }

    if (errors) {
        return;
    }

    printlnz("Loading linker overlay");
    if (loadfile("compiler.5")) {
        linkerPreWrite();
    }

    if (errors) {
        return;
    }

    printlnz("Loading objcode overlay");
    if (loadfile("compiler.4")) {
        objCodeWrite(astRoot);
    }

    if (errors) {
        return;
    }

    printlnz("Loading linker overlay");
    if (loadfile("compiler.5")) {
        linkerPostWrite("hello", 0);
    }

    log("main", "back to main code");
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
    ++errors;
    exit(0);
}

void logFatalError(const char *message)
{
    printz("*** Fatal translation error: ");
    printlnz(message);
    ++errors;
}

void logRuntimeError(const char *message, unsigned /*lineNumber*/)
{
    printz("*** Runtime error: ");
    printlnz(message);
    ++errors;
}
