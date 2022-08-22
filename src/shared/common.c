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
#include <cbm.h>
#include <conio.h>

short cntSymtabs;
CHUNKNUM firstSymtabChunk;
CHUNKNUM globalSymtab;
ICODE *pGlobalIcode;
char isFatalError;

void initCommon(void)
{
    SYMTAB symtab;

    cntSymtabs = 0;
    firstSymtabChunk = 0;
    isFatalError = 0;

    makeSymtab(&symtab);
    globalSymtab = symtab.symtabChunkNum;
    pGlobalIcode = makeIcode();
}

char isStopKeyPressed()
{
    char ch = 0;

    if (kbhit()) {
        ch = cgetc();
    }

    return ch == CH_STOP;
}
