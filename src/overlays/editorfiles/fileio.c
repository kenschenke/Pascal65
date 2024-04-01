/**
 * fileio.c
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * File input / output.
 * 
 * Copyright (c) 2024
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

#include "editor.h"

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <conio.h>
#include <cbm.h>
#include <doscmd.h>
#include <errno.h>
#include <int16.h>

static void addRow(efile *file, erow *row, CHUNKNUM lastRow);
static void appendText(erow *row, CHUNKNUM *lastChunk, char *text);
static char editorSave(char *filename);
static char saveToExisting(void);

char doesFileExist(char *filename) {
    FILE *fp;

    fp = fopen(filename, "r");
    if (fp) {
        fclose(fp);
        return 1;
    }

    return 0;
}

static void addRow(efile *file, erow *row, CHUNKNUM lastRow)
{
    CHUNKNUM chunkNum;
    allocChunk(&chunkNum);

    if (row->rowChunk) {
        storeChunk(row->rowChunk, row);
    }

    if (lastRow) {
        retrieveChunk(lastRow, row);
        row->nextRowChunk = chunkNum;
        storeChunk(lastRow, row);
    }

    if (file->firstRowChunk == 0) {
        file->firstRowChunk = chunkNum;
    }

    memset(row, 0, sizeof(erow));
    row->rowChunk = chunkNum;
}

static void appendText(erow *row, CHUNKNUM *lastChunk, char *text)
{
    char *p = text;
    echunk chunk;
    CHUNKNUM chunkNum;
    int toCopy, len = strlen(text);

    while (len) {
        allocChunk(&chunkNum);
        if (*lastChunk) {
            retrieveChunk(*lastChunk, &chunk);
            chunk.nextChunk = chunkNum;
            storeChunk(*lastChunk, &chunk);
        } else {
            row->firstTextChunk = chunkNum;
        }

        toCopy = len > ECHUNK_LEN ? ECHUNK_LEN : len;
        memcpy(chunk.bytes, p, toCopy);
        chunk.bytesUsed = toCopy;
        chunk.nextChunk = 0;
        storeChunk(chunkNum, &chunk);
        row->size += toCopy;
        len -= toCopy;
        *lastChunk = chunkNum;
        p += toCopy;
    }
}

char editorOpen(const char *filename, char readOnly) {
    FILE *fp;

    if (E.cf.fileChunk) {
        storeChunk(E.cf.fileChunk, (unsigned char *)&E.cf);
    }

    fp = fopen(filename, "r");
    if (!fp) {
        editorSetStatusMessage("Cannot open file");
        return 0;
    }

    E.cf.readOnly = readOnly;

    editorReadFileContents(&E.cf, fp);

    fclose(fp);
    E.cf.dirty = 0;
    E.anyDirtyRows = 1;
    editorSetDefaultStatusMessage();
    updateStatusBarFilename();

    return 1;
}

void editorReadFileContents(efile *file, FILE *fp)
{
    erow row;
    CHUNKNUM lastTextChunk=0, lastRowChunk=0;
    char buf[40], *line, *eol;
    int buflen = 40;

    row.rowChunk = 0;

    while (!feof(fp)) {
        if (!fgets(buf, buflen, fp)) {
            break;
        }

        line = buf;     // start at beginning of buffer
        while (1) {
            eol = strchr(line, '\n');   // Look for a CR (end of line)
            if (eol == NULL) {
                // CR not found, so we have a partial line.
                // Save what we have so far in the buffer.
                if (row.rowChunk) {
                    appendText(&row, &lastTextChunk, line);
                } else {
                    addRow(file, &row, lastRowChunk);
                    appendText(&row, &lastTextChunk, line);
                    row.idx = file->numrows++;
                }
                break;
            } else {
                *eol = '\0';
                if (row.rowChunk) {
                    appendText(&row, &lastTextChunk, line);
                } else {
                    addRow(file, &row, lastRowChunk);
                    appendText(&row, &lastTextChunk, line);
                    row.idx = file->numrows++;
                }
                storeChunk(row.rowChunk, &row);
                lastRowChunk = row.rowChunk;
                row.rowChunk = 0;
                lastTextChunk = 0;
                line = eol + 1;
            }
        }
    }

    if (row.rowChunk) {
        storeChunk(row.rowChunk, &row);
    }
}

static char editorSave(char *filename) {
    FILE *fp;
    char newFile = 0;
    CHUNKNUM rowChunkNum, textChunkNum;
    erow row;
    echunk chunk;

    fp = fopen(filename, "w");
    if (fp == NULL) {
        return 0;

    }
    rowChunkNum = E.cf.firstRowChunk;
    while (rowChunkNum) {
        retrieveChunk(rowChunkNum, (unsigned char *)&row);
        textChunkNum = row.firstTextChunk;
        while (textChunkNum) {
            retrieveChunk(textChunkNum, (unsigned char *)&chunk);
            if (chunk.bytesUsed) {
                if (fwrite(chunk.bytes, 1, chunk.bytesUsed, fp) != chunk.bytesUsed) {
                    return 0;
                }
            }
            textChunkNum = chunk.nextChunk;
        }
        fputc('\n', fp);
        rowChunkNum = row.nextRowChunk;
    }
    if (fclose(fp)) {
        return 0;
    }

    E.cf.dirty = 0;
    updateStatusBarFilename();

    return 1;
}

void loadFilesFromState(void)
{
    FILE *fp;
    char filename[CHUNK_LEN + 1];
    efile file;
    CHUNKNUM fileChunk;

    fileChunk = E.firstFileChunk;
    while (fileChunk) {
        retrieveChunk(fileChunk, &file);
        memset(filename, 0, sizeof(filename));
        retrieveChunk(file.filenameChunk, filename);
        if (!strcmp(filename, "Help File")) {
            file.readOnly = 1;
            strcpy(filename, "help.txt");
        }
        fp = fopen(filename, "r");
        editorReadFileContents(&file, fp);
        fclose(fp);
        storeChunk(file.fileChunk, &file);
        if (file.fileChunk == E.cf.fileChunk) {
            memcpy(&E.cf, &file, sizeof(efile));
        }
        fileChunk = file.nextFileChunk;
    }
}

char saveAs(void) {
    char filename[16+1], prompt[80];
    int ch;

    clearStatusRow();

    if (editorPrompt(filename, sizeof(filename), "Save as: ") == 0) {
        editorSetDefaultStatusMessage();
        return 0;
    }

#ifdef __MEGA65__
    flushkeybuf();
#endif

    if (doesFileExist(filename)) {
        strcpy(prompt, filename);
        strcat(prompt, " already exists. Overwrite Y/N?");
        while (1) {
            drawStatusRow(COLOR_RED, 0, prompt);
            ch = cgetc();
            if (ch == 'y' || ch == 'Y') {
                break;
            } else if (ch == 'n' || ch == 'N' || ch == CH_ESC) {
                clearStatusRow();
                editorSetDefaultStatusMessage();
                return 0;
            }
        }
        
#ifdef __MEGA65__
        removeFile(filename);
#else
        remove(filename);
#endif
    }

    if (!E.cf.filenameChunk) {
        allocChunk(&E.cf.filenameChunk);
    }
    storeChunk(E.cf.filenameChunk, (unsigned char *)filename);

    return editorSave(filename);
}

char saveFile(void) {
    if (E.cf.fileChunk == 0) {
        // no file is open - welcome screen?
        return 0;
    }

    if (E.cf.readOnly) {
        drawStatusRow(COLOR_LIGHTRED, 1, "File is read-only");
        return 0;
    }

    if (!E.cf.dirty) {
        // nothing to do
        return 1;
    }

    if (E.cf.filenameChunk) {
        if (saveToExisting()) {
            return 1;
        }
    } else {
        if (saveAs()) {
            return 1;
        }
    }

    return 0;
}

static char saveToExisting(void) {
    char filename[CHUNK_LEN], tempFilename[16 + 1];

    clearStatusRow();

    strcpy(tempFilename, "tmp");
    strcat(tempFilename, formatInt16(E.cf.fileChunk));
    strcat(tempFilename, ".txt");
    if (editorSave(tempFilename) == 0) {
        char message[40];
        strcpy(message, "Save failed: ");
        strcat(message, strerror(errno));
        drawStatusRow(COLOR_LIGHTRED, 1, message);
        return 0;
    }

    if (retrieveChunk(E.cf.filenameChunk, (unsigned char *)filename) == 0) {
        drawStatusRow(COLOR_LIGHTRED, 1, "Invalid filename");
        return 0;
    }

#ifdef __MEGA65__
    removeFile(filename);
    renameFile(tempFilename, filename);
#else
    remove(filename);
    rename(tempFilename, filename);
#endif

    return 1;
}

