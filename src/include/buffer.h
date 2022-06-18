#ifndef BUFFER_H
#define BUFFER_H

#include <stdio.h>
#include <error.h>

#define MAX_LINE_LEN 40

extern int currentLineNumber;
extern char eofChar;
extern int inputPosition;

typedef struct {
    FILE *fh;
    char buffer[MAX_LINE_LEN + 1];
    char *pChar;
} TINBUF;

TINBUF *openTextInBuffer(const char *pFilename, TAbortCode ac);
void closeTextInBuffer(TINBUF *tinBuf);

char getCurrentChar(TINBUF *tinBuf);
char getChar(TINBUF *tinBuf);
char getLine(TINBUF *tinBuf);
char putBackChar(TINBUF *tinBuf);

#endif // end of BUFFER_H
