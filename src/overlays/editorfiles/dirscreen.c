/**
 * dirscreen.c
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Directory screen for editor
 * 
 * Copyright (c) 2024
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

#include <stdio.h>
#include <string.h>
#include <editor.h>
#include <int16.h>
#include <chunks.h>
#include <doscmd.h>

#ifdef __MEGA65__
#include <cbm.h>
#include <conio.h>

char fixAlphaCase(char);
#endif

#define MAX_DIR_FILES 296
#define MAX_DIR_INDEX 27
#define DIR_ROWS 17
#define FILES_PER_INDEX 11

struct DIRINDEX
{
    CHUNKNUM chunks[FILES_PER_INDEX];
    char unused;
};

struct DIRENT
{
    char filename[16];  // space-filled, not zero-terminated
    short blocks;
    char type[3];
    char unused[CHUNK_LEN-21];
};

static char showAll;
static int numFiles;
static int selectedFile;
static int fileInTopRow;
static char inRightCol;
static struct DIRINDEX lastIndex;
static CHUNKNUM lastIndexLoaded;
static CHUNKNUM dirIndexes[MAX_DIR_INDEX];  // 27 index records

static void clearEntry(char y, char c);
static void clearPromptArea(void);
static void deleteDirEnt(int fileNum);
static void deleteEntry(void);
static void drawEntry(int offset, char y, char c, char selected);
static void drawPromptArea(void);
static void drawStatusLine(char *str, char isCentered);
static void freeDirEntries(void);
static void getDirEnt(int fileNum, struct DIRENT *pEnt);
static void getFilenameForEntry(char *filename);
static void loadDirectory(void);
static void renameEntry(void);
static void saveDirEnt(int fileNum, struct DIRENT *pEnt);
static void showDirectory(void);
static void trimFilename(char *filename);
static void updateStatusRow(void);

static void clearEntry(char y, char c)
{
    char entryBuf[33];

    memset(entryBuf, ' ', sizeof(entryBuf));
    drawRow(y, c, sizeof(entryBuf), entryBuf, 0);
}

static void clearPromptArea(void)
{
    char y, buffer[60];

    memset(buffer, ' ', sizeof(buffer));
    for (y = 22; y <= 24; ++y) {
        drawRow(y, 0, sizeof(buffer), buffer, 0);
    }
}

// offset: in dirFiles[]
// y: row on screen
// c: column on screen
// selected: 1 if draw in reverse
static void drawEntry(int offset, char y, char c, char selected)
{
    struct DIRENT ent;
    char buffer[16], entryBuf[33];

    getDirEnt(offset, &ent);

    strcpy(buffer, formatInt16(ent.blocks));
    memset(entryBuf, ' ', sizeof(entryBuf));
    memcpy(entryBuf+2, buffer, strlen(buffer));
    memcpy(entryBuf+8, ent.filename, sizeof(ent.filename));
    memcpy(entryBuf+26, ent.type, 3);
    drawRow(y, c, 33, entryBuf, selected?1:0);
}

static void deleteDirEnt(int fileNum)
{
    struct DIRINDEX index, nextIndex;
    int indexNum = fileNum / FILES_PER_INDEX;
    int f = fileNum % FILES_PER_INDEX;

    retrieveChunk(dirIndexes[indexNum], &index);
    freeChunk(index.chunks[f]);
    while (fileNum < numFiles) {
        while (f < FILES_PER_INDEX-1) {
            index.chunks[f] = index.chunks[f+1];
            ++f;
            ++fileNum;
        }
        if (dirIndexes[indexNum+1]) {
            retrieveChunk(dirIndexes[indexNum+1], &nextIndex);
            index.chunks[f] = nextIndex.chunks[0];
            storeChunk(dirIndexes[indexNum++], &index);
            memcpy(&index, &nextIndex, sizeof(struct DIRINDEX));
            f = 0;
        } else {
            index.chunks[f] = 0;
            storeChunk(dirIndexes[indexNum], &index);
        }
        ++fileNum;
    }

    storeChunk(dirIndexes[indexNum], &index);
    --numFiles;
    lastIndexLoaded = 0xffff;
}

static void deleteEntry(void)
{
    struct DIRENT ent;
    char ch, prompt[55], filename[16+1];

    if (!numFiles) {
        return;
    }

    clearPromptArea();

    getDirEnt(selectedFile, &ent);

    memcpy(filename, ent.filename, sizeof(ent.filename));
    filename[16] = 0;
    trimFilename(filename);

    strcpy(prompt, "    Delete ");
    strcat(prompt, filename);
    strcat(prompt, ". Are you sure Y/N?");

    while (1) {
        drawStatusRow(COLOR_RED, 0, prompt);
        ch = cgetc();
        if (ch == 'y' || ch == 'Y') {
            break;
        } else if (ch == 'n' || ch == 'N' || ch == CH_ESC) {
            drawPromptArea();
            return;
        }
    }

#ifdef __MEGA65__
    removeFile(filename);
#else
    remove(filename);
#endif

    deleteDirEnt(selectedFile);

    if (selectedFile+1 > numFiles) {
        selectedFile = numFiles - 1;
    }

    drawPromptArea();
    showDirectory();
    updateStatusRow();
}

static void drawPromptArea(void)
{
    char y = 22;

    clearPromptArea();

    drawRow(y++, 4, 44, "RETURN: Open  R: Rename  S: Scratch (delete)", 0);
    drawRow(y++, 4, 40, "Q: Hide non-SEQ files  *: Show all files", 0);
    drawRow(y++, 4, 19, "\x1f: Return to editor", 0);
}

static void drawStatusLine(char *str, char isCentered) {
    char x = 5;
    char buffer[67];

    // Clear the status line first
    memset(buffer, ' ', sizeof(buffer));
    drawRow(DIR_ROWS+2, x, sizeof(buffer), buffer, 0);

    if (isCentered) {
        x = 38 - strlen(str)/2;
    }
    drawRow(DIR_ROWS+2, x, strlen(str), str, 0);
}

static void freeDirEntries(void)
{
    int dirIndex, f;
    struct DIRINDEX index;

    for (dirIndex = 0; dirIndex < MAX_DIR_INDEX; ++dirIndex) {
        if (!dirIndexes[dirIndex]) {
            continue;
        }

        retrieveChunk(dirIndexes[dirIndex], &index);
        for (f = 0; f < FILES_PER_INDEX; ++f) {
            if (index.chunks[f]) {
                freeChunk(index.chunks[f]);
            }
        }
        freeChunk(dirIndexes[dirIndex]);
    }
}

static void getDirEnt(int fileNum, struct DIRENT *pEnt)
{
    int indexNum = fileNum / FILES_PER_INDEX;

    if (indexNum != lastIndexLoaded) {
        retrieveChunk(dirIndexes[indexNum], &lastIndex);
        lastIndexLoaded = indexNum;
    }

    retrieveChunk(lastIndex.chunks[fileNum % FILES_PER_INDEX], pEnt);
}

static void getFilenameForEntry(char *filename)
{
    struct DIRENT ent;

    getDirEnt(selectedFile, &ent);

    memcpy(filename, ent.filename, sizeof(ent.filename));
    filename[16] = 0;
    trimFilename(filename);
}

static void loadDirectory(void) {
    int i, j, indexNum, fileNum;
    FILE *fh;
    char first = 1;
    struct DIRENT ent;
    struct DIRINDEX index;
    unsigned char buffer[40];

    memset(dirIndexes, 0, sizeof(dirIndexes));

    fh = fopen("$", "rb");
    fread(buffer, 1, 2, fh);    // skip 2 bytes

    numFiles = 0;
    while (1) {
        fread(buffer, 1, 2, fh);
        if (!buffer[0] && !buffer[1]) {
            break;
        }

        fread(&ent.blocks, 2, 1, fh);  // num. of blocks for this entry

        i = 0;
        while(1) {
            fread(buffer+i, 1, 1, fh);
            if (buffer[i] == 0) {
                break;
            }
            ++i;
        }

        if (first) {
            first = 0;
            continue;
        }

        // Find the opening quote of the filename
        i = 0;
        while (buffer[i] && buffer[i] != '\"') ++i;
        if (!buffer[i]) {
            continue;
        }

        // Copy into the filename until the closing quote
        j = 0;
        ++i;
        memset(ent.filename, ' ', sizeof(ent.filename));
        while (buffer[i] != '\"') {
            ent.filename[j++] = buffer[i++];
        }

        // Look for the file type
        ++i;
        while (buffer[i] && buffer[i] == ' ') ++i;

        // Copy the file type (if found)
        if (buffer[i]) {
            memcpy(ent.type, buffer+i, 3);
        }

        // Showing all files?
        if (!showAll && memcmp(ent.type, "seq", 3)) {
            continue;
        }

        indexNum = numFiles / FILES_PER_INDEX;
        fileNum = numFiles % FILES_PER_INDEX;
        if (!fileNum) {
            allocChunk(dirIndexes+indexNum);
            memset(&index, 0, sizeof(struct DIRINDEX));
        }

        // Save this entry
        allocChunk(index.chunks+fileNum);
        storeChunk(index.chunks[fileNum], &ent);
        if (fileNum == FILES_PER_INDEX-1) {
            storeChunk(dirIndexes[indexNum], &index);
        }

        ++numFiles;
    }

    fclose(fh);

    if (dirIndexes[indexNum]) {
        storeChunk(dirIndexes[indexNum], &index);
    }

    selectedFile = 0;
    fileInTopRow = 0;
    inRightCol = 0;
    lastIndexLoaded = 0xffff;

    updateStatusRow();
}

static void renameEntry(void) {
    char oldFilename[16+1], newFilename[16+1];
    struct DIRENT ent;

    if (!numFiles) {
        return;
    }

    clearPromptArea();
    if (!editorPrompt(newFilename, sizeof(newFilename), "    New filename: ")) {
        return;
    }

    getDirEnt(selectedFile, &ent);

    memcpy(oldFilename, ent.filename, sizeof(ent.filename));
    oldFilename[16] = 0;
    trimFilename(oldFilename);

#ifdef __MEGA65__
    renameFile(oldFilename, newFilename);
#else
    rename(oldFilename, newFilename);
#endif

    memset(ent.filename, ' ', sizeof(ent.filename));
    memcpy(ent.filename, newFilename, strlen(newFilename));
    saveDirEnt(selectedFile, &ent);

    drawPromptArea();
    showDirectory();
}

static void saveDirEnt(int fileNum, struct DIRENT *pEnt)
{
    struct DIRINDEX index;
    int indexNum = fileNum / FILES_PER_INDEX;

    retrieveChunk(dirIndexes[indexNum], &index);
    storeChunk(index.chunks[fileNum % FILES_PER_INDEX], pEnt);
}

char showDirScreen(char *filename) {
    char y, code=0;
    int key;
    unsigned char lineBuf[69];

    clearCursor();
    clearScreen();

    lineBuf[0] = 112;
    memset(lineBuf+1, 64, 67);
    lineBuf[34] = 114;
    lineBuf[68] = 110;
    drawScreenRaw(0, 4, 69, lineBuf);

    lineBuf[0] = 221;
    lineBuf[68] = 221;
    memset(lineBuf+1, ' ', sizeof(lineBuf)-2);
    lineBuf[34] = 221;
    for (y = 1; y < DIR_ROWS+1; ++y) {
        drawRow(y, 4, 69, (const char *)lineBuf, 0);
    }

    lineBuf[0] = 107;
    memset(lineBuf+1, 64, 67);
    lineBuf[34] = 113;
    lineBuf[68] = 115;
    drawScreenRaw(y++, 4, 69, lineBuf);

    lineBuf[0] = 221;
    lineBuf[68] = 221;
    memset(lineBuf+1, ' ', sizeof(lineBuf)-2);
    drawRow(y++, 4, 69, (const char *)lineBuf, 0);

    lineBuf[0] = 109;
    memset(lineBuf+1, 64, 67);
    lineBuf[68] = 125;
    drawScreenRaw(y, 4, 69, lineBuf);

    drawPromptArea();

    showAll = 0;
    loadDirectory();
    showDirectory();

    while(!code) {
        key = cgetc();
#ifdef __MEGA65__
        key = fixAlphaCase(key);
#endif

        switch (key) {
            case CH_CURS_UP:
                if (!numFiles) {
                    break;
                }
                // If in the right column and already at the top,
                // move the selection to bottom of the left column.
                if (inRightCol && fileInTopRow == 0 && selectedFile == DIR_ROWS) {
                    inRightCol = 0;
                    selectedFile = DIR_ROWS - 1;
                    showDirectory();
                    break;
                }
                if (selectedFile == 0 || (inRightCol && selectedFile == DIR_ROWS)) {
                    // Already at the top
                    break;
                }
                // Is the selection is in the top row?
                if (selectedFile == fileInTopRow ||
                    (inRightCol && selectedFile == fileInTopRow + DIR_ROWS)) {
                        --fileInTopRow;
                        --selectedFile;
                        showDirectory();
                        break;
                }
                --selectedFile;
                showDirectory();
                break;
            
            case CH_CURS_DOWN:
                if (!numFiles || selectedFile+1 >= numFiles) {
                    break;
                }
                if (inRightCol) {
                    // If the selection is at the bottom and there are more rows,
                    // scroll the list up.
                    if (selectedFile == fileInTopRow + DIR_ROWS*2 - 1 &&
                        fileInTopRow + DIR_ROWS*2 - 1 < numFiles) {
                            fileInTopRow++;
                    }
                } else {
                    if (fileInTopRow+DIR_ROWS-1 == selectedFile) {
                        // Selected file in last row of display.
                        // If there is a file in the right column, scroll the display
                        if (selectedFile+DIR_ROWS+1 < numFiles) {
                            ++fileInTopRow;
                        } else if (fileInTopRow+DIR_ROWS < numFiles) {
                            // Otherwise, move to the top of the right column
                            selectedFile = fileInTopRow + DIR_ROWS;
                            inRightCol = 1;
                            showDirectory();
                            break;
                        } else {
                            break;
                        }
                    }
                }
                ++selectedFile;
                showDirectory();
                break;
            
            case CH_CURS_LEFT:
                if (!numFiles || !inRightCol) {
                    break;
                }
                selectedFile -= DIR_ROWS;
                inRightCol = 0;
                showDirectory();
                break;
            
            case CH_CURS_RIGHT:
                if (!numFiles ||
                    inRightCol ||
                    selectedFile + DIR_ROWS >= numFiles) {
                    break;
                }
                selectedFile += DIR_ROWS;
                inRightCol = 1;
                showDirectory();
                break;
            
            case 'r':
            case 'R':
                renameEntry();
                break;
            
            case 's':
            case 'S':
                deleteEntry();
                break;

            case '*':
            case 'q':
            case 'Q':
                showAll = key == '*' ? 1 : 0;
                freeDirEntries();
                loadDirectory();
                showDirectory();
                break;

            case BACKARROW:
                freeDirEntries();
                code = FILESCREEN_BACK;
                break;
            
            case CH_ENTER:
                getFilenameForEntry(filename);
                code = FILESCREEN_OPENFILE;
                break;
        }
    }

    return code;
}

static void showDirectory(void)
{
    char y=1;
    int r, f=fileInTopRow;

    for (r = 0; r < DIR_ROWS; ++r,++y,++f) {
        if (f >= numFiles) {
            clearEntry(y, 5);
        } else {
            drawEntry(f, y, 5, f == selectedFile ? 1 : 0);
        }
        if (f+DIR_ROWS >= numFiles) {
            clearEntry(y, 39);
        } else {
            drawEntry(f+DIR_ROWS, y, 39, f+DIR_ROWS == selectedFile ? 1 : 0);
        }
    }
}

static void trimFilename(char *filename)
{
    while (filename[strlen(filename)-1] == ' ') {
        filename[strlen(filename)-1] = 0;
    }
}

static void updateStatusRow(void)
{
    char buffer[20];

    strcpy(buffer, formatInt16(numFiles));
    strcat(buffer, " file");
    if (numFiles != 1) {
        strcat(buffer, "s");
    }
    strcat(buffer, " found");

    drawStatusLine(buffer, 1);
}
