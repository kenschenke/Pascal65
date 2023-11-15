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

#include <stdio.h>
#include <editor.h>
#include <cbm.h>
#include <device.h>
#include <conio.h>
#include <string.h>
#include <em.h>
#include <stdlib.h>

struct editorConfig E;

extern void _OVERLAY1_LOAD__[], _OVERLAY1_SIZE__[];
extern void _OVERLAY2_LOAD__[], _OVERLAY2_SIZE__[];
unsigned char loadfile(const char *name);
static void openHelpFile(void);

#ifndef __MEGA65__
static unsigned overlay1size, overlay2size;
static unsigned overlay1blocks, overlay2blocks;

static BLOCKNUM editorCache, editorfilesCache;

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
        printf("Unable to load overlay from disk\n");
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

unsigned char loadfile(const char *name)
{
    if (cbm_load(name, getcurrentdevice(), NULL) == 0) {
        printf("Loading overlay file failed\n");
        return 0;
    }

    return 1;
}

void editorSetDefaultStatusMessage(void) {
    editorSetStatusMessage("F1: open  Ctrl-X: quit  F7: help");
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

#ifdef __MEGA65__
    loadfile("ked.2");
#else
    loadOverlayFromCache(overlay2size, _OVERLAY2_LOAD__, editorfilesCache);
#endif
    ret = editorOpen(filename, 0);

#ifdef __MEGA65__
    loadfile("ked.1");
#else
    loadOverlayFromCache(overlay1size, _OVERLAY1_LOAD__, editorCache);
#endif
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

#ifdef __MEGA65__
    loadfile("ked.2");
#else
    loadOverlayFromCache(overlay2size, _OVERLAY2_LOAD__, editorfilesCache);
#endif
    editorOpen("help.txt", 1);
#ifdef __MEGA65__
    loadfile("ked.1");
#else
    loadOverlayFromCache(overlay1size, _OVERLAY1_LOAD__, editorCache);
#endif
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

#ifdef __MEGA65__
    loadfile("ked.2");
#else
    loadOverlayFromCache(overlay2size, _OVERLAY2_LOAD__, editorfilesCache);
#endif
    code = handleFiles();

#ifdef __MEGA65__
    loadfile("ked.1");
#else
    loadOverlayFromCache(overlay1size, _OVERLAY1_LOAD__, editorCache);
#endif
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

// Editor: 12901
//    editorRowDelChars: 461
//    editorRowInsertChar: 551
//    editorRowAppendString: 396
int main(int argc, char *argv[])
{
    char loopCode;
#ifndef __MEGA65__
    overlay1size = (unsigned)_OVERLAY1_SIZE__;
    overlay2size = (unsigned)_OVERLAY2_SIZE__;
    overlay1blocks = overlay1size/BLOCK_LEN + (overlay1size % BLOCK_LEN ? 1 : 0);
    overlay2blocks = overlay2size/BLOCK_LEN + (overlay2size % BLOCK_LEN ? 1 : 0);
#endif

    initBlockStorage();

#ifndef __MEGA65__
    // Allocate space in extended memory to cache the parser and parsertest overlays.
    // This is done so they don't have to be reloaded for each test.
    if (!allocBlockGroup(&editorCache, overlay1blocks) ||
        !allocBlockGroup(&editorfilesCache, overlay2blocks)) {
        printf("Unable to allocate extended memory\n");
        return 0;
    }

    loadOverlayFromFile("ked.1", overlay1size, _OVERLAY1_LOAD__, editorCache);
    loadOverlayFromFile("ked.2", overlay2size, _OVERLAY2_LOAD__, editorfilesCache);

    loadOverlayFromCache(overlay1size, _OVERLAY1_LOAD__, editorCache);
#else
    loadfile("ked.1");
#endif

    initEditor();

    while (1) {
        loopCode = editorRun();
        if (loopCode == EDITOR_LOOP_QUIT) {
            break;
        }

        if (loopCode == EDITOR_LOOP_OPENFILE) {
            openFile();
        }

        if (loopCode == EDITOR_LOOP_SAVEFILE) {
#ifdef __MEGA65__
            loadfile("ked.2");
#else
            loadOverlayFromCache(overlay2size, _OVERLAY2_LOAD__, editorfilesCache);
#endif
            saveFile();
#ifdef __MEGA65__
            loadfile("ked.1");
#else
            loadOverlayFromCache(overlay1size, _OVERLAY1_LOAD__, editorCache);
#endif
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

    return 0;
}
