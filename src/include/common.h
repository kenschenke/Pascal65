/**
 * common.h
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Header for shared data between main code and overlays
 * 
 * Copyright (c) 2024
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

#ifndef COMMON_H
#define COMMON_H

#include <symtab.h>
#include <misc.h>
#include <ast.h>
#include <chunks.h>

#define MAX_LIBS 80

struct rtroutine {
    unsigned char routineNum;
    char routineSeq;
    char libNum;
    CHUNKNUM left;
    CHUNKNUM right;
    char unused[CHUNK_LEN - 7];
};

extern short cntSymtabs;
extern CHUNKNUM firstSymtabChunk;
extern CHUNKNUM globalSymtab;
extern CHUNKNUM units;
extern CHUNKNUM exports;
extern short currentLineNumber;
extern unsigned char libsNeeded[MAX_LIBS / 8];

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

// Returns 0 if unit not found
char findUnit(CHUNKNUM name, struct unit* pUnit);

void initCommon(void);
void freeCommon(void);
char isStopKeyPressed(void);
char isConcatOperand(CHUNKNUM exprChunk);
char isStringConcat(CHUNKNUM exprChunk);

#endif // end of COMMON_H
