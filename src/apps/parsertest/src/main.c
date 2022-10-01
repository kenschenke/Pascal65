#include <stdio.h>
#include <buffer.h>
#include <scanner.h>
#include <common.h>
#include <parser.h>
#include <symtab.h>
#include <stdlib.h>

void logError(const char *message, unsigned lineNumber, TErrorCode code)
{
    printf("*** ERROR: %s, line %d\n", message, lineNumber);
}

void logFatalError(const char *message)
{
    printf("*** Fatal translation error: %s\n", message);
}

void logRuntimeError(const char *message, unsigned lineNumber)
{
    printf("*** Runtime error: %s\n", message);
}

int main()
{
    TINBUF *tinBuf;
    SCANNER scanner;

    initBlockStorage();
    initCommon();
    initParser();

    printf("heapMemAvail = %d\n", _heapmemavail());

    tinBuf = tin_open("scopeerr.pas", abortSourceFileOpenFailed);
    scanner.pTinBuf = tinBuf;
    parse(&scanner);
    printf("made it!\n");
    tin_close(tinBuf);

	return 0;
}
