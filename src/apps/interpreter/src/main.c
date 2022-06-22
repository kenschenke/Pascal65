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
#include <conio.h>
#include <common.h>

extern void _OVERLAY1_LOAD__[], _OVERLAY1_SIZE__[];
unsigned char loadfile(const char *name);

void main()
{
    TINBUF *tinBuf;
    SCANNER scanner;
    EXECUTOR *pExec;

#ifdef __C128__
    fast();
    videomode(VIDEOMODE_80x25);
    printf("Is fast mode: %s\n", isfast() ? "yes" : "no");
#endif
    bgcolor(COLOR_BLUE);
    textcolor(COLOR_WHITE);

    // load the parser
    printf("Loading parser module\n");
    if (loadfile("interpreter.1")) {
        initCommon();

        tinBuf = tin_open("expr1.in", abortSourceFileOpenFailed);
        scanner.pTinBuf = tinBuf;
        printf("Parsing Source File\n");
        parse(&scanner);
        tin_close(tinBuf);
    }

    // If there were no syntax errors, convert the symbol tables.
    // and create and invoke the backend executor.
    if (errorCount > 0 || isFatalError) {
        printf("Errors found in parsing -- exiting\n");
        return;
    }
    convertAllSymtabs();
    
    printf("Loading executor module\n");
    if (loadfile("interpreter.2")) {
        pExec = executorInit();
        executorGo(pExec);
        freeAllSymtabs();

        executorFree(pExec);
    }
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

void logError(const char *message, unsigned lineNumber)
{
    printf("*** ERROR: %s\n", message);
}

void logFatalError(const char *message)
{
    printf("*** Fatal translation error: %s\n", message);
}

void logRuntimeError(const char *message, unsigned lineNumber)
{
    printf("*** Runtime error: %s\n", message);
}

void outputLine(const char *message)
{
    printf("%s\n", message);
}

