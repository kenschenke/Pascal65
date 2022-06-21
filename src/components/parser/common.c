#include <stdio.h>
#include <common.h>
#include <symtab.h>
#include <icode.h>

short cntSymtabs;
SYMTAB *pSymtabList;
SYMTAB **vpSymtabs;
SYMTAB *pGlobalSymtab;
ICODE *pGlobalIcode;

void initCommon(void)
{
    cntSymtabs = 0;
    pSymtabList = NULL;

    pGlobalSymtab = makeSymtab();
    pGlobalIcode = makeIcode();
}
