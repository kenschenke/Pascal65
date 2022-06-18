#include <stdio.h>
#include <ovrlcommon.h>
#include <ovrlinterp.h>
#include <ovrlcomp.h>
#include <cbm.h>
#include <device.h>
#include <conio.h>

extern void _OVERLAY1_LOAD__[], _OVERLAY1_SIZE__[];
extern void _OVERLAY2_LOAD__[], _OVERLAY2_SIZE__[];
unsigned char loadfile(const char *name);

void main()
{
#ifdef __C128__
    fast();
    videomode(VIDEOMODE_80x25);
    printf("Is fast mode: %s\n", isfast() ? "yes" : "no");
#endif
    bgcolor(COLOR_BLUE);
    textcolor(COLOR_WHITE);
    printf("Loading compiler overlay\n");
    if (loadfile("pascal65.1")) {
        overlayCompiler();
    }

    printf("Loading interpreter overlay\n");
    if (loadfile("pascal65.2")) {
        overlayInterpreter();
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
