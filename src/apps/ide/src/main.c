#include <stdio.h>
#include <ovrlcommon.h>
#include <cbm.h>
#include <device.h>
#include <editor.h>
#include <stdlib.h>
#include <string.h>
#include <libcommon.h>

extern void _OVERLAY1_LOAD__[], _OVERLAY1_SIZE__[];
extern void _OVERLAY2_LOAD__[], _OVERLAY2_SIZE__[];
extern void _OVERLAY3_LOAD__[], _OVERLAY3_SIZE__[];
unsigned char loadfile(const char *name);

void logError(const char *message, unsigned lineNumber, TErrorCode code)
{
    printz("*** ERROR: ");
    printlnz(message);
}

void logFatalError(const char *message)
{
    printz("*** Fatal error: ");
    printlnz(message);
}

void logRuntimeError(const char *message, unsigned lineNumber)
{
    printz("*** Runtime error: ");
    printlnz(message);
}

void outputLine(const char *message)
{
    printlnz(message);
}

void parserOverlay(void);

void main()
{
#ifdef __C128__
    fast();
    videomode(VIDEOMODE_80x25);
    printf("Is fast mode: %s\n", isfast() ? "yes" : "no");
#endif
    // bgcolor(COLOR_BLUE);
    // textcolor(COLOR_WHITE);
    printlnz("Loading editor overlay");

#ifdef __MEGA65
    // On the Mega65, $1600 - $1fff is available to use in the heap
    _heapadd((void *)0x1600, 0x1fff - 0x1600);
#endif

#if 0
    printf("avail = %d\n", _heapmemavail());
    return;
#endif

    initBlockStorage();

#if 1
    if (loadfile("pascal65.4")) {
        initEditor();
        editorSetDefaultStatusMessage();
        // E.cbExitRequested = handleExitRequested;
        // E.cbKeyPressed = handleKeyPressed;
        // E.cbExitRequested = handleExitRequested;
        // if (argc >= 2) {
        //     int i;
        //     for (i = 1; i < argc; ++i)
        //         editorOpen(argv[i], 0);
        // }

        E.welcomePage =
            "Welcome To Pascal65 Version " "XXX" "\r"
            "\r"
            "Copyright 2022-2023 by Ken Schenke\r"
            "kenschenke@gmail.com\r"
            "github.com/kenschenke/Pascal65\r"
            "\r"
            "Pascal compiler based on the book\r"
            "\"Writing Compilers and Interpreters:\r"
            "A Software Engineering Approach\"\r"
            "Second Edition\r"
            "by Ronald Mak"
            "\r";
        
        updateStatusBarFilename();
        editorRun();
    }
#endif

#if 0
    printf("Loading compiler overlay\n");
    if (loadfile("pascal65.1")) {
        parserOverlay();
    }
#endif

    // printf("Loading interpreter overlay\n");
    // if (loadfile("pascal65.2")) {
    //     overlayInterpreter();
    // }

    // log("main", "back to main code");
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
