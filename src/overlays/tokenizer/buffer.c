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

static FILE *tinFh;
char tinBuffer[MAX_LINE_LEN + 1];
char *pBufChar;

char lineNumberChanged;
char eofChar = 0x7f;
unsigned inputPosition;

void tinOpen(const char *pFilename, TAbortCode ac)
{
    tinFh = fopen(pFilename, "r");
    if (tinFh == NULL) {
        abortTranslation(ac);
    }

    memset(tinBuffer, 0, sizeof(tinBuffer));
    pBufChar = tinBuffer;
    currentLineNumber = 0;
}

void tinClose(void)
{
    fclose(tinFh);
    tinFh = NULL;
}

char getCurrentChar(void)
{
    if (isFatalError)
        return eofChar;

    return *pBufChar;
}

char getChar(void)
{
    char ch;

    if (isFatalError)
        return eofChar;
        
    if (*pBufChar == eofChar) {
        return eofChar;
    } else if (*pBufChar == 0) {
        ch = getLine();
        if (isFatalError)
            return eofChar;
    } else {
        pBufChar++;
        ++inputPosition;
        ch = *pBufChar;
    }

    return ch;
}

char getLine(void)
{
    extern int currentNestingLevel;
    int i, n;

    if (isFatalError)
        return eofChar;
        
    if (feof(tinFh)) {
        pBufChar = &eofChar;
    } else {
        i = 0;
        while(1) {
            n = fread(tinBuffer+i, sizeof(char), 1, tinFh);
            if (n != 1) {
                if (!feof(tinFh)) {
                    abortTranslation(abortSourceFileReadFailed);
                    return eofChar;
                }
                tinBuffer[i] = 0;
                break;
            }
            if (tinBuffer[i] == 13) {  // carriage return
                tinBuffer[i] = 0;
                ++currentLineNumber;
                lineNumberChanged = 1;
                break;
            }
            ++i;
            if (i >= MAX_LINE_LEN) {
                abortTranslation(abortSourceLineTooLong);
                return eofChar;
            }
        }
        pBufChar = tinBuffer;
    }

    return *pBufChar;
}

char isBufferEof(void) {
    return feof(tinFh) ? 1 : 0;
}

char putBackChar(void)
{
    if (isFatalError)
        return eofChar;

    pBufChar--;
    inputPosition--;

    return *pBufChar;
}
