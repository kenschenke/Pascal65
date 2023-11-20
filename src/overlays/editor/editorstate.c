#include <stdio.h>
#include <chunks.h>
#include <editor.h>
#include <string.h>
#ifdef __MEGA65__
#include <doscmd.h>
#endif

/*
    This code loads and saves editor state.  It is used when running a compiled
    program from within the IDE.  The editor state is saved before running
    the program.  The program reruns the editor that then reloads the saved state.
    The state is saved to a file on the disk.

    State File Contents:
        1.  Number of open files
        2.  For each open file:
                a.  Filename
                        i. If the filename is "help.txt", it is loaded as the
                           help file, read-only.
                b.  Cursor X position
                c.  Cursor Y position
                d.  Row offset
                e.  Column offset
    
    State File Layout:
        <1 byte>   Number of open files

        For each file:
            <1 byte>  1 if this was the current file, 0 otherwise
            <1 byte>  Length of filename
            <n bytes> Filename
            <1 byte>  Cursor X position
            <2 bytes> Cursor Y position
            <1 byte>  Column offset
            <2 bytes> Row offset
*/

char editorHasState(void) {
    FILE *fp = fopen("zzstate", "rb");
    if (fp == NULL) {
        return 0;
    }

    fclose(fp);
    return 1;
}

void editorLoadState(void)
{
    char filename[CHUNK_LEN];
    efile file;
    char c, numOpenFiles, fileNum, isCurrentFile;
    FILE *fp;
    CHUNKNUM fileChunkNum, currentFileChunkNum;

    fp = fopen("zzstate", "rb");
    if (fp == NULL) {
        return;
    }

    fread(&numOpenFiles, sizeof(char), 1, fp);

    for (fileNum = 0; fileNum < numOpenFiles; ++fileNum) {
        fread(&isCurrentFile, sizeof(char), 1, fp);
        memset(filename, 0, sizeof(filename));
        fread(&c, sizeof(char), 1, fp);
        fread(filename, sizeof(char), c, fp);
        initFile();
        allocChunk(&E.cf.filenameChunk);
        storeChunk(E.cf.filenameChunk, filename);
        fread(&c, sizeof(char), 1, fp);
        E.cf.cx = c;
        fread(&E.cf.cy, sizeof(int), 1, fp);
        fread(&c, sizeof(char), 1, fp);
        E.cf.coloff = c;
        fread(&E.cf.rowoff, sizeof(int), 1, fp);
        storeChunk(E.cf.fileChunk, &E.cf);
        if (isCurrentFile) {
            currentFileChunkNum = E.cf.fileChunk;
        }
    }

    fclose(fp);
#ifdef __MEGA65__
    removeFile("zzstate");
#else
    remove("zzstate");
#endif

    fileChunkNum = E.firstFileChunk;
    while (fileChunkNum) {
        retrieveChunk(fileChunkNum, &file);
        if (fileChunkNum == currentFileChunkNum) {
            memcpy(&E.cf, &file, sizeof(efile));
            break;
        }
        fileChunkNum = file.nextFileChunk;
    }
}

void editorSaveState(void)
{
    char filename[CHUNK_LEN + 1];
    CHUNKNUM fileChunk;
    efile file;
    FILE *fp;
    char c, numOpenFiles = 0;

    fp = fopen("zzstate", "wb");
    if (fp == NULL) {
        return;
    }

    // Walk through the open files and count them
    fileChunk = E.firstFileChunk;
    while (fileChunk) {
        retrieveChunk(fileChunk, &file);
        ++numOpenFiles;
        fileChunk = file.nextFileChunk;
    }

    // Number of open files
    fwrite(&numOpenFiles, sizeof(char), 1, fp);

    // Save each file to state file
    fileChunk = E.firstFileChunk;
    while (fileChunk) {
        if (fileChunk == E.cf.fileChunk) {
            c = 1;  // active file
            memcpy(&file, &E.cf, sizeof(efile));
        } else {
            c = 0;  // not the active file
            retrieveChunk(fileChunk, &file);
        }
        fwrite(&c, sizeof(char), 1, fp);
        memset(filename, 0, sizeof(filename));
        retrieveChunk(file.filenameChunk, filename);
        c = (char) strlen(filename);
        fwrite(&c, sizeof(char), 1, fp);
        fwrite(filename, sizeof(char), c, fp);

        c = file.cx;
        fwrite(&c, sizeof(char), 1, fp);
        fwrite(&file.cy, sizeof(int), 1, fp);

        c = file.coloff;
        fwrite(&c, sizeof(char), 1, fp);
        fwrite(&file.rowoff, sizeof(int), 1, fp);

        fileChunk = file.nextFileChunk;
    }

    fclose(fp);
}