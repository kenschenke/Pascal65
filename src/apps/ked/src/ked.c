/**
 * ked.c
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Entry point and file screen for Ked.
 * 
 * Copyright (c) 2022
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

#include "editor.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdarg.h>
#include <blocks.h>
#include <conio.h>
#include <cbm.h>
#include <doscmd.h>
#include <unistd.h>

#define KED_VERSION "0.0.1"

static CHUNKNUM selectedFile;

static char filePage;
static int openFiles;

static void cycleCurrentDevice(void);
static char handleExitRequested(void);
static void handleFiles(void);
char handleKeyPressed(int key);
static void openHelpFile(void);
static void showFileScreen(void);
static void switchToFile(char num);

static void cycleCurrentDevice(void) {
    int dev = getCurrentDrive() + 1;
    char buf[4+1];
    if (dev > 9) {
        dev = 8;
    }

    sprintf(buf, "%d", dev);
    chdir(buf);
}

static char handleExitRequested(void) {
    CHUNKNUM chunkNum = E.firstFileChunk;
    efile file;
    int ch;

    storeChunk(E.cf.fileChunk, (unsigned char *)&E.cf);

    while (chunkNum) {
        retrieveChunk(chunkNum, (unsigned char *)&file);
        if (file.dirty) {
            while (1) {
                drawStatusRow(COLOUR_RED, 0, "Unsaved files. Exit anyway? Y/N");
                ch = editorReadKey();
                if (ch == 'y' || ch == 'Y') {
                    return 1;
                } else if (ch == 'n' || ch == 'N' || ch == CH_ESC) {
                    clearStatusRow();
                    return 0;
                }
            }
        }

        chunkNum = file.nextFileChunk;
    }

    return 1;
}

static void handleFiles(void) {
    int key;

    editorSetStatusMessage("O=Open, S=Save, N=New, C=Close, M=More");
    editorRefreshScreen();

    while(1) {
        key = editorReadKey();
        if (key == 'm' || key == 'M') {
            selectedFile = E.cf.fileChunk;
            filePage = 0;
            openFiles = 0;
            showFileScreen();
        } else if (key == 'c' || key == 'C') {
            closeFile();
            clearScreen();
            editorSetAllRowsDirty();
            return;
        } else if (key == 'n' || key == 'N') {
            editorNewFile();
            clearScreen();
            editorSetAllRowsDirty();
            return;
        } else if (key == 's' || key == 'S' || key == CTRL_KEY('s')) {
            if (saveFile()) {
                return;
            }
        } else if (key == 'a' || key == 'A') {
            if (saveAs()) {
                clearScreen();
                editorSetAllRowsDirty();
                return;
            }
        } else if (key == 'o' || key == 'O') {
            openFile();
            if (E.cf.fileChunk) {
                clearScreen();
                editorSetAllRowsDirty();
                return;
            } else {
                drawStatusRow(COLOUR_RED, 1, "Unable to open file");
            }
        } else if (key == BACKARROW || key == CH_ESC) {
            clearScreen();
            editorSetAllRowsDirty();
            return;
        } else if (key >= '1' && key <= '9') {
            switchToFile(key - '0');
            clearScreen();
            editorSetAllRowsDirty();
            return;
        } else if (key == 'd' || key == 'D') {
            cycleCurrentDevice();
            showFileScreen();
        } else if (key == CH_CURS_LEFT) {
            if (filePage > 0) {
                --filePage;
                showFileScreen();
            }
        } else if (key == CH_CURS_RIGHT) {
            if (filePage < openFiles / 9 - (openFiles % 9 ? 0 : 1)) {
                ++filePage;
                showFileScreen();
            }
        }
    }
}

char handleKeyPressed(int key) {
    char ret = 0;

    if (key == HELP_KEY) {
        clearCursor();
        openHelpFile();
        ret = 1;
    } else if (key == BACKARROW) {
        ret = 1;
        handleFiles();
    } else if (key == CTRL_KEY('o')) {
        openFile();
        if (E.cf.fileChunk) {
            clearScreen();
            editorSetAllRowsDirty();
            ret = 1;
        }
    } else if (key == CTRL_KEY('s')) {
        saveFile();
    }

    return ret;
}

static void openHelpFile(void) {
    char buf[CHUNK_LEN];

    editorOpen("help.txt", 1);
    strcpy(buf, "Help File");
    allocChunk(&E.cf.filenameChunk);
    storeChunk(E.cf.filenameChunk, (unsigned char *)buf);
    storeChunk(E.cf.fileChunk, (unsigned char *)&E.cf);
}

static void showFileScreen(void) {
    int i, n, count;
    char y, page;
    char buf[CHUNK_LEN * 2];
    char chunk[CHUNK_LEN];
    efile file;
    CHUNKNUM chunkNum;

    clearCursor();
    clearScreen();

    if (E.cf.fileChunk) {
        storeChunk(E.cf.fileChunk, (unsigned char *)&E.cf);
    }

    drawRow(1, 3, 29, "Open Files (* = Current File)", 0);

    // Render a list of open files
    chunkNum = E.firstFileChunk;
    y = 3;
    i = 0;
    page = 0;
    count = 0;
    if (chunkNum == 0) {
        drawRow(y, 7, 13, "No files open", 0);
    } else {
        while (chunkNum) {
            ++count;
            ++i;
            if (i > 9) {
                ++page;
                i = 1;
            }

            retrieveChunk(chunkNum, (unsigned char *)&file);

            if (page == filePage) {
                if (file.filenameChunk) {
                    retrieveChunk(file.filenameChunk, (unsigned char *)chunk);
                } else {
                    strcpy(chunk, "No filename");
                }
                n = snprintf(buf, sizeof(buf), "%c%2d: %s%s",
                    chunkNum == selectedFile ? '*' : ' ', i, chunk,
                    file.dirty ? " (modified)" : "");
                drawRow(y++, 7, n, buf, 0);
            }

            chunkNum = file.nextFileChunk;
        }
    }

    y = 12;
    openFiles = count;

    if (count) {
        ++y;
        n = snprintf(buf, sizeof(buf), "%d file%s open",
            count, count == 1 ? "": "s");
        drawRow(y++, 3, n, buf, 0);
        drawRow(y++, 3, 29, "Type number to switch to file", 0);
        if (count > 9) {
            n = snprintf(buf, sizeof(buf), "Showing files %d - %d",
                filePage * 9 + 1, count >= (filePage+1)*9 ? filePage * 9 + 9 : count);
            drawRow(y++, 3, n, buf, 0);
            drawRow(y++, 3, 37, "Left / right arrows to see more files", 0);
        }
    }

    ++y;
    drawRow(y++, 3, 34, "O: Open  C: Close  S: Save  N: New", 0);

    n = snprintf(buf, sizeof(buf), "A: Save As  D: Device (Currently %d)",
        getCurrentDrive());
    drawRow(y++, 3, n, buf, 0);

    drawRow(y, 3, 19, "\x1f  Return To Editor", 0);
}

// num is 1 - 9 on current page
static void switchToFile(char num) {
    char page = 0;
    int i = 0;
    CHUNKNUM chunkNum;
    efile file;

    chunkNum = E.firstFileChunk;
    while (chunkNum) {
        ++i;
        if (i > 9) {
            ++page;
            i = 1;
        }

        if (page == filePage && i == num) {
            if (chunkNum != E.cf.fileChunk) {
                storeChunk(E.cf.fileChunk, (unsigned char *)&E.cf);
                retrieveChunk(chunkNum, (unsigned char *)&E.cf);
                clearScreen();
                editorSetAllRowsDirty();
                return;
            }
        }

        retrieveChunk(chunkNum, (unsigned char *)&file);
        chunkNum = file.nextFileChunk;
    }
}

int main(int argc, char *argv[])
{
    // On the Mega65, $1600 - $1fff is available to use in the heap
    _heapadd((void *)0x1600, 0x1fff - 0x1600);

    initBlockStorage();

    initEditor();
    editorSetStatusMessage("Ctrl-O: open  Ctrl-X: quit  Press HELP");
    E.cbKeyPressed = handleKeyPressed;
    E.cbExitRequested = handleExitRequested;
    if (argc >= 2) {
        int i;
        for (i = 1; i < argc; ++i)
            editorOpen(argv[i], 0);
    }

    E.welcomePage =
        "Welcome To Ked Version " KED_VERSION "\r"
        "\r"
        "Copyright 2022 by Ken Schenke\r"
        "kenschenke@gmail.com\r"
        "github.com/kenschenke/Pascal65\r"
        "\r"
        "Based on\r"
        "\r"
        "\"Build Your Own Text Editor\"\r"
        "viewsourcecode.org/snaptoken/kilo/\r"
        "\r"
        "And\r"
        "\r"
        "antirez's Kilo editor\r"
        "antirez.com/news/108\r";
    
    editorRun();

    return 0;
}
