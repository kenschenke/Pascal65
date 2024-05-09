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

char handleFiles(char *filename) {
    int key;
    char code;

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
        } else if (key == 'o' || key == 'O' || key == '$') {
            code = showDirScreen(filename);
            if (code == FILESCREEN_BACK || code == FILESCREEN_OPENFILE) {
                return code;
            }
            showFileScreen();
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
    unsigned char lineBuf[70];
    efile file;
    CHUNKNUM chunkNum;

    clearCursor();
    clearScreen();

    if (E.cf.fileChunk) {
        storeChunk(E.cf.fileChunk, (unsigned char *)&E.cf);
    }

    lineBuf[0] = 112;
    memset(lineBuf+1, 64, 68);
    lineBuf[69] = 110;
    drawScreenRaw(1, 4, 70, lineBuf);

    memset(lineBuf, ' ', sizeof(lineBuf));
    lineBuf[0] = 221;
    memcpy(lineBuf+19, "Open Files (* = Current File)", 29);
    lineBuf[69] = 221;
    drawRow(2, 4, 70, (const char *)lineBuf, 0);

    lineBuf[0] = 107;
    memset(lineBuf+1, 64, 68);
    lineBuf[69] = 115;
    drawScreenRaw(3, 4, 70, lineBuf);

    memset(lineBuf, ' ', sizeof(lineBuf));
    lineBuf[0] = 221;
    lineBuf[69] = 221;
    drawRow(4, 4, 70, (const char *)lineBuf, 0);

    // Render a list of open files
    chunkNum = E.firstFileChunk;
    y = 5;
    i = 0;
    page = 0;
    count = 0;
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
            memset(lineBuf+1, ' ', sizeof(lineBuf)-2);
            n = 3;
            if (chunkNum == selectedFile) {
                lineBuf[n] = '*';
            }
            if (i < 10) {
                ++n;
            }
            ++n;
            strcpy(buf, formatInt16(i));
            memcpy(lineBuf+n, buf, strlen(buf));
            n += strlen(buf);
            lineBuf[n] = ':';
            n += 2;
            memcpy(lineBuf+n, chunk, strlen(chunk));
            n += strlen(chunk);
            if (file.dirty) {
                memcpy(lineBuf+n, " (modified)", 11);
            }
            drawRow(y++, 4, 70, (const char *)lineBuf, 0);
        }

        chunkNum = file.nextFileChunk;
    }

    memset(lineBuf+1, ' ', sizeof(lineBuf)-2);
    while (y < 14) {
        drawRow(y++, 4, 70, (const char *)lineBuf, 0);
    }

    lineBuf[0] = 107;
    memset(lineBuf+1, 64, 68);
    lineBuf[69] = 115;
    drawScreenRaw(y++, 4, 70, lineBuf);

    lineBuf[0] = 221;
    lineBuf[69] = 221;
    memset(lineBuf+1, ' ', sizeof(lineBuf)-2);
    if (E.firstFileChunk == 0) {
        memcpy(lineBuf+9, "No files open", 13);
    } else {
        strcpy(buf, formatInt16(count));
        strcat(buf, " file");
        if (count != 1) {
            strcat(buf, "s");
        }
        strcat(buf, " open");
        memcpy(lineBuf+(68-strlen(buf))/2, buf, strlen(buf));
    }
    drawRow(y++, 4, 70, (const char *)lineBuf, 0);

    lineBuf[0] = 109;
    memset(lineBuf+1, 64, 68);
    lineBuf[69] = 125;
    drawScreenRaw(y++, 4, 70, lineBuf);

    openFiles = count;

    if (count) {
        ++y;
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

    strcpy(buf, "$: Dir  A: Save As  D: Device (Currently ");
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

