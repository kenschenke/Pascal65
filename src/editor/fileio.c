#include "editor.h"

#include <stdio.h>
#include <string.h>
#include <stdlib.h>

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
    char *buf, *line, *eol;
    int buflen = 120, lastRow = -1;

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

    buf = malloc(buflen);

    while (!feof(fp)) {
        if (!fgets(buf, buflen, fp)) {
            fclose(fp);
            free(buf);
            editorSetStatusMessage("Cannot read file");
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

    free(buf);
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

