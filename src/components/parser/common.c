#include <stdio.h>
#include <common.h>
#include <symtab.h>

int cntSymtabs = 0;
SYMTAB *pSymtabList = NULL;
SYMTAB **vpSymtabs;
SYMTAB *pGlobalSymtab;

void initCommon(void)
{
    pGlobalSymtab = makeSymtab();
}
