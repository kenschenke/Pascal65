/**
 * filescreen.c
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * File screen for editor
 * 
 * Copyright (c) 2024
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

#include <stdio.h>
#include <string.h>
#include <editor.h>
#include <doscmd.h>
#include <unistd.h>
#include <int16.h>

#ifdef __C128__
#include <c128.h>
#endif
#include <conio.h>

#ifdef __MEGA65__
#include <cbm.h>
#endif

static void cycleCurrentDevice(void);
static void showFileScreen(void);
static void switchToFile(char num);

#ifdef __MEGA65__
char fixAlphaCase(char);
#endif

static CHUNKNUM selectedFile;
static char filePage;
static int openFiles;

static void cycleCurrentDevice(void) {
    int dev = getCurrentDrive() + 1;
    if (dev > 9) {
        dev = 8;
    }

    chdir(formatInt16(dev));
}

char handleFiles(void) {
    int key;

    while(1) {
        key = cgetc();
#ifdef __MEGA65__
        key = fixAlphaCase(key);
#endif
        if (key == 'm' || key == 'M') {
            selectedFile = E.cf.fileChunk;
            filePage = 0;
            openFiles = 0;
            showFileScreen();
        } else if (key == 'c' || key == 'C') {
            return FILESCREEN_CLOSEFILE;
        } else if (key == 'n' || key == 'N') {
            return FILESCREEN_NEWFILE;
        } else if (key == 's' || key == 'S' || key == CTRL_KEY('s')) {
            if (saveFile()) {
                return FILESCREEN_SAVEFILE;
            }
        } else if (key == 'a' || key == 'A') {
            if (saveAs()) {
                return FILESCREEN_SAVEASFILE;
            }
        } else if (key == 'o' || key == 'O') {
            return FILESCREEN_OPENFILE;
        } else if (key == BACKARROW || key == CH_ESC) {
            return FILESCREEN_BACK;
        } else if (key >= '1' && key <= '9') {
            switchToFile(key - '0');
            return FILESCREEN_SWITCHTOFILE;
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
                buf[n=0] = chunkNum == selectedFile ? '*' : ' ';
                if (i < 10) {
                    buf[++n] = ' ';
                }
                buf[++n] = 0;
                strcat(buf, formatInt16(i));
                strcat(buf, ": ");
                strcat(buf, chunk);
                if (file.dirty) {
                    strcat(buf, " (modified)");
                }
                n = strlen(buf);
                drawRow(y++, 7, n, buf, 0);
            }

            chunkNum = file.nextFileChunk;
        }
    }

    y = 12;
    openFiles = count;

    if (count) {
        ++y;
        strcpy(buf, formatInt16(count));
        strcat(buf, " file");
        if (count != 1) {
            strcat(buf, "s");
        }
        strcat(buf, " open");
        n = strlen(buf);
        drawRow(y++, 3, n, buf, 0);
        drawRow(y++, 3, 29, "Type number to switch to file", 0);
        if (count > 9) {
            strcpy(buf, "Showing files ");
            strcat(buf, formatInt16(filePage * 9 + 1));
            strcat(buf, " - ");
            strcat(buf, formatInt16(count >= (filePage+1)*9 ? filePage * 9 + 9 : count));
            n = strlen(buf);
            drawRow(y++, 3, n, buf, 0);
            drawRow(y++, 3, 37, "Left / right arrows to see more files", 0);
        }
    }

    ++y;
    drawRow(y++, 3, 34, "O: Open  C: Close  S: Save  N: New", 0);

    strcpy(buf, "A: Save As  D: Device (Currently ");
    strcat(buf, formatInt16(8));
    strcat(buf, ")");
    n = strlen(buf);
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
                storeChunk(E.cf.selectionChunk, &E.selection);
                retrieveChunk(chunkNum, (unsigned char *)&E.cf);
                retrieveChunk(E.cf.selectionChunk, &E.selection);
                clearScreen();
                return;
            }
        }

        retrieveChunk(chunkNum, (unsigned char *)&file);
        chunkNum = file.nextFileChunk;
    }
}

