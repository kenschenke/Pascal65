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

void testWriteInt8(char);
void testWriteUint8(unsigned char);
void testWriteInt16(int);
void testWriteUint16(unsigned);
void testWriteInt32(long);
void testWriteUint32(unsigned long);
long testMultInt32(long num1, long num2);
long testDivInt32(long num1, long num2);

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
    printf("Is fast mode: %s\n", isfast() ? "yes" : "no");
#endif
    bgcolor(COLOR_BLUE);
    textcolor(COLOR_WHITE);
    printf("Loading tokenizer overlay\n");

    if (loadfile("compiler.1")) {
        tokenId = tokenize("hello.pas");
    }

    printf("Loading parser overlay\n");
    if (loadfile("compiler.2")) {
        astRoot = parse(tokenId);
        freeMemBuf(tokenId);
    }

    if (errors) {
        return;
    }

    printf("Loading semantic overlay\n");
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

    printf("Loading linker overlay\n");
    if (loadfile("compiler.5")) {
        linkerPreWrite();
    }

    if (errors) {
        return;
    }

    printf("Loading objcode overlay\n");
    if (loadfile("compiler.4")) {
        objCodeWrite(astRoot);
    }

    if (errors) {
        return;
    }

    printf("Loading linker overlay\n");
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
    printf("%s: %s\n", module, message);
}

void logError(const char *message, unsigned lineNumber, TErrorCode ec)
{
    printf("*** ERROR: %s -- line %d -- code %d\n", message, lineNumber, ec);
    ++errors;
    exit(0);
}

void logFatalError(const char *message)
{
    printf("*** Fatal translation error: %s\n", message);
    ++errors;
}

void logRuntimeError(const char *message, unsigned /*lineNumber*/)
{
    printf("*** Runtime error: %s\n", message);
    ++errors;
}
