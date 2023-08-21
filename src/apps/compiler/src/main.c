#include <stdio.h>
#include <ovrlcommon.h>
#include <cbm.h>
#include <device.h>
#include <conio.h>
#include <common.h>
#include <chunks.h>
#include <parser.h>
#include <semantic.h>
#include <codegen.h>

extern void _OVERLAY1_LOAD__[], _OVERLAY1_SIZE__[];
unsigned char loadfile(const char *name);

void main()
{
    CHUNKNUM tokenId, astRoot;

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

    printf("Loading semantic overlay\n");
    if (loadfile("compiler.3")) {
        initSemantic();
        init_scope_stack();
        decl_resolve(astRoot, 0);
        set_decl_offsets(astRoot, 0, 0);
        decl_typecheck(astRoot);
    }

    printf("Loading code generation overlay\n");
    if (loadfile("compiler.4")) {
        genProgram(astRoot);
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
}

void logFatalError(const char *message)
{
    printf("*** Fatal translation error: %s\n", message);
}

void logRuntimeError(const char *message, unsigned /*lineNumber*/)
{
    printf("*** Runtime error: %s\n", message);
}
