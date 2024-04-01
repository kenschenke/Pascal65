/**
 * libcommon.h
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Definitions and declarations for common library routines
 * 
 * Copyright (c) 2024
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

#ifndef LIBCOMMON_H
#define LIBCOMMON_H

void __fastcall__ leftPad(char fieldWidth, char valueWidth);
void __fastcall__ printlnz(const char *str);
void __fastcall__ printz(const char *str);

#endif // end of LIBCOMMON_H
