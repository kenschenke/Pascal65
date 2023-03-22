/**
 * fileio.c
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * File input / output.
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
#include <conio.h>
#include <cbm.h>
#include <doscmd.h>
#include <errno.h>
#include <int16.h>

void closeFile(void) {
    if (E.cf.dirty && E.cf.fileChunk) {
        int ch;

        while (1) {
            drawStatusRow(COLOR_LIGHTRED, 0, "Save changes before closing? Y/N");
            ch = editorReadKey();
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

char doesFileExist(char *filename) {
    FILE *fp;

    fp = fopen(filename, "r");
    if (fp) {
        fclose(fp);
        return 1;
    }

    return 0;
}

void editorClose(void) {
    CHUNKNUM chunkNum;
    erow row;
    efile file;

    if (!E.cf.fileChunk) {
        return;  // no file currently open
    }

    // Free the rows
    chunkNum = E.cf.firstRowChunk;
    while (chunkNum) {
        if (retrieveChunk(chunkNum, (unsigned char *)&row) == 0) {
            break;
        }
        chunkNum = row.nextRowChunk;
        editorFreeRow(row.firstTextChunk);
        freeChunk(row.rowChunk);
    }

    // Remove the file from the list
    if (E.firstFileChunk == E.cf.fileChunk) {
        E.firstFileChunk = E.cf.nextFileChunk;
    } else {
        chunkNum = E.firstFileChunk;
        while (chunkNum) {
            retrieveChunk(chunkNum, (unsigned char *)&file);
            if (file.nextFileChunk == E.cf.fileChunk) {
                file.nextFileChunk = E.cf.nextFileChunk;
                storeChunk(chunkNum, (unsigned char *)&file);
                break;
            }
            chunkNum = file.nextFileChunk;
        }
    }

    freeChunk(E.cf.filenameChunk);
    freeChunk(E.cf.fileChunk);
    E.cf.fileChunk = 0;
    E.cf.firstRowChunk = 0;
    clearScreen();
    
    if (E.firstFileChunk) {
        retrieveChunk(E.firstFileChunk, (unsigned char *)&E.cf);
        editorSetAllRowsDirty();
    }
}

void editorSwitchToOpenFile(CHUNKNUM fileChunkNum) {
    CHUNKNUM chunkNum;

    // First, store the current file chunk
    if (E.cf.fileChunk) {
        storeChunk(E.cf.fileChunk, (unsigned char *)&E.cf);
    }

    // Find the other file in the list
    chunkNum = E.firstFileChunk;
    while (chunkNum) {
        retrieveChunk(chunkNum, (unsigned char *)&E.cf);
        if (chunkNum == fileChunkNum) {
            break;
        }
        chunkNum = E.cf.nextFileChunk;
    }

    if (!chunkNum) {
        E.cf.fileChunk = 0;
    }

    editorSetAllRowsDirty();
}

void editorOpen(const char *filename, char readOnly) {
    FILE *fp;
    erow row;
    char buf[40], *line, *eol;
    int buflen = 40, lastRow = -1;

    if (E.cf.fileChunk) {
        storeChunk(E.cf.fileChunk, (unsigned char *)&E.cf);
    }

    fp = fopen(filename, "r");
    if (!fp) {
        editorSetStatusMessage("Cannot open file");
        return;
    }

    initFile(&E.cf);
    E.cf.readOnly = readOnly;
    editorStoreFilename(&E.cf, filename);

    while (!feof(fp)) {
        if (!fgets(buf, buflen, fp)) {
            break;
        }

        line = buf;
        while (1) {
            eol = strchr(line, '\r');
            if (eol == NULL) {
                if (line != NULL) {
                    if (lastRow >= 0) {
                        editorRowAt(lastRow, &row);
                        editorRowAppendString(&row, line, strlen(line));
                    } else {
                        editorInsertRow(E.cf.numrows, line, strlen(line));
                    }
                    lastRow = E.cf.numrows - 1;
                }
                break;
            } else {
                *eol = '\0';
                if (line != NULL) {
                    if (lastRow >= 0) {
                        editorRowAt(lastRow, &row);
                        editorRowAppendString(&row, line, strlen(line));
                    } else {
                        editorInsertRow(E.cf.numrows, line, strlen(line));
                    }
                    lastRow = -1;
                }
                line = eol + 1;
            }
        }
    }

    fclose(fp);
    E.cf.dirty = 0;
}

char editorSave(char *filename) {
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
        fputc('\r', fp);
        rowChunkNum = row.nextRowChunk;
    }
    if (fclose(fp)) {
        return 0;
    }

    E.cf.dirty = 0;

    return 1;
}

void openFile(void) {
    char filename[16+1];

    clearStatusRow();

    if (editorPrompt("Open file: ", filename, sizeof(filename), 11) == 0) {
        editorSetDefaultStatusMessage();
        return;
    }

    editorOpen(filename, 0);
    editorSetDefaultStatusMessage();

#ifdef __C64__
    renderCursor64(0, 0);
#endif
}

char saveAs(void) {
    char filename[16+1], prompt[80];
    int ch;

    clearStatusRow();

    if (editorPrompt("Save as: ", filename, sizeof(filename), 9) == 0) {
        editorSetDefaultStatusMessage();
        return 0;
    }

    if (doesFileExist(filename)) {
        strcpy(prompt, filename);
        strcat(prompt, " already exists. Overwrite Y/N?");
        while (1) {
            drawStatusRow(COLOR_RED, 0, prompt);
            ch = editorReadKey();
            if (ch == 'y' || ch == 'Y') {
                break;
            } else if (ch == 'n' || ch == 'N' || ch == CH_ESC) {
                clearStatusRow();
                editorSetDefaultStatusMessage();
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

char saveToExisting(void) {
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

    removeFile(filename);
    renameFile(tempFilename, filename);

    return 1;
}

