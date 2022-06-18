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
    SYMTABNODE *pNode;
    TOKEN token;
} ICODE;

void checkIcodeBounds(ICODE *Icode, int size);
void freeIcode(ICODE *Icode);
TOKEN *getNextTokenFromIcode(ICODE *Icode);
void insertLineMarker(ICODE *Icode);
ICODE *makeIcode(void);
ICODE *makeIcodeFrom(ICODE *Icode);
void putSymtabNodeToIcode(ICODE *Icode, SYMTABNODE *pNode);
void putTokenToIcode(ICODE *Icode, TTokenCode tc);

#endif // end of ICODE_H
