#include <stdio.h>
#include <formatter.h>
#include <string.h>

#define INDENT_SIZE 4
#define MAX_MARGIN 60
#define MAX_LENGTH 80

static FILE *fmtFh;

static int margin;
static char newLine;

void fmtClose(void) {
    if (fmtFh) {
        fclose(fmtFh);
        fmtFh = NULL;
    }
}

void fmtDetent(void) {
    if ((margin -= INDENT_SIZE) < 0) {
        margin = 0;
    }
}

void fmtIndent(void) {
    margin += INDENT_SIZE;
}

char fmtOpen(const char *filename) {
    fmtClose();

    margin = 0;
    newLine = 0;

    fmtFh = fopen(filename, "w");
    return fmtFh == NULL ? 0 : 1;
}

void fmtPut(const char *pString) {
    if (newLine) {
        newLine = 0;
        fprintf(fmtFh, "%*s", margin, " ");
    }

    fprintf(fmtFh, "%s", pString);
}

void fmtPutLine(const char *pString) {
    if (newLine) {
        fprintf(fmtFh, "%*s", margin, " ");
    }
    
    fprintf(fmtFh, "%s\n", pString);
    newLine = 1;
}

void fmtPutName(CHUNKNUM chunkNum) {
    char chunk[CHUNK_LEN + 1];

    if (retrieveChunk(chunkNum, (unsigned char *)chunk) == 0) {
        fmtPut("<unknown>");
    } else {
        chunk[CHUNK_LEN] = 0;
        fmtPut(chunk);
    }
}

void fmtPutStringArray(CHUNKNUM chunkNum) {
    char buf[CHUNK_LEN];
    STRVALCHUNK chunk;

    chunk.nextChunkNum = chunkNum;
    while (chunk.nextChunkNum) {
        if (retrieveChunk(chunk.nextChunkNum, (unsigned char *)&chunk) == 0) {
            fmtPut("<unknown>");
        } else {
            memset(buf, 0, sizeof(buf));
            memcpy(buf, chunk.value, sizeof(chunk.value));
            fmtPut(buf);
        }
    }
}

void fmtResetMargin(int m) {
    margin = m;
}

int fmtSetMargin(void) {
    return margin;
}

void fmtSource(CHUNKNUM programId) {
    fmtPrintProgram(programId);
}

