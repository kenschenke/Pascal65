/**
 * buffer.c
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Functions to implement buffered reading of source files.
 * 
 * Copyright (c) 2022
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

#include <stdlib.h>
#include <string.h>
#include <common.h>

#include <buffer.h>

short currentLineNumber;
char eofChar = 0x7f;
unsigned inputPosition;

TINBUF *tin_open(const char *pFilename, TAbortCode ac)
{
    FILE *fh;
    TINBUF *tinBuf;

    tinBuf = malloc(sizeof(TINBUF));
    if (tinBuf == NULL) {
        return NULL;
    }
    memset(tinBuf, 0, sizeof(TINBUF));

    fh = fopen(pFilename, "r");
    if (fh == NULL) {
        abortTranslation(ac);
        return tinBuf;
    }

    if (tinBuf == NULL) {
        fclose(fh);
        abortTranslation(abortOutOfMemory);
        return tinBuf;
    }

    tinBuf->fh = fh;
    memset(tinBuf->buffer, 0, sizeof(tinBuf->buffer));
    tinBuf->pChar = tinBuf->buffer;
    currentLineNumber = 0;

    return tinBuf;
}

void tin_close(TINBUF *tinBuf)
{
    fclose(tinBuf->fh);
    free(tinBuf);
}

char getCurrentChar(void)
{
    if (isFatalError)
        return eofChar;

    return *(pInputBuffer->pChar);
}

char getChar(void)
{
    char ch;

    if (isFatalError)
        return eofChar;
        
    if (*(pInputBuffer->pChar) == eofChar) {
        return eofChar;
    } else if (*(pInputBuffer->pChar) == 0) {
        ch = getLine();
        if (isFatalError)
            return eofChar;
    } else {
        pInputBuffer->pChar++;
        ++inputPosition;
        ch = *(pInputBuffer->pChar);
    }

    return ch;
}

char getLine(void)
{
    extern int currentNestingLevel;
    int i, n;

    if (isFatalError)
        return eofChar;
        
    if (feof(pInputBuffer->fh)) {
        pInputBuffer->pChar = &eofChar;
    } else {
        i = 0;
        while(1) {
            n = fread(pInputBuffer->buffer+i, sizeof(char), 1, pInputBuffer->fh);
            if (n != 1) {
                if (!feof(pInputBuffer->fh)) {
                    abortTranslation(abortSourceFileReadFailed);
                    return eofChar;
                }
                pInputBuffer->buffer[i] = 0;
                break;
            }
            if (pInputBuffer->buffer[i] == 13) {  // carriage return
                pInputBuffer->buffer[i] = 0;
                ++currentLineNumber;
                break;
            }
            ++i;
            if (i >= MAX_LINE_LEN) {
                abortTranslation(abortSourceLineTooLong);
                return eofChar;
            }
        }
        pInputBuffer->pChar = pInputBuffer->buffer;
    }

    return *(pInputBuffer->pChar);
}

char putBackChar(void)
{
    if (isFatalError)
        return eofChar;

    pInputBuffer->pChar--;
    inputPosition--;

    return *(pInputBuffer->pChar);
}
