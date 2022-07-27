/*** includes ***/

#include "editor.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#define KED_VERSION "0.0.1"

/**
 * TODO:
 * 
 * Add support for multiple files and show welcome page when no files are open
 * Update initial status message
 * Load and save files
 * Make find case insensitive
 * Change the unsaved exit procedure to ask a confirmation question
 * Help page
 * 
 */

/*** defines ***/

#if 0
int showKeyCodes(void) {
    char buf[3+1];
    char c = editorReadKey();
    if (c == 'q') {
        return 1;
    }

    sprintf(buf, "%3d", c);
    drawRow(10, 3, buf, NULL);
    return 0;
}
#endif

int main(int argc, char *argv[])
{
    // On the Mega65, $1600 - $1fff is available to use in the heap
    _heapadd((void *)0x1600, 0x1fff - 0x1600);

    initEditor();
    if (argc >= 2) {
        // editorOpen(argv[1]);
    }

#if 0
    while (!showKeyCodes());
    return 0;
#endif

#if 1
    editorOpen("help.txt");
#endif

    E.welcomePage =
        "Welcome To Ked Version " KED_VERSION "\r"
        "\r"
        "Copyright 2022 by Ken Schenke\r"
        "kenschenke@gmail.com";

    editorRun();

    return 0;
}
