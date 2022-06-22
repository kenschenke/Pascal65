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
#include <icode.h>

extern short cntSymtabs;
extern SYMTAB *pSymtabList;
extern SYMTAB **vpSymtabs;
extern SYMTAB *pGlobalSymtab;
extern ICODE *pGlobalIcode;

void initCommon(void);

#endif // end of COMMON_H
