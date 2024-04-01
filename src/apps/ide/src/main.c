/**
 * main.c
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Entry point for IDE.
 * 
 * Copyright (c) 2024
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

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
#include <membuf.h>
#include <int16.h>
#include <common.h>
#include <unistd.h>
#ifdef __MEGA65__
#include <doscmd.h>
#endif

#define OVERLAY_EDITOR 0
#define OVERLAY_EDITORFILES 1

#define AUTORUN "autorun"
#define AUTOSRC "autosrc"

unsigned char loadfile(const char *name);
static void loadOverlay(int overlayNum);
static void compile(char run);
static void restoreState(void);
static void setupOverlayName(char *name, int num);

struct editorConfig E;

// Device Pascal65 was loaded from
static char prgDrive;

void loadproghelper(const char *prg);

static void compile(char run)
{
    FILE *fp;
    char newline = '\n', filename[CHUNK_LEN];

    memset(filename, 0, sizeof(filename));
    retrieveChunk(E.cf.filenameChunk, filename);

    if (fp = fopen(run ? AUTORUN : AUTOSRC, "w")) {
        fwrite(filename, 1, strlen(filename), fp);
        fwrite(&newline, 1, 1, fp);
        fclose(fp);
    }

    loadOverlay(OVERLAY_EDITOR);
    editorSaveState();

    loadfile("loadprog");
    loadproghelper("compiler");
}

void logError(const char *message, unsigned lineNumber, TErrorCode /*code*/)
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

void logRuntimeError(const char *message, unsigned /*lineNumber*/)
{
    printz("*** Runtime error: ");
    printlnz(message);
}

void editorSetDefaultStatusMessage(void) {
#ifdef __MEGA65__
    editorSetStatusMessage("F1: open  F2: save  F5: compile  \x1f: files  Ctrl-X: quit");
#else
    editorSetStatusMessage("F1: open  Ctrl-X: quit  F7: help");
#endif
}

#ifndef __MEGA65__
extern void _OVERLAY1_LOAD__[], _OVERLAY1_SIZE__[];
extern void _OVERLAY2_LOAD__[], _OVERLAY2_SIZE__[];
static unsigned overlaySizes[2];
static unsigned overlayBlocks[2];
static BLOCKNUM overlayCaches[2];

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
        printz(name);
        printlnz(" missing");
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

// overlayNum is zero-based
static void loadOverlay(int overlayNum)
{
#ifdef __MEGA65__
    char name[16];

    setupOverlayName(name, overlayNum);
    loadfile(name);
#else
    loadOverlayFromCache(overlaySizes[overlayNum],
        _OVERLAY1_LOAD__, overlayCaches[overlayNum]);
#endif
}

static void openFile(void)
{
    char ret;
    char filename[16+1];

    // prompt for filename
    if (promptForOpenFilename(filename, sizeof(filename)) == 0) {
        return;
    }

    if (E.cf.fileChunk) {
        storeChunk(E.cf.fileChunk, (unsigned char *)&E.cf);
    }

    initFile();

    loadOverlay(OVERLAY_EDITORFILES);
    ret = editorOpen(filename, 0);
    loadOverlay(OVERLAY_EDITOR);
    if (!ret) {
        // The open failed.  Uninitialize the new file and pretend it never happened.
        unInitFile();
        return;
    }

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

    loadOverlay(OVERLAY_EDITORFILES);
    editorOpen("help.txt", 1);
    loadOverlay(OVERLAY_EDITOR);
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

static void restoreState(void)
{
    if (!editorHasState()) {
        return;
    }

    editorLoadState();

    loadOverlay(OVERLAY_EDITORFILES);
    loadFilesFromState();
    loadOverlay(OVERLAY_EDITOR);

    if (E.cf.fileChunk) {
        clearScreen();
        editorSetAllRowsDirty();
        E.cf.dirty = 0;
        E.anyDirtyRows = 1;
        editorSetDefaultStatusMessage();
        updateStatusBarFilename();
    }

    // Remove the PRG that was run
#ifdef __MEGA65__
    removeFile("zzprg");
#else
    remove("zzprg");
#endif
}

static void showFileScreen(void)
{
    char code;

    editorSetStatusMessage("O=Open, S=Save, N=New, C=Close, M=More");
    editorRefreshScreen();

    loadOverlay(OVERLAY_EDITORFILES);
    code = handleFiles();

    loadOverlay(OVERLAY_EDITOR);
    editorSetDefaultStatusMessage();
    if (code == FILESCREEN_BACK) {
        clearScreen();
        editorSetAllRowsDirty();
        E.anyDirtyRows = 1;
    }
    else if (code == FILESCREEN_CLOSEFILE) {
        closeFile();
        clearScreen();
        editorSetAllRowsDirty();
    }
    else if (code == FILESCREEN_NEWFILE) {
        editorNewFile();
        clearScreen();
        editorSetAllRowsDirty();
    } else if (code == FILESCREEN_SAVEFILE || code == FILESCREEN_SAVEASFILE) {
        clearScreen();
        editorSetAllRowsDirty();
        updateStatusBarFilename();
    } else if (code == FILESCREEN_OPENFILE) {
        openFile();
    } else if (code == FILESCREEN_SWITCHTOFILE) {
        clearScreen();
        editorSetAllRowsDirty();
        updateStatusBarFilename();
    }
}

static void setupOverlayName(char *name, int num)
{
    strcpy(name, "pascal65.");
    strcat(name, formatInt16(num + 1));
}

#ifndef __MEGA65__
static void setupOverlays(void)
{
    int i;
    char name[16];

    overlaySizes[0] = (unsigned)_OVERLAY1_SIZE__;
    overlaySizes[1] = (unsigned)_OVERLAY1_SIZE__;
    for (i = 0; i < 2; ++i) {
        overlayBlocks[i] = overlaySizes[i]/BLOCK_LEN + (overlaySizes[i] % BLOCK_LEN ? 1 : 0);
    }

    // Allocate space in extended memory to cache the parser and parsertest overlays.
    // This is done so they don't have to be reloaded for each test.
    for (i = 0; i < 7; ++i) {
        if (!allocBlockGroup(&overlayCaches[i], overlayBlocks[i])) {
            printlnz("Unable to allocate extended memory\n");
            return;
        }
    }

    for (i = 0; i < 2; ++i) {
        setupOverlayName(name, i);
        loadOverlayFromFile(name, overlaySizes[i], _OVERLAY1_LOAD__, overlayCaches[i]);
    }
}
#endif

void reset(void);

void main()
{
    char loopCode;

    prgDrive = getcurrentdevice();

#if 0
    printz("avail = ");
    printlnz(formatInt16(_heapmemavail()));
    return;
#endif

    initBlockStorage();
    initCommon();

#ifndef __MEGA65__
    setupOverlays();
#endif

    loadOverlay(OVERLAY_EDITOR);
    initEditor();
    restoreState();

    while (1) {
        loopCode = editorRun();
        if (loopCode == EDITOR_LOOP_QUIT) {
            reset();
        }

        if (loopCode == EDITOR_LOOP_OPENFILE) {
            openFile();
        }

        if (loopCode == EDITOR_LOOP_SAVEFILE || loopCode == EDITOR_LOOP_COMPILE || loopCode == EDITOR_LOOP_RUN) {
            if (E.cf.dirty) {
                loadOverlay(OVERLAY_EDITORFILES);
                saveFile();
                loadOverlay(OVERLAY_EDITOR);
            }
            if (loopCode == EDITOR_LOOP_COMPILE) {
                drawStatusRow(COLOR_WHITE, 0, "Compiling...");
                compile(0);
            }
            if (loopCode == EDITOR_LOOP_RUN) {
                drawStatusRow(COLOR_WHITE, 0, "Running...");
                editorSaveState();
                compile(1);
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
}

unsigned char loadfile(const char *name)
{
    if (cbm_load(name, prgDrive, NULL) == 0) {
        printz(name);
        printlnz(" missing");
        exit(0);
    }

    return 1;
}
