#include <stdio.h>
#include <ovrlinterp.h>
#include <ovrlcommon.h>
#include <buffer.h>
#include <scanner.h>
#include <parser.h>
#include <error.h>
#include <cbm.h>
#include <device.h>
#include <conio.h>

extern void _OVERLAY1_LOAD__[], _OVERLAY1_SIZE__[];
unsigned char loadfile(const char *name);

void main()
{
    TINBUF *tinBuf;
    SCANNER scanner;

#ifdef __C128__
    fast();
    videomode(VIDEOMODE_80x25);
    printf("Is fast mode: %s\n", isfast() ? "yes" : "no");
#endif
    bgcolor(COLOR_BLUE);
    textcolor(COLOR_WHITE);
    printf("Loading interpreter overlay\n");
    if (loadfile("interpreter.1")) {
        tinBuf = tin_open("hello.pas", abortSourceFileOpenFailed);
        scanner.pTinBuf = tinBuf;
        parse(&scanner);
        overlayInterpreter();
        tin_close(tinBuf);
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

void logError(const char *message, unsigned lineNumber)
{
    printf("*** ERROR: %s\n", message);
}

void logFatalError(const char *message)
{
    printf("*** Fatal translation error: %s\n", message);
}
