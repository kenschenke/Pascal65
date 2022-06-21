#include <stdlib.h>
#include <string.h>

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
        tinBuf->fatalError = 1;
        abortTranslation(ac);
        return tinBuf;
    }

    if (tinBuf == NULL) {
        fclose(fh);
        tinBuf->fatalError = 1;
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

char getCurrentChar(TINBUF *tinBuf)
{
    if (tin_isFatalError(tinBuf))
        return eofChar;

    return *(tinBuf->pChar);
}

char getChar(TINBUF *tinBuf)
{
    char ch;

    if (tin_isFatalError(tinBuf))
        return eofChar;
        
    if (*(tinBuf->pChar) == eofChar) {
        return eofChar;
    } else if (*(tinBuf->pChar) == 0) {
        ch = getLine(tinBuf);
        if (tin_isFatalError(tinBuf))
            return eofChar;
    } else {
        tinBuf->pChar++;
        ++inputPosition;
        ch = *(tinBuf->pChar);
    }

    return ch;
}

char getLine(TINBUF *tinBuf)
{
    extern int currentNestingLevel;
    int i, n;

    if (tin_isFatalError(tinBuf))
        return eofChar;
        
    if (feof(tinBuf->fh)) {
        tinBuf->pChar = &eofChar;
    } else {
        i = 0;
        while(1) {
            n = fread(tinBuf->buffer+i, sizeof(char), 1, tinBuf->fh);
            if (n != 1) {
                if (!feof(tinBuf->fh)) {
                    tinBuf->fatalError = 1;
                    abortTranslation(abortSourceFileReadFailed);
                    return eofChar;
                }
                tinBuf->buffer[i] = 0;
                break;
            }
            if (tinBuf->buffer[i] == 13) {  // carriage return
                tinBuf->buffer[i] = 0;
                ++currentLineNumber;
                break;
            }
            ++i;
            if (i >= MAX_LINE_LEN) {
                tinBuf->fatalError = 1;
                abortTranslation(abortSourceLineTooLong);
                return eofChar;
            }
        }
        tinBuf->pChar = tinBuf->buffer;
    }

    return *(tinBuf->pChar);
}

char tin_isFatalError(TINBUF *tinBuf)
{
    return tinBuf->fatalError;
}

char putBackChar(TINBUF *tinBuf)
{
    if (tin_isFatalError(tinBuf))
        return eofChar;

    tinBuf->pChar--;
    inputPosition--;

    return *(tinBuf->pChar);
}
