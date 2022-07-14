/*** includes ***/

#include "editor.h"
#include <ctype.h>
#include <errno.h>
#include <conio.h>
#include <stdio.h>
#include <stdarg.h>
#include <stdlib.h>
#include <string.h>

#define KED_VERSION "0.0.1"

/**
 * TODO:
 * 
 * Load and save files
 * Make find case insensitive
 * Drop "Kilo" name
 * Change the unsaved exit procedure to ask a confirmation question
 * Help page
 * Add function prototypes to top of file
 * 
 */

/*** defines ***/

int showKeyCodes(void) {
    char buf[3+1];
    unsigned char rev[3];
    char c = editorReadKey();
    if (c == 'q') {
        return 1;
    }

    sprintf(buf, "%3d", c);
    memset(rev, 0, 3);
    drawRow(10, 3, buf, rev);
    return 0;
}

int main(int argc, char *argv[])
{
    int i, len;
    char buf[80];

    initEditor();
    if (argc >= 2) {
        // editorOpen(argv[1]);
    }

#if 0
    while (!showKeyCodes());
    return 0;
#endif

#if 0
    editorOpen("help.txt");
    E.readOnly = 0;
#endif

#if 0
    for (i = 1; i <= 46; ++i) {
        len = sprintf(buf, "%*sEditor Row %d", i % 50, " ", i);
        editorInsertRow(i-1, buf, len);
    }
    E.dirty = 0;
#endif

    editorSetStatusMessage("HELP: Ctrl-S = save | Ctrl-Q = quit | Ctrl-F = find");

#if 1
    E.welcomePage =
        "Welcome To Ked Version " KED_VERSION "\r"
        "\r"
        "Copyright 2022 by Ken Schenke\r"
        "kenschenke@gmail.com";
    E.readOnly = 1;
    E.filename = "Welcome";
#endif

    while (!E.quit) {
        editorRefreshScreen();
        editorProcessKeypress();
    }

    clearScreen();
    gotoxy(0, 0);

    return 0;
}
