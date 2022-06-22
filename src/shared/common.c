/**
 * common.c
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Code to initialize common data shared between overlays
 * 
 * Copyright (c) 2022
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

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
