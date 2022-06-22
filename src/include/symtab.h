/**
 * symtab.h
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Header for symbol table
 * 
 * Copyright (c) 2022
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

#ifndef SYMTAB_H
#define SYMTAB_H

struct _SYMTABLINENODE {
    struct _SYMTABLINENODE *next;
    short number;
};
typedef struct _SYMTABLINENODE SYMTABLINENODE;

typedef struct {
    SYMTABLINENODE *head;
    SYMTABLINENODE *tail;
} SYMTABLINELIST;

struct _SYMTABNODE {
    struct _SYMTABNODE *left, *right;
    char *pString;
    short xSymtab;
    short xNode;
    int value;  // temporary
    SYMTABLINELIST *lineNumList;
};
typedef struct _SYMTABNODE SYMTABNODE;

struct _SYMTAB {
    SYMTABNODE *root;
    SYMTABNODE **vpNodes;
    short cntNodes;
    short xSymtab;
    struct _SYMTAB *next;
};
typedef struct _SYMTAB SYMTAB;

void freeSymtab(SYMTAB *symtab);
SYMTAB *makeSymtab(void);

void addLineNumToSymtabList(SYMTABLINELIST *pLineList);
void convertSymtab(SYMTAB *symtab, SYMTAB *vpSymtabs[]);
void convertSymtabNode(SYMTABNODE *symtabNode, SYMTABNODE *vpNodes[]);
SYMTABNODE *enterSymtab(SYMTAB *symtab, const char *pString);
SYMTABNODE *getSymtabNode(SYMTAB *symtab, short xNode);
SYMTABNODE *searchSymtab(SYMTAB *symtab, const char *pString);

#endif // end of SYMTAB_H
