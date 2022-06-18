#include <stdlib.h>
#include <string.h>

#include <buffer.h>

int currentLineNumber;
char eofChar = 0x7f;
int inputPosition;

TINBUF *openTextInBuffer(const char *pFilename, TAbortCode ac)
{
    FILE *fh;
    TINBUF *tinBuf;

    fh = fopen(pFilename, "r");
    if (fh == NULL) {
        abortTranslation(ac);
    }

    tinBuf = malloc(sizeof(TINBUF));
    if (tinBuf == NULL) {
        fclose(fh);
        abortTranslation(abortOutOfMemory);
    }

    tinBuf->fh = fh;
    memset(tinBuf->buffer, 0, sizeof(tinBuf->buffer));
    tinBuf->pChar = tinBuf->buffer;
    currentLineNumber = 0;

    return tinBuf;
}

void closeTextInBuffer(TINBUF *tinBuf)
{
    fclose(tinBuf->fh);
    free(tinBuf);
}

char getCurrentChar(TINBUF *tinBuf)
{
    return *(tinBuf->pChar);
}

char getChar(TINBUF *tinBuf)
{
    char ch;

    if (*(tinBuf->pChar) == eofChar) {
        return eofChar;
    } else if (*(tinBuf->pChar) == 0) {
        ch = getLine(tinBuf);
    } else {
        tinBuf->pChar++;
        inputPosition++;
        ch = *(tinBuf->pChar);
    }

#if 0
    if (ch > 128) {
        ch -= 128;
    }
#endif
    return ch;
}

char getLine(TINBUF *tinBuf)
{
    extern int currentNestingLevel;
    int i, n;

    if (feof(tinBuf->fh)) {
        tinBuf->pChar = &eofChar;
    } else {
        i = 0;
        while(1) {
            n = fread(tinBuf->buffer+i, sizeof(char), 1, tinBuf->fh);
            if (n != 1) {
                if (!feof(tinBuf->fh)) {
                    abortTranslation(abortSourceFileReadFailed);
                }
                tinBuf->buffer[i] = 0;
                break;
            }
            if (tinBuf->buffer[i] == 13) {  // carriage return
                tinBuf->buffer[i] = 0;
                currentLineNumber++;
                break;
            }
            i++;
            if (i >= MAX_LINE_LEN) {
                abortTranslation(abortSourceLineTooLong);
            }
        }
        tinBuf->pChar = tinBuf->buffer;
    }

    return *(tinBuf->pChar);
}

char putBackChar(TINBUF *tinBuf)
{
    tinBuf->pChar--;
    inputPosition--;

    return *(tinBuf->pChar);
}
