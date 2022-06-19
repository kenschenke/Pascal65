#ifndef SYMTAB_H
#define SYMTAB_H

struct _SYMTABLINENODE {
    struct _SYMTABLINENODE *next;
    unsigned number;
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
    unsigned value;  // temporary
    SYMTABLINELIST *lineNumList;
};
typedef struct _SYMTABNODE SYMTABNODE;

struct _SYMTAB {
    SYMTABNODE *root;
    SYMTABNODE **vpNodes;
    unsigned short cntNodes;
    unsigned short xSymtab;
    struct _SYMTAB *next;
};
typedef struct _SYMTAB SYMTAB;

void freeSymtab(SYMTAB *symtab);
SYMTAB *makeSymtab(void);

void addLineNumToSymtabList(SYMTABLINELIST *pLineList);
void convertSymtab(SYMTAB *symtab, SYMTAB *vpSymtabs[]);
void convertSymtabNode(SYMTABNODE *symtabNode, SYMTABNODE *vpNodes[]);
SYMTABNODE *enterSymtab(SYMTAB *symtab, const char *pString);
SYMTABNODE *getSymtabNode(SYMTAB *symtab, unsigned short xNode);
SYMTABNODE *searchSymtab(SYMTAB *symtab, const char *pString);
void printSymtab(SYMTAB *symtab);

#endif // end of SYMTAB_H
