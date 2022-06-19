#ifndef COMMON_H
#define COMMON_H

#include <symtab.h>

extern unsigned cntSymtabs;
extern SYMTAB *pSymtabList;
extern SYMTAB **vpSymtabs;
extern SYMTAB *pGlobalSymtab;

void initCommon(void);

#endif // end of COMMON_H
