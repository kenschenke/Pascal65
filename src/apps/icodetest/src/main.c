#include <stdio.h>
#include <blocks.h>
#include <chunks.h>
#include <stdlib.h>
#include "icodetest.h"

short currentLineNumber;

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

void initStandardRoutines(void) {
    
}

int main()
{
    initBlockStorage();
    initMemBufCache();
    testIcodePosition();

    initBlockStorage();
    initMemBufCache();
    testIcodeGotoPosition();

    initBlockStorage();
    initMemBufCache();
    testIcodeToken();

    initBlockStorage();
    initMemBufCache();
    testIcodeSymtabNode();

    printf("Done with tests\n");

	return 0;
}
