/**
 * inputbuf.h
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Definitions and declarations for input buffers.
 * 
 * Copyright (c) 2024
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

#ifndef INPUTBUF_H
#define INPUTBUF_H

#include <real.h>

#define INPUTBUFLEN 80

void clearInputBuf(void);
char isInputEndOfLine(void);
char readCharFromInput(void);
FLOAT readFloatFromInput(void);

#endif // end of INPUTBUF_H
