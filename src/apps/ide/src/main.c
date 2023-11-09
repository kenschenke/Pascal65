#include <stdio.h>
#include <ovrlcommon.h>
#include <cbm.h>
#include <device.h>
#include <editor.h>
#include <stdlib.h>
#include <string.h>
#include <libcommon.h>
#include <conio.h>
#include <em.h>
#include <tokenizer.h>
#include <parser.h>
#include <membuf.h>
#include <semantic.h>
#include <codegen.h>
#include <ast.h>
#include <int16.h>
#include <common.h>

extern void _OVERLAY1_LOAD__[], _OVERLAY1_SIZE__[];
extern void _OVERLAY2_LOAD__[], _OVERLAY2_SIZE__[];
extern void _OVERLAY3_LOAD__[], _OVERLAY3_SIZE__[];
extern void _OVERLAY4_LOAD__[], _OVERLAY4_SIZE__[];
extern void _OVERLAY5_LOAD__[], _OVERLAY5_SIZE__[];
extern void _OVERLAY6_LOAD__[], _OVERLAY6_SIZE__[];
extern void _OVERLAY7_LOAD__[], _OVERLAY7_SIZE__[];
unsigned char loadfile(const char *name);

struct editorConfig E;

static char intBuffer[16];

void logError(const char *message, unsigned lineNumber, TErrorCode code)
{
    printz("*** ERROR: ");
    printz(message);
    printz(" line ");
    printlnz(formatInt16(lineNumber));
    exit(0);
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

void editorSetDefaultStatusMessage(void) {
    editorSetStatusMessage("F1: open  Ctrl-X: quit  F7: help");
}

void parserOverlay(void);

#ifndef __MEGA65__
static unsigned
    overlay1size,
    overlay2size,
    overlay3size,
    overlay4size,
    overlay5size,
    overlay6size,
    overlay7size;
static unsigned
    overlay1blocks,
    overlay2blocks,
    overlay3blocks,
    overlay4blocks,
    overlay5blocks,
    overlay6blocks,
    overlay7blocks;

static BLOCKNUM tokenizerCache,
    parserCache,
    semanticCache,
    objCodeCache,
    linkerCache,
    editorCache,
    editorfilesCache;

static void loadOverlayFromCache(unsigned size, void *buffer, unsigned cache) {
    struct em_copy emc;

    emc.buf = buffer;
    emc.offs = 0;
    emc.page = cache;
    emc.count = size;
    flushChunkBlock();
    em_copyfrom(&emc);
}

static void loadOverlayFromFile(char *name, unsigned size, void *buffer, unsigned cache) {
    struct em_copy emc;

    if (!loadfile(name)) {
        printlnz(name);
        printlnz("Unable to load overlay from disk\n");
        exit(0);
    }

    // Copy the parser overlay to the cache
    emc.buf = buffer;
    emc.offs = 0;
    emc.page = cache;
    emc.count = size;
    flushChunkBlock();
    em_copyto(&emc);
}
#endif

static void closeFile(void) {
    if (E.cf.dirty && E.cf.fileChunk) {
        int ch;

        while (1) {
            drawStatusRow(COLOR_LIGHTRED, 0, "Save changes before closing? Y/N");
            ch = cgetc();
            if (ch == 'y' || ch == 'Y') {
                break;
            } else if (ch == STOP_KEY) {
                clearStatusRow();
                editorSetDefaultStatusMessage();
                return;
            } else if (ch == 'n' || ch == 'N' || ch == CH_ESC) {
                editorClose();
                clearStatusRow();
                editorSetDefaultStatusMessage();
                return;
            }
        }

        if (saveFile() == 0) {
            return;
        }
    }

    editorClose();
}

static void compile(void)
{
    CHUNKNUM tokens, ast;
    char filename[16 + 1];

    memset(filename, 0, sizeof(filename));
    retrieveChunk(E.cf.filenameChunk, filename);

    // Tokenizer
    loadOverlayFromCache(overlay1size, _OVERLAY1_LOAD__, tokenizerCache);
    tokens = tokenize(filename);

    // Parser
    loadOverlayFromCache(overlay2size, _OVERLAY2_LOAD__, parserCache);
    ast = parse(tokens);
    freeMemBuf(tokens);

    // Semantic analysis and error checking
    loadOverlayFromCache(overlay3size, _OVERLAY3_LOAD__, semanticCache);
    initSemantic();    
    init_scope_stack();
    decl_resolve(ast, 0);
    set_decl_offsets(ast, 0, 0);
    decl_typecheck(ast);

    // Object code (part 1 - linker pre-write)
    loadOverlayFromCache(overlay5size, _OVERLAY5_LOAD__, linkerCache);
    linkerPreWrite();

    // Generate object code
    loadOverlayFromCache(overlay4size, _OVERLAY4_LOAD__, objCodeCache);
    objCodeWrite(ast);

    // Generate PRG filename
    if (!stricmp(filename+strlen(filename)-4, ".pas")) {
        filename[strlen(filename)-4] = 0;
    } else {
        if (strlen(filename) > 12) {
            strcpy(filename+12, ".prg");
        } else {
            strcat(filename, ".prg");
        }
    }

    // Write the PRG file
    loadOverlayFromCache(overlay5size, _OVERLAY5_LOAD__, linkerCache);
    linkerPostWrite(filename);

    // Free the AST
    decl_free(ast);
    free_scope_stack();

    loadOverlayFromCache(overlay6size, _OVERLAY6_LOAD__, editorCache);
}

static void openFile(void)
{
    char filename[16+1];

    // prompt for filename
    if (promptForOpenFilename(filename, sizeof(filename)) == 0) {
        return;
    }

    if (E.cf.fileChunk) {
        storeChunk(E.cf.fileChunk, (unsigned char *)&E.cf);
    }

    initFile();

    loadOverlayFromCache(overlay7size, _OVERLAY7_LOAD__, editorfilesCache);
    editorOpen(filename, 0);

    loadOverlayFromCache(overlay6size, _OVERLAY6_LOAD__, editorCache);
    editorStoreFilename(filename);
    editorSetDefaultStatusMessage();
    updateStatusBarFilename();

    renderCursor(0, 0);

    if (E.cf.fileChunk) {
        clearScreen();
        editorSetAllRowsDirty();
    }
}

static void openHelpFile(void) {
    char buf[CHUNK_LEN];

    if (E.cf.fileChunk) {
        storeChunk(E.cf.fileChunk, (unsigned char *)&E.cf);
    }

    initFile();

    loadOverlayFromCache(overlay7size, _OVERLAY7_LOAD__, editorfilesCache);
    editorOpen("help.txt", 1);
    loadOverlayFromCache(overlay6size, _OVERLAY6_LOAD__, editorCache);
    strcpy(buf, "Help File");
    allocChunk(&E.cf.filenameChunk);
    storeChunk(E.cf.filenameChunk, (unsigned char *)buf);
    storeChunk(E.cf.fileChunk, (unsigned char *)&E.cf);
    updateStatusBarFilename();

    if (E.cf.fileChunk) {
        clearScreen();
        editorSetAllRowsDirty();
    }
}

static void showFileScreen(void)
{
    char code;

    editorSetStatusMessage("O=Open, S=Save, N=New, C=Close, M=More");
    editorRefreshScreen();

    loadOverlayFromCache(overlay7size, _OVERLAY7_LOAD__, editorfilesCache);
    code = handleFiles();

    loadOverlayFromCache(overlay6size, _OVERLAY6_LOAD__, editorCache);
    if (code == FILESCREEN_BACK) {
        editorSetDefaultStatusMessage();
        clearScreen();
        editorSetAllRowsDirty();
        E.anyDirtyRows = 1;
    }
    else if (code == FILESCREEN_CLOSEFILE) {
        editorSetDefaultStatusMessage();
        closeFile();
        clearScreen();
        editorSetAllRowsDirty();
    }
    else if (code == FILESCREEN_NEWFILE) {
        editorSetDefaultStatusMessage();
        editorNewFile();
        clearScreen();
        editorSetAllRowsDirty();
    } else if (code == FILESCREEN_SAVEFILE || code == FILESCREEN_SAVEASFILE) {
        editorSetDefaultStatusMessage();
        clearScreen();
        editorSetAllRowsDirty();
        updateStatusBarFilename();
    } else if (code == FILESCREEN_OPENFILE) {
        openFile();
    } else if (code == FILESCREEN_SWITCHTOFILE) {
        editorSetDefaultStatusMessage();
        clearScreen();
        editorSetAllRowsDirty();
        updateStatusBarFilename();
    }
}

void main()
{
    char loopCode;
#ifndef __MEGA65__
    overlay1size = (unsigned)_OVERLAY1_SIZE__;
    overlay2size = (unsigned)_OVERLAY2_SIZE__;
    overlay3size = (unsigned)_OVERLAY3_SIZE__;
    overlay4size = (unsigned)_OVERLAY4_SIZE__;
    overlay5size = (unsigned)_OVERLAY5_SIZE__;
    overlay6size = (unsigned)_OVERLAY6_SIZE__;
    overlay7size = (unsigned)_OVERLAY7_SIZE__;
    overlay1blocks = overlay1size/BLOCK_LEN + (overlay1size % BLOCK_LEN ? 1 : 0);
    overlay2blocks = overlay2size/BLOCK_LEN + (overlay2size % BLOCK_LEN ? 1 : 0);
    overlay3blocks = overlay3size/BLOCK_LEN + (overlay3size % BLOCK_LEN ? 1 : 0);
    overlay4blocks = overlay4size/BLOCK_LEN + (overlay4size % BLOCK_LEN ? 1 : 0);
    overlay5blocks = overlay5size/BLOCK_LEN + (overlay5size % BLOCK_LEN ? 1 : 0);
    overlay6blocks = overlay6size/BLOCK_LEN + (overlay6size % BLOCK_LEN ? 1 : 0);
    overlay7blocks = overlay7size/BLOCK_LEN + (overlay7size % BLOCK_LEN ? 1 : 0);
#endif

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

    setIntBuf(intBuffer);

    initBlockStorage();
    initCommon();

#ifndef __MEGA65__
    // Allocate space in extended memory to cache the parser and parsertest overlays.
    // This is done so they don't have to be reloaded for each test.
    if (!allocBlockGroup(&tokenizerCache, overlay1blocks) ||
        !allocBlockGroup(&parserCache, overlay2blocks) ||
        !allocBlockGroup(&semanticCache, overlay3blocks) ||
        !allocBlockGroup(&objCodeCache, overlay4blocks) ||
        !allocBlockGroup(&linkerCache, overlay5blocks) ||
        !allocBlockGroup(&editorCache, overlay6blocks) ||
        !allocBlockGroup(&editorfilesCache, overlay7blocks)) {
        printlnz("Unable to allocate extended memory\n");
        return;
    }

    loadOverlayFromFile("pascal65.1", overlay1size, _OVERLAY1_LOAD__, tokenizerCache);
    loadOverlayFromFile("pascal65.2", overlay2size, _OVERLAY2_LOAD__, parserCache);
    loadOverlayFromFile("pascal65.3", overlay3size, _OVERLAY3_LOAD__, semanticCache);
    loadOverlayFromFile("pascal65.4", overlay4size, _OVERLAY4_LOAD__, objCodeCache);
    loadOverlayFromFile("pascal65.5", overlay5size, _OVERLAY5_LOAD__, linkerCache);
    loadOverlayFromFile("pascal65.6", overlay6size, _OVERLAY6_LOAD__, editorCache);
    loadOverlayFromFile("pascal65.7", overlay7size, _OVERLAY7_LOAD__, editorfilesCache);
#endif

    loadOverlayFromCache(overlay6size, _OVERLAY6_LOAD__, editorCache);
    initEditor();

    while (1) {
        loopCode = editorRun();
        if (loopCode == EDITOR_LOOP_QUIT) {
            break;
        }

        if (loopCode == EDITOR_LOOP_OPENFILE) {
            openFile();
        }

        if (loopCode == EDITOR_LOOP_SAVEFILE || loopCode == EDITOR_LOOP_COMPILE) {
            if (E.cf.dirty) {
                loadOverlayFromCache(overlay7size, _OVERLAY7_LOAD__, editorfilesCache);
                saveFile();
                loadOverlayFromCache(overlay6size, _OVERLAY6_LOAD__, editorCache);
            }
            if (loopCode == EDITOR_LOOP_COMPILE) {
                drawStatusRow(COLOR_WHITE, 0, "Compiling...");
                compile();
            }
            editorSetAllRowsDirty();
            editorSetDefaultStatusMessage();
        }

        if (E.loopCode == EDITOR_LOOP_FILESCREEN) {
            showFileScreen();
        }

        if (E.loopCode == EDITOR_LOOP_OPENHELP) {
            clearCursor();
            drawStatusRow(COLOR_WHITE, 0, "Loading Help File...");
            openHelpFile();
            editorSetDefaultStatusMessage();
        }

        E.loopCode = EDITOR_LOOP_CONTINUE;
    }

#if 0
    if (loadfile("pascal65.6")) {
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
