/**
 * common.h
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Header for shared data between main code and overlays
 * 
 * Copyright (c) 2022
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

#ifndef COMMON_H
#define COMMON_H

#include <symtab.h>
#include <misc.h>

extern short cntSymtabs;
extern CHUNKNUM firstSymtabChunk;
extern CHUNKNUM globalSymtab;
extern short currentLineNumber;

extern const TTokenCode tlDeclarationStart[], tlDeclarationFollow[],
    tlIdentifierStart[], tlIdentifierFollow[],
    tlSublistFollow[], tlFieldDeclFollow[];

extern const TTokenCode tlEnumConstStart[], tlEnumConstFollow[],
    tlSubrangeLimitFollow[];

extern const TTokenCode tlIndexStart[], tlIndexFollow[],
    tlIndexListFollow[];

extern const TTokenCode tlSubscriptOrFieldStart[];

extern const TTokenCode tlProcFuncStart[], tlProcFuncFollow[],
    tlHeaderFollow[];

extern const TTokenCode tlProgProcIdFollow[], tlFuncIdFollow[],
    tlActualVarParmFollow[], tlFormalParmsFollow[];

extern char isFatalError;       // non-zero if fatal parsing error encountered

void initCommon(void);
char isStopKeyPressed(void);

#endif // end of COMMON_H
