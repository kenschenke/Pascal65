/**
 * buffer.h
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Header for source file buffered reading
 * 
 * Copyright (c) 2024
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

#ifndef BUFFER_H
#define BUFFER_H

#include <stdio.h>
#include <error.h>

#define MAX_LINE_LEN 80

extern char eofChar;

void tinOpen(const char *pFilename, TAbortCode ac);
void tinClose(void);

char getCurrentChar(void);
char getChar(void);
char getLine(void);
char isBufferEof(void);
char putBackChar(void);

#endif // end of BUFFER_H
