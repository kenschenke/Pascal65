#ifndef INPUTBUF_H
#define INPUTBUF_H

#include <real.h>

void clearInputBuf(void);
char isInputEndOfLine(void);
char readCharFromInput(void);
FLOAT readFloatFromInput(void);
int readIntFromInput(void);

#endif // end of INPUTBUF_H
