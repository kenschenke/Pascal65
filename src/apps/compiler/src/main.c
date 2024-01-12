#include <stdio.h>
#include <stdlib.h>
#include <ovrlcommon.h>
#include <cbm.h>
#include <device.h>
#include <conio.h>
#include <common.h>
#include <chunks.h>
#include <parser.h>
#include <resolver.h>
#include <typecheck.h>
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

static void tokenizeAndParseUnits(void)
{
    char any, filename[16 + 1];
    struct unit _unit;
    CHUNKNUM chunkNum, unitTokens;

    while (1) {
        chunkNum = units;
        any = 0;
        while (chunkNum) {
            retrieveChunk(chunkNum, &_unit);
            if (!_unit.astRoot) {
                any = 1;
                strcpy(filename, _unit.name);
                strcat(filename, ".pas");

                loadfile("compiler.1");
                unitTokens = tokenize(filename);

                loadfile("compiler.2");
                _unit.astRoot = parse(unitTokens);
                freeMemBuf(unitTokens);
                storeChunk(chunkNum, &_unit);
            }

            chunkNum = _unit.next;
        }

        if (!any) {
            break;
        }
    }
}

void main()
{
    CHUNKNUM tokenId, astRoot;
    short offset = 0;

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

    tokenizeAndParseUnits();

    if (errors) {
        return;
    }

    printlnz("Loading resolver overlay");
    if (loadfile("compiler.3")) {
        init_scope_stack();
        resolve_units();
        decl_resolve(astRoot, 0);
        offset = set_decl_offsets(astRoot, 0, 0);
        set_unit_offsets(units, offset);
        fix_global_offsets(astRoot);
    }

    printlnz("Loading typecheck overlay");
    if (loadfile("compiler.4")) {
        decl_typecheck(astRoot);
        typecheck_units();
    }

    if (errors) {
        return;
    }

    printlnz("Loading linker overlay");
    if (loadfile("compiler.6")) {
        linkerPreWrite(astRoot);
    }

    if (errors) {
        return;
    }

    printlnz("Loading objcode overlay");
    if (loadfile("compiler.5")) {
        objCodeWrite(astRoot);
    }

    if (errors) {
        return;
    }

    printlnz("Loading linker overlay");
    if (loadfile("compiler.6")) {
        linkerPostWrite("hello", 0);
    }

    decl_free(astRoot);
    free_scope_stack();
    freeCommon();

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
