/**
 * int16.h
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Definitions and declarations for 16-bit integer handling
 * 
 * Copyright (c) 2024
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

#ifndef INT16_H
#define INT16_H

#define INTBUFLEN 14

const char *formatInt16(int num);
const char *formatUint16(unsigned int num);
int parseInt16(char *buffer);
void printInt16(int num);
void setIntBuf(char *buffer);   // buffer must be at least 14 bytes

#endif // end of INT16_H
