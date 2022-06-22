/**
 * buffer.h
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Header for source file buffered reading
 * 
 * Copyright (c) 2022
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

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
} TINBUF;

TINBUF *tin_open(const char *pFilename, TAbortCode ac);
void tin_close(TINBUF *tinBuf);

char getCurrentChar(TINBUF *tinBuf);
char getChar(TINBUF *tinBuf);
char getLine(TINBUF *tinBuf);
char putBackChar(TINBUF *tinBuf);

#endif // end of BUFFER_H
