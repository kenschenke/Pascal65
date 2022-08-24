/**
 * icode.h
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Header for intermediate code
 * 
 * Copyright (c) 2022
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

#ifndef ICODE_H
#define ICODE_H

#include <stdio.h>
#include <scanner.h>
#include <symtab.h>
#include <misc.h>

extern const TTokenCode mcLineMarker;

typedef struct {
    char *pCode;
    char *cursor;
    SYMTABNODE symtabNode;
    TOKEN token;
} ICODE;

void checkIcodeBounds(ICODE *Icode, int size);
void freeIcode(ICODE *Icode);
unsigned getCurrentIcodeLocation(ICODE *Icode);
TOKEN *getNextTokenFromIcode(ICODE *Icode);
void gotoIcodePosition(ICODE *Icode, unsigned position);
void insertLineMarker(ICODE *Icode);
ICODE *makeIcode(void);
ICODE *makeIcodeFrom(ICODE *Icode);
void putSymtabNodeToIcode(ICODE *Icode, SYMTABNODE *pNode);
void putTokenToIcode(ICODE *Icode, TTokenCode tc);
void resetIcodePosition(ICODE *Icode);

#endif // end of ICODE_H
