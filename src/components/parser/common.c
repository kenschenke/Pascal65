#include <stdio.h>
#include <common.h>
#include <symtab.h>

unsigned cntSymtabs = 0;
SYMTAB *pSymtabList = NULL;
SYMTAB **vpSymtabs;
SYMTAB *pGlobalSymtab;

void initCommon(void)
{
    pGlobalSymtab = makeSymtab();
}
