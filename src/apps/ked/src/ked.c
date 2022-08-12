#include "editor.h"
#include <stdio.h>
#include <errno.h>
#include <string.h>
#include <stdlib.h>
#include <stdarg.h>
#include <blocks.h>
#include <conio.h>
#include <cbm.h>
#include <ctype.h>
#include <doscmd.h>
#include <unistd.h>

/*** defines ***/

#define KED_VERSION "0.0.1"

#if 0
int showKeyCodes(void) {
    char buf[3+1];
    char c = editorReadKey();
    if (c == 'q') {
        return 1;
    }

    sprintf(buf, "%3d", c);
    drawRow(10, 0, 3, buf, 0);  // 31: Help
    return 0;
}
#endif

static CHUNKNUM selectedFile;

static char filePage;
static int openFiles;

static void clearStatusRow(void);
static void closeFile(void);
static void cycleCurrentDevice(void);
static char doesFileExist(char *filename);
static void drawStatusRow(char color, char center, const char *fmt, ...);
static char editorPrompt(char *prompt, char *buf, size_t bufsize);
static char handleExitRequested(void);
static void handleFiles(void);
static void openFile(void);
static void openHelpFile(void);
static char saveAs(void);
static char saveFile(void);
static char saveToExisting(void);
static void showFileScreen(void);
static void switchToFile(char num);

static void clearStatusRow(void) {
    int x;

    for (x = 0; x < E.screencols; ++x) {
        cellcolor(x, E.screenrows + 1, COLOUR_WHITE);
    }
    clearRow(E.screenrows + 1, 0);
}

static void closeFile(void) {
    if (E.cf.dirty && E.cf.fileChunk) {
        int ch;

        while (1) {
            drawStatusRow(COLOUR_RED, 0, "Unsaved changes will be lost. Close Y/N?");
            ch = editorReadKey();
            if (ch == 'y' || ch == 'Y') {
                break;
            } else if (ch == 'n' || ch == 'N' || ch == CH_ESC) {
                clearStatusRow();
                return;
            }
        }

        if (saveFile() == 0) {
            return;
        }
    }

    editorClose();
}

static void cycleCurrentDevice(void) {
    int dev = getCurrentDrive() + 1;
    char buf[4+1];
    if (dev > 9) {
        dev = 8;
    }

    sprintf(buf, "%d", dev);
    chdir(buf);
}

static char doesFileExist(char *filename) {
    FILE *fp;

    fp = fopen(filename, "r");
    if (fp) {
        fclose(fp);
        return 1;
    }

    return 0;
}

static void drawStatusRow(char color, char center, const char *fmt, ...) {
    int x;
    char buf[80 + 1];

    va_list ap;
    va_start(ap, fmt);
    vsnprintf(buf, sizeof(buf), fmt, ap);
    va_end(ap);

    for (x = 0; x < E.screencols; ++x) {
        cellcolor(x, E.screenrows + 1, color);
    }

    x = center ? E.screencols / 2 - strlen(buf) / 2 : 0;
    drawRow(E.screenrows + 1, x, strlen(buf), buf, 0);
    clearRow(E.screenrows + 1, x + strlen(buf));
}

static char editorPrompt(char *prompt, char *buf, size_t bufsize) {
    size_t buflen = 0;
    int c;

    buf[0] = '\0';

    while (1) {
        drawStatusRow(COLOUR_WHITE, 0, prompt, buf);
        c = editorReadKey();
        if (c == DEL_KEY || c == CTRL_KEY('h') || c == CH_DEL) {
            if (buflen != 0) buf[--buflen] = '\0';
        } else if (c == '\x1b') {
            clearStatusRow();
            return 0;
        } else if (c == CH_ENTER) {
            if (buflen != 0) {
                clearStatusRow();
                return 1;
            }
        } else if (buflen + 1 < bufsize && !iscntrl(c) && c < 128) {
            buf[buflen++] = c;
            buf[buflen] = '\0';
        }
    }

    return 0;
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

static void openFile(void) {
    char filename[16+1];

    clearStatusRow();

    if (editorPrompt("Open file: %s", filename, sizeof(filename)) == 0) {
        drawStatusRow(COLOUR_RED, 1, "Open aborted");
        return;
    }

    editorOpen(filename, 0);
}

static void openHelpFile(void) {
    char buf[CHUNK_LEN];

    editorOpen("help.txt", 1);
    strcpy(buf, "Help File");
    allocChunk(&E.cf.filenameChunk);
    storeChunk(E.cf.filenameChunk, (unsigned char *)buf);
    storeChunk(E.cf.fileChunk, (unsigned char *)&E.cf);
}

static char saveAs(void) {
    char filename[16+1], prompt[80];
    int ch;

    clearStatusRow();

    if (editorPrompt("Save as: %s", filename, sizeof(filename)) == 0) {
        drawStatusRow(COLOUR_RED, 1, "Save aborted");
        return 0;
    }

    if (doesFileExist(filename)) {
        sprintf(prompt, "%s already exists. Overwrite Y/N?", filename);
        while (1) {
            drawStatusRow(COLOUR_RED, 0, prompt);
            ch = editorReadKey();
            if (ch == 'y' || ch == 'Y') {
                break;
            } else if (ch == 'n' || ch == 'N' || ch == CH_ESC) {
                clearStatusRow();
                drawStatusRow(COLOUR_RED, 1, "Save aborted");
                return 0;
            }
        }
        
        removeFile(filename);
    }

    if (!E.cf.filenameChunk) {
        allocChunk(&E.cf.filenameChunk);
    }
    storeChunk(E.cf.filenameChunk, (unsigned char *)filename);

    return editorSave(filename);
}

static char saveFile(void) {
    if (E.cf.fileChunk == 0) {
        // no file is open - welcome screen?
        return 0;
    }

    if (E.cf.readOnly) {
        drawStatusRow(COLOUR_RED, 1, "File is read-only");
        return 0;
    }

    if (!E.cf.dirty) {
        // nothing to do
        return 1;
    }

    if (E.cf.filenameChunk) {
        if (saveToExisting()) {
            clearScreen();
            editorSetAllRowsDirty();
            return 1;
        }
    } else {
        if (saveAs()) {
            clearScreen();
            editorSetAllRowsDirty();
            return 1;
        }
    }

    return 0;
}

static char saveToExisting(void) {
    char filename[CHUNK_LEN], tempFilename[16 + 1];

    clearStatusRow();

    sprintf(tempFilename, "tmp%d.txt", E.cf.fileChunk);
    if (editorSave(tempFilename) == 0) {
        drawStatusRow(COLOUR_RED, 1, "Save failed: %s", strerror(errno));
        return 0;
    }

    if (retrieveChunk(E.cf.filenameChunk, (unsigned char *)filename) == 0) {
        drawStatusRow(COLOUR_RED, 1, "Invalid filename");
        return 0;
    }

    removeFile(filename);
    renameFile(tempFilename, filename);

    return 1;
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

    for (y = 0; y < E.screenrows; ++y) {
        n = snprintf(buf, sizeof(buf), "%02d", y + 1);
        drawRow(y, 0, n, buf, 0);
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
        // editorOpen(argv[1]);
    }

#if 0
    printf("avail = %d\n", _heapmemavail());
    return 0;
#endif

#if 0
    while (!showKeyCodes());
    return 0;
#endif

#if 0
    editorOpen("help.txt", 1);
    // return 0;
#endif

    E.welcomePage =
        "Welcome To Ked Version " KED_VERSION "\r"
        "\r"
        "Copyright 2022 by Ken Schenke\r"
        "kenschenke@gmail.com";
    
#if 0
    {  
        // Create 20 files
        char buf[20];
        int i, n;

        for (i = 20; i >= 1; --i) {
            initFile(&E.cf);
            n = snprintf(buf, sizeof(buf), "Filename %d", i);
            editorStoreFilename(&E.cf, buf);
            n = snprintf(buf, sizeof(buf), "Text for file %d", i);
            editorInsertRow(0, buf, n);
            storeChunk(E.cf.fileChunk, (unsigned char *)&E.cf);
        }
    }
#endif

#if 0
    {
        int i;
        erow row;
        // Create a file with long lines
        initFile(&E.cf);
        editorInsertRow(0, "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Pellentesque luctus sodales finibus. Mauris ultrices quam nunc, non consectetur dui convallis eget. In sed neque rhoncus.", 178);
        editorInsertRow(1, "", 0);
        editorRowAt(1, &row);
        for (i = 0; i < 19; ++i) {
            editorRowAppendString(&row, "123456789 ", 10);
        }
        editorInsertRow(2, "", 0);
    }
#endif

    editorRun();

    return 0;
}
