#include <stdio.h>
#include <ovrlcommon.h>
#include <cbm.h>
#include <device.h>
#include <editor.h>
#include <stdlib.h>
#include <string.h>

static CHUNKNUM selectedFile;

static char filePage;
static int openFiles;

static void cycleCurrentDevice(void);
static void handleFiles(void);
char handleKeyPressed(int key);
static void openHelpFile(void);
static void showFileScreen(void);
static void switchToFile(char num);

extern void _OVERLAY1_LOAD__[], _OVERLAY1_SIZE__[];
extern void _OVERLAY2_LOAD__[], _OVERLAY2_SIZE__[];
extern void _OVERLAY3_LOAD__[], _OVERLAY3_SIZE__[];
unsigned char loadfile(const char *name);

static void cycleCurrentDevice(void) {
#if 0
    int dev = getCurrentDrive() + 1;
    char buf[4+1];
    if (dev > 9) {
        dev = 8;
    }

    sprintf(buf, "%d", dev);
    chdir(buf);
#endif
}

void logError(const char *message, unsigned lineNumber, TErrorCode code)
{
    printf("*** ERROR: %s\n", message);
}

void logFatalError(const char *message)
{
    printf("*** Fatal translation error: %s\n", message);
}

void logRuntimeError(const char *message, unsigned lineNumber)
{
    printf("*** Runtime error: %s\n", message);
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

char handleKeyPressed(int key) {
    char ret = 0;

    if (key == CTRL_KEY('h')) {
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

void outputLine(const char *message)
{
    printf("%s\n", message);
}

void parserOverlay(void);

static void showFileScreen(void) {
#if 1
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

#if 0
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
#endif

    y = 12;
    openFiles = count;

#if 0
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
#endif

    ++y;
    drawRow(y++, 3, 34, "O: Open  C: Close  S: Save  N: New", 0);

#if 0
    n = snprintf(buf, sizeof(buf), "A: Save As  D: Device (Currently %d)",
        8); // getCurrentDrive());
    drawRow(y++, 3, n, buf, 0);
#endif

    drawRow(y, 3, 19, "\x1f  Return To Editor", 0);
#endif
}

// num is 1 - 9 on current page
static void switchToFile(char /*num*/) {
#if 0
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
#endif
}

void main()
{
#ifdef __C128__
    fast();
    videomode(VIDEOMODE_80x25);
    printf("Is fast mode: %s\n", isfast() ? "yes" : "no");
#endif
    // bgcolor(COLOR_BLUE);
    // textcolor(COLOR_WHITE);
    printf("Loading editor overlay\n");

#ifdef __MEGA65
    // On the Mega65, $1600 - $1fff is available to use in the heap
    _heapadd((void *)0x1600, 0x1fff - 0x1600);
#endif

    initBlockStorage();

#if 1
    if (loadfile("pascal65.3")) {
        initEditor();
        editorSetStatusMessage("Ctrl-O: open  Ctrl-X: quit  Press HELP");
        E.cbKeyPressed = handleKeyPressed;
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
    printf("%s: %s\n", module, message);
}
