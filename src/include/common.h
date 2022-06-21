#ifndef COMMON_H
#define COMMON_H

#include <symtab.h>
#include <icode.h>

extern short cntSymtabs;
extern SYMTAB *pSymtabList;
extern SYMTAB **vpSymtabs;
extern SYMTAB *pGlobalSymtab;
extern ICODE *pGlobalIcode;

void initCommon(void);

#endif // end of COMMON_H
