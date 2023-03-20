#include <stdio.h>
#include <string.h>
#include <editor.h>
#include <doscmd.h>
#include <unistd.h>

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

static CHUNKNUM selectedFile;
static char filePage;
static int openFiles;

static void cycleCurrentDevice(void) {
    int dev = getCurrentDrive() + 1;
    char buf[4+1];
    if (dev > 9) {
        dev = 8;
    }

    sprintf(buf, "%d", dev);
    chdir(buf);
}

void handleFiles(void) {
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
                drawStatusRow(COLOR_RED, 1, "Unable to open file");
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
        8); // getCurrentDrive());
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

