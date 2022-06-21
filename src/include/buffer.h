#ifndef BUFFER_H
#define BUFFER_H

#include <stdio.h>
#include <error.h>

#define MAX_LINE_LEN 40

extern short currentLineNumber;
extern char eofChar;
extern unsigned inputPosition;

typedef struct {
    FILE *fh;
    char buffer[MAX_LINE_LEN + 1];
    char *pChar;
    char fatalError; // 1 if fatal error
} TINBUF;

TINBUF *tin_open(const char *pFilename, TAbortCode ac);
void tin_close(TINBUF *tinBuf);

char getCurrentChar(TINBUF *tinBuf);
char getChar(TINBUF *tinBuf);
char getLine(TINBUF *tinBuf);
char tin_isFatalError(TINBUF *tinBuf);
char putBackChar(TINBUF *tinBuf);

#endif // end of BUFFER_H
