#include <stdio.h>
#include <buffer.h>
#include <scanner.h>
#include <common.h>
#include <parser.h>
#include <symtab.h>
#include <stdlib.h>

struct TestCase {
    const char *source;
    TErrorCode code;
    unsigned lineNumber;
};

static struct TestCase cases[] = {
#ifdef MAINPAS
    {"main.pas", 0, 0},
#endif
#ifdef TESTPROG
    {"missingprog.pas", errMissingPROGRAM, 3},
    {"missingpid.pas", errMissingIdentifier, 3},
    {"badprogvar.pas", errMissingIdentifier, 3},
#endif
    {NULL},
};

static TErrorCode expectedCode;
static unsigned expectedLineNumber;

static int sawCode;
static int testsRun;
static int testsFail;

void logError(const char *message, unsigned lineNumber, TErrorCode code)
{
#ifdef MAINPAS
    printf("*** ERROR: %s line %d\n", message, lineNumber);
#else
    if (code == expectedCode && lineNumber == expectedLineNumber) {
        sawCode = 1;
    }
#endif
}

void logFatalError(const char *message)
{
    printf("*** Fatal translation error: %s\n", message);
}

void logRuntimeError(const char *message, unsigned lineNumber)
{
    printf("*** Runtime error: %s\n", message);
}

#if 1
char failCode;
#endif

int main()
{
    int i = 0;
    TINBUF *tinBuf;
    SCANNER scanner;

    testsRun = 0;
    testsFail = 0;

    while (1) {
        if (!cases[i].source) {
            break;
        }

        initBlockStorage();
        initCommon();
        initParser();

        sawCode = 0;
        expectedCode = cases[i].code;
        expectedLineNumber = cases[i].lineNumber;

        tinBuf = tin_open(cases[i].source, abortSourceFileOpenFailed);
        scanner.pTinBuf = tinBuf;
        parse(&scanner);
        tin_close(tinBuf);

#ifndef MAINPAS
        if (!sawCode) {
            printf("source: %s\n", cases[i].source);
            printf("   *** ERROR: never saw code %d on line %d\n",
                expectedCode, expectedLineNumber);
            ++testsFail;
        }
#endif

        ++i;
    }

    printf("%d test%s run\n", i, i == 1 ? "" : "s");
    printf("%d test%s failed\n", testsFail, testsFail == 1 ? "" : "s");

	return 0;
}
