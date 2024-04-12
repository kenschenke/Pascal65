/**
 * main.c
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Entry point for command-line compiler.
 * 
 * Copyright (c) 2024
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

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
#include <codegen.h>

#include <string.h>
#include <libcommon.h>

#ifdef __MEGA65__
#include <doscmd.h>
#endif

#define AUTORUN "autorun"
#define AUTOSRC "autosrc"
#define EDITOR_STATE "zzstate"

extern void _OVERLAY1_LOAD__[], _OVERLAY1_SIZE__[];
unsigned char loadfile(const char *name);
static void checkSrcFn(const char *str);
static void handleErrors(void);
static char hasEditorState(void);
static void readAutoSrc(void);
static void relaunchIde(void);

void waitforkey(void);

char isAutoRun;     // non-zero to run program after compiling
char srcFn[16 + 1]; // source filename
char intBuf[15];

static char errors;

static void checkSrcFn(const char *str)
{
    if (strlen(str) > sizeof(srcFn)) {
        printlnz("Source filename too long");
        abortTranslation(abortSourceLineTooLong);
        exit(5);
    }

    strcpy(srcFn, str);
}

static void handleErrors(void)
{
    if (hasEditorState()) {
        printz("\nPress a key...");
        waitforkey();
        relaunchIde();
    }
}

static char hasEditorState(void)
{
    FILE *fh;

    fh = fopen(EDITOR_STATE, "r");
    if (fh == NULL) {
        return 0;
    }

    fclose(fh);
    return 1;
}

static void readAutoSrc(void)
{
    FILE *fp;
    char *p, buffer[50];

    fp = fopen(AUTORUN, "r");
    if (fp == NULL) {
        fp = fopen(AUTOSRC, "r");
        if (fp == NULL) {
            return;
        }
    } else {
        isAutoRun = 1;
    }

    fgets(buffer, sizeof(buffer), fp);
    fclose(fp);
#ifdef __MEGA65__
    if (isAutoRun) {
        removeFile(AUTORUN);
    } else {
        removeFile(AUTOSRC);
    }
#else
    if (isAutoRun) {
        remove(AUTORUN);
    } else {
        remove(AUTOSRC);
    }
#endif

    p = buffer + strlen(buffer) - 1;
    while (*p == '\n') {
        if (p > buffer) *(p--) = 0; else break;
    }

    checkSrcFn(buffer);
}

void loadproghelper(const char *prg);

static void relaunchIde(void)
{
    FILE *fp = fopen(EDITOR_STATE, "r");

    if (fp == NULL) {
        return;
    }
    fclose(fp);

    loadfile("loadprog");
    loadproghelper("pascal65");
}

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

void main(int argc, char *argv[])
{
    CHUNKNUM tokenId, astRoot;
    short offset = 0;

    srcFn[0] = 0;
    // Check command line first
    if (argc > 1) {
        checkSrcFn(argv[1]);
    }

    // If no filename supplied on the command line, try the autosrc.
    if (!srcFn[0]) {
        readAutoSrc();
    }

    // If a source file was not provided on the command line or autosrc, prompt for one.
    if (!srcFn[0]) {
        char buffer[50];

        printz("Source file: ");
        gets(buffer);
        checkSrcFn(buffer);
    }

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
    printlnz("Tokenizing");

    if (loadfile("compiler.1")) {
        tokenId = tokenize(srcFn);
    }

    printlnz("Parsing");
    if (loadfile("compiler.2")) {
        astRoot = parse(tokenId);
        freeMemBuf(tokenId);
    }

    if (errors) {
        handleErrors();
        return;
    }

    tokenizeAndParseUnits();

    if (errors) {
        handleErrors();
        return;
    }

    printlnz("Resolving");
    if (loadfile("compiler.3")) {
        init_scope_stack();
        resolve_units();
        decl_resolve(astRoot, 0);
        offset = set_decl_offsets(astRoot, 0, 0);
        set_unit_offsets(units, offset);
        fix_global_offsets(astRoot);
    }

    if (errors) {
        handleErrors();
        return;
    }

    printlnz("Type checking");
    if (loadfile("compiler.4")) {
        decl_typecheck(astRoot);
        typecheck_units();
    }

    if (errors) {
        handleErrors();
        return;
    }

    if (loadfile("compiler.6")) {
        linkerPreWrite(astRoot);
    }

    if (errors) {
        handleErrors();
        return;
    }

    printlnz("Writing code");
    if (loadfile("compiler.5")) {
        objCodeWrite(astRoot);
    }

    if (errors) {
        handleErrors();
        return;
    }

    printlnz("Linking code");
    if (loadfile("compiler.6")) {
        linkerPostWrite(srcFn, isAutoRun, astRoot);
    }

    free_scope_stack();
    freeCommon();

    printlnz("Done");

    log("main", "back to main code");

    relaunchIde();
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

void logError(const char *message, unsigned lineNumber, TErrorCode /*ec*/)
{
    printz("*** ERROR: ");
    printz(message);
    printz(" -- line ");
    printlnz(formatInt16(lineNumber));
    ++errors;
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
