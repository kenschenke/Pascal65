/**
 * main.c
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Entry point for interpreter.
 * 
 * Copyright (c) 2022
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

#include <stdio.h>
#include <stdlib.h>
#include <ovrlcommon.h>
#include <buffer.h>
#include <scanner.h>
#include <parser.h>
#include <exec.h>
#include <error.h>
#include <cbm.h>
#include <device.h>
#include <common.h>
#include <blocks.h>
#include <formatter.h>

extern void _OVERLAY1_LOAD__[], _OVERLAY1_SIZE__[];
unsigned char loadfile(const char *name);

#if 1
extern char traceSym;
#endif

#if 1
char failCode;
#endif

void main()
{
    CHUNKNUM programId;

#ifdef __C128__
    fast();
    videomode(VIDEOMODE_80x25);
    printf("Is fast mode: %s\n", isfast() ? "yes" : "no");
#endif
    // bgcolor(COLOR_BLUE);
    // textcolor(COLOR_WHITE);

    // On the Mega65, $1600 - $1fff is available to use in the heap
#ifdef __MEGA65__
    _heapadd((void *)0x1600, 0x1fff - 0x1600);
#endif

#if 0
    printf("avail = %d\n", _heapmemavail());
    return;
#endif

    initBlockStorage();
    initCommon();
    initParser();

    programId = parse("test.pas");
    
    if (fmtOpen("output.pas") == 0) {
        printf("Unable to open output\n");
        return;
    }

    printf("Formatting output\n");
    fmtSource(programId);
    fmtClose();

    printf("Done\n");
}

unsigned char loadfile(const char *name)
{
    if (cbm_load(name, getcurrentdevice(), NULL) == 0) {
        return 0;
    }

    return 1;
}

void log(const char *module, const char *message)
{
    printf("%s: %s\n", module, message);
}

void logError(const char *message, unsigned lineNumber, TErrorCode code)
{
    printf("*** ERROR: %s -- line %d -- code %d\n", message, lineNumber, code);
    exit(0);
}

void logFatalError(const char *message)
{
    printf("*** Fatal translation error: %s\n", message);
}

void logRuntimeError(const char *message, unsigned /*lineNumber*/)
{
    printf("*** Runtime error: %s\n", message);
}

void outputLine(const char *message)
{
    printf("%s\n", message);
}

